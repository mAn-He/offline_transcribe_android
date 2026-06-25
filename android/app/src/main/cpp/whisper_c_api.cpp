#include "whisper_c_api.h"

// Real whisper.cpp header (provided at build time via CMake FetchContent).
#include "whisper.h"

#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

#include <android/log.h>
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO,  "whisper_ffi", __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, "whisper_ffi", __VA_ARGS__)

struct wffi_model_t {
  whisper_context* ctx = nullptr; // owns the real whisper context
};

struct wffi_context_t {
  whisper_context*   model = nullptr; // borrowed (owned by wffi_model_t)
  std::vector<float> pcmf32;          // mono 16kHz samples in [-1, 1]
  std::string        collected;       // final transcript
};

static std::mutex g_mutex;

// Minimal RIFF/WAVE reader for 16-bit PCM mono. FFmpeg already normalizes input
// to 16kHz mono s16le, so we only need to handle that case robustly.
static bool load_wav_pcm_s16_mono(const char* path, std::vector<float>& out) {
  FILE* f = std::fopen(path, "rb");
  if (!f) { LOGE("cannot open wav: %s", path); return false; }

  char riff[4];
  if (std::fread(riff, 1, 4, f) != 4 || std::strncmp(riff, "RIFF", 4) != 0) { std::fclose(f); return false; }
  std::fseek(f, 4, SEEK_CUR); // overall chunk size
  char wave[4];
  if (std::fread(wave, 1, 4, f) != 4 || std::strncmp(wave, "WAVE", 4) != 0) { std::fclose(f); return false; }

  uint16_t channels = 1, bits = 16;
  uint32_t sample_rate = 16000;
  bool ok = false;

  while (true) {
    char id[4];
    if (std::fread(id, 1, 4, f) != 4) break;
    uint32_t sz = 0;
    if (std::fread(&sz, 4, 1, f) != 1) break;

    if (std::strncmp(id, "fmt ", 4) == 0) {
      uint16_t audio_fmt = 0;
      std::fread(&audio_fmt, 2, 1, f);
      std::fread(&channels, 2, 1, f);
      std::fread(&sample_rate, 4, 1, f);
      std::fseek(f, 6, SEEK_CUR);       // byte_rate(4) + block_align(2)
      std::fread(&bits, 2, 1, f);
      if (sz > 16) std::fseek(f, sz - 16, SEEK_CUR); // skip any extension
    } else if (std::strncmp(id, "data", 4) == 0) {
      if (bits != 16) { LOGE("unsupported bit depth: %d", bits); break; }
      const size_t n = sz / 2;
      std::vector<int16_t> buf(n);
      const size_t got = std::fread(buf.data(), 2, n, f);
      out.resize(got);
      for (size_t i = 0; i < got; ++i) out[i] = buf[i] / 32768.0f;
      ok = !out.empty();
      break;
    } else {
      std::fseek(f, sz + (sz & 1), SEEK_CUR); // skip chunk (+pad byte if odd)
    }
  }

  std::fclose(f);
  if (channels != 1 || sample_rate != 16000) {
    LOGI("warning: expected 16kHz mono, got %u Hz / %u ch", sample_rate, channels);
  }
  return ok;
}

extern "C" {

wffi_model_handle wffi_load_model(const char* model_path) {
  std::lock_guard<std::mutex> lock(g_mutex);
  whisper_context_params cparams = whisper_context_default_params();
  cparams.use_gpu = false; // CPU-only on Android ARM64
  whisper_context* wc = whisper_init_from_file_with_params(model_path, cparams);
  if (!wc) { LOGE("whisper_init_from_file failed: %s", model_path); return nullptr; }
  auto* m = new wffi_model_t();
  m->ctx = wc;
  return m;
}

void wffi_free_model(wffi_model_handle m) {
  if (!m) return;
  if (m->ctx) whisper_free(m->ctx);
  delete m;
}

wffi_context_handle wffi_prepare(const char* wav_path, wffi_model_handle model) {
  if (!model || !model->ctx) return nullptr;
  auto* c = new wffi_context_t();
  c->model = model->ctx;
  if (!load_wav_pcm_s16_mono(wav_path, c->pcmf32)) { delete c; return nullptr; }
  LOGI("loaded %zu samples (%.1f s)", c->pcmf32.size(), c->pcmf32.size() / 16000.0);
  return c;
}

void wffi_free_ctx(wffi_context_handle ctx) {
  delete ctx;
}

wffi_params_t wffi_default_params(void) {
  wffi_params_t p{};
  const unsigned hw = std::thread::hardware_concurrency();
  // Use big cores but cap to keep thermals sane on long (~2h) jobs.
  p.n_threads       = hw > 0 ? static_cast<int>(std::min(hw, 6u)) : 4;
  p.translate       = false;
  p.print_progress  = false;
  p.print_timestamps = false;
  return p;
}

int wffi_full(wffi_context_handle ctx, wffi_params_t params) {
  if (!ctx || !ctx->model) return -1;
  if (ctx->pcmf32.empty()) return -2;

  whisper_full_params wp = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
  wp.n_threads        = params.n_threads > 0 ? params.n_threads : 4;
  wp.translate        = params.translate;
  wp.print_progress   = params.print_progress;
  wp.print_timestamps = params.print_timestamps;
  wp.print_realtime   = false;
  wp.print_special    = false;
  wp.no_context       = true;        // independent windows -> stable for long audio
  wp.single_segment   = false;
  wp.language         = nullptr;     // auto-detect (handles Korean and mixed input)

  const int r = whisper_full(ctx->model, wp, ctx->pcmf32.data(), static_cast<int>(ctx->pcmf32.size()));
  if (r != 0) { LOGE("whisper_full failed: %d", r); return r; }

  const int n = whisper_full_n_segments(ctx->model);
  ctx->collected.clear();
  for (int i = 0; i < n; ++i) {
    const char* seg = whisper_full_get_segment_text(ctx->model, i);
    if (seg) ctx->collected += seg;
  }
  LOGI("transcribed %d segments, %zu chars", n, ctx->collected.size());
  return 0;
}

const char* wffi_collect_text(wffi_context_handle ctx) {
  if (!ctx) return "";
  return ctx->collected.c_str();
}

} // extern "C"
