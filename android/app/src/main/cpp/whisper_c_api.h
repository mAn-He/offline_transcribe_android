#pragma once
#include <stdint.h>
#include <stdbool.h>

// Stable C ABI exposed to Dart FFI.
//
// NOTE: functions are prefixed `wffi_` (whisper-ffi) on purpose. The real
// whisper.cpp library already exports symbols named `whisper_full`,
// `whisper_free`, `whisper_init_from_file_with_params`, etc. Naming our wrapper
// the same would collide at link time (and recurse), which is exactly the bug
// the original skeleton would have hit. Keep this namespace distinct.

#ifdef __cplusplus
extern "C" {
#endif

// Opaque handles
typedef struct wffi_model_t*   wffi_model_handle;
typedef struct wffi_context_t* wffi_context_handle;

typedef struct {
  int  n_threads;        // <=0 means "auto"
  bool translate;        // translate to English (false = keep source language)
  bool print_progress;
  bool print_timestamps;
} wffi_params_t;

// Load a whisper ggml model (.bin) from disk. Returns null on failure.
wffi_model_handle wffi_load_model(const char* model_path);
void              wffi_free_model(wffi_model_handle m);

// Decode a 16kHz mono PCM s16le WAV (produced by FFmpeg) into memory and bind
// it to the given model. Returns null on failure.
wffi_context_handle wffi_prepare(const char* wav_path, wffi_model_handle model);
void                wffi_free_ctx(wffi_context_handle ctx);

// Sensible defaults (auto thread count, no translate, no console prints).
wffi_params_t wffi_default_params(void);

// Run full transcription. Returns 0 on success, non-zero on error.
int wffi_full(wffi_context_handle ctx, wffi_params_t params);

// Collected transcript (valid until wffi_free_ctx). Never null.
const char* wffi_collect_text(wffi_context_handle ctx);

#ifdef __cplusplus
}
#endif
