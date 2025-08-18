#include "whisper_c_api.h"
#include <string>
#include <vector>
#include <memory>
#include <mutex>

// The real whisper.cpp headers - vendored in subdir
#include "whisper/whisper.h"

struct whisper_model_t { std::unique_ptr<whisper_context, void(*)(whisper_context*)> ctx; };
struct whisper_context_t { std::string collected; };

static std::mutex g_mutex;

whisper_model_handle whisper_load_model(const char* model_path) {
  std::lock_guard<std::mutex> lock(g_mutex);
  auto* raw = whisper_init_from_file(model_path);
  if (!raw) return nullptr;
  whisper_model_t* m = new whisper_model_t{std::unique_ptr<whisper_context, void(*)(whisper_context*)>(raw, whisper_free)};
  return m;
}

void whisper_free_model(whisper_model_handle m) {
  if (!m) return;
  delete m;
}

whisper_context_handle whisper_init_from_file_with_params(const char* wav_path, whisper_model_handle model) {
  if (!model) return nullptr;
  auto* ctx = new whisper_context_t();
  // No-op here; we reuse the model's context for simplicity. Real implementation should create state per thread.
  (void) wav_path;
  return ctx;
}

void whisper_free(whisper_context_handle ctx) {
  delete ctx;
}

whisper_params_t whisper_full_default_params(int strategy) {
  (void) strategy;
  whisper_params_t p{};
  p.translate = false;
  p.print_progress = false;
  p.print_realtime = false;
  p.print_timestamps = true;
  return p;
}

int whisper_full(whisper_context_handle ctx, whisper_params_t params, int n_processors) {
  (void) params; (void) n_processors; (void) ctx;
  // TODO: wire real audio processing: load PCM wav and run whisper_full()
  // For now, we just set dummy text to prove end-to-end wiring.
  if (ctx) ctx->collected = "[DUMMY TRANSCRIPT]";
  return 0;
}

const char* whisper_collect_text(whisper_context_handle ctx) {
  if (!ctx) return "";
  return ctx->collected.c_str();
}
