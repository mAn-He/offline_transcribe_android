#pragma once
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif

// Opaque handles
typedef struct whisper_model_t* whisper_model_handle;
typedef struct whisper_context_t* whisper_context_handle;

typedef struct {
  bool translate;
  bool print_progress;
  bool print_realtime;
  bool print_timestamps;
} whisper_params_t;

// API
whisper_model_handle whisper_load_model(const char* model_path);
void whisper_free_model(whisper_model_handle m);

whisper_context_handle whisper_init_from_file_with_params(const char* wav_path, whisper_model_handle model);
void whisper_free(whisper_context_handle ctx);

whisper_params_t whisper_full_default_params(int strategy);
int whisper_full(whisper_context_handle ctx, whisper_params_t params, int n_processors);

const char* whisper_collect_text(whisper_context_handle ctx);

#ifdef __cplusplus
}
#endif
