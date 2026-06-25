# Offline Multilingual Meeting Minutes (Flutter + On-Device AI)

A Flutter application that generates Korean meeting minutes **entirely offline** on
Galaxy S24+ class (ARM64) devices. It runs Whisper (ASR) via **direct Dart FFI to
whisper.cpp**, and an LLM (Gemma 4 / Llama / Qwen / Phi) via `llama_cpp_dart` for
Map-Reduce summarization & translation. No network is required after the models
are downloaded.

> **Status:** the native ASR path is now a **real whisper.cpp integration** (not a
> stub). whisper.cpp sources are pulled at build time via CMake `FetchContent`, so
> they are not committed here. GGUF/bin models are downloaded on-device. See
> **Known Limitations** for what still needs device verification.

## Goals and Key Constraints
- **Performance-first:** direct FFI to a C++ engine; ARM64 NEON/dotprod auto-enabled by whisper.cpp
- **100% offline:** all inference runs on-device after model download
- **Long-running:** designed for up to ~2 hours of audio
- **Resource-aware:** download only the selected models; CPU thread count capped for thermals
- **Target:** Flutter (Android ARM64)

## Architecture Overview
```
UI (Flutter + Riverpod)
  └─ pick model (LLM + ASR) ──▶ ModelPrefs ──▶ download only what's selected
  └─ Run pipeline ──▶ WorkManager one-off task ──▶ Compute Isolate:
        ├─ FFmpeg     : input audio → 16kHz mono PCM s16le WAV
        ├─ Whisper FFI: WAV → transcript (whisper.cpp, auto language detect)
        └─ Llama      : Map-Reduce summarize/translate → Korean minutes
  └─ result saved to <docs>/outputs/minutes.txt
```

## Repository Structure
```
lib/
  main.dart                          # UI, WorkManager registration, download wiring
  src/state/state.dart               # Riverpod state
  src/pipeline/pipeline.dart         # End-to-end pipeline in an Isolate (honors model selection)
  src/utils/ffmpeg.dart              # Audio preprocessing (16kHz mono PCM)
  src/utils/io_paths.dart            # Resolves model/output paths from the selection
  src/llm/llm.dart                   # Llama Map-Reduce (takes an explicit modelPath)
  src/ffi/whisper_bindings.dart      # Manual FFI bindings for the wffi_* C ABI
  src/whisper/whisper.dart           # Whisper Dart-side wrapper
  src/download/model_manifest.dart   # Verified download URLs + filename lookup
  src/download/model_downloader.dart # Downloads only the selected ASR + LLM
  src/models/model_options.dart      # Selectable LLM/ASR options shown in the UI
  src/prefs/model_prefs.dart         # Persists the user's model choice
  src/ui/model_selector.dart         # Bottom-sheet model picker
android/
  app/src/main/cpp/                  # C ABI shim + CMake (FetchContent pulls whisper.cpp)
  app/src/main/AndroidManifest.xml   # MainActivity, permissions, flutter_downloader
  app/src/main/kotlin/.../*.kt       # Progress notification helper
```

## Models (download URLs verified, public & token-free)

| Role | Option (UI label)            | File                                  | Size   |
|------|------------------------------|---------------------------------------|--------|
| ASR  | Whisper Small Q5_1           | `whisper-small-q5_1.bin`              | ~190MB |
| LLM  | Gemma 4 E2B (on-device, new) | `gemma-4-E2B-it-Q3_K_M.gguf`          | ~2.5GB |
| LLM  | Qwen 2.5 0.5B Instruct       | `qwen2.5-0.5b-instruct-q4_k_m.gguf`   | ~0.4GB |
| LLM  | Llama 3.2 1B Instruct        | `llama-3.2-1b-instruct-q4_k_m.gguf`   | ~0.8GB |
| LLM  | Phi-3 Mini 3.8B Instruct     | `phi-3-mini-3.8b-instruct-q4_k_m.gguf`| ~2.3GB |

- Whisper models use the **`.bin`** (ggml) extension — not `.gguf`.
- **Gemma 4** is Google's April-2026 model; the **E2B** "edge" variant targets mobile/on-device and covers 140 languages incl. Korean.
- The downloader fetches **only the selected** ASR + LLM (not the whole list), so first run is a few GB, not 15GB+.

## Prerequisites
- Flutter SDK (3.19+), Android Studio, Android NDK (r26+), CMake (3.22+)
- A network connection (only the first time, to fetch whisper.cpp + the chosen models)
- Galaxy S24+ (ARM64, Android 14) or equivalent ARM64 device

## Building and Running
```bash
flutter pub get
# (optional) regenerate FFI bindings if you change the C header:
dart run ffigen --config ffigen.yaml
# build & run on a connected ARM64 device:
flutter run --release --target-platform=android-arm64
```
The first native build downloads and compiles **whisper.cpp v1.7.4** automatically
(see `android/app/src/main/cpp/CMakeLists.txt`). No manual vendoring needed.

### Using the app
1. Tap **모델 선택** (Select model) → choose an LLM + ASR. Downloads start automatically for anything missing.
2. Wait for the download notification to finish.
3. Tap **Pick audio**, then **Run pipeline (background)**.
4. Output is written to `<docs>/outputs/minutes.txt` and shown in the UI.

---

## What changed recently (this branch)

This branch turned the project from a non-building skeleton into a buildable,
end-to-end-wired app. Summary of the fixes:

**Native ASR — now real (was a dummy):**
- `whisper_c_api.cpp` reads the 16kHz mono PCM WAV, runs `whisper_full()`, and
  collects segment text. Previously it returned `"[DUMMY TRANSCRIPT]"`.
- The C ABI was renamed to a distinct **`wffi_*`** namespace. The old skeleton
  reused whisper.cpp's own symbol names (`whisper_full`, `whisper_free`, …), which
  would have collided at link time.
- Korean is handled via auto language detection; thread count auto-selects big
  cores (capped to 6 for sustained/thermal stability).

**Build — whisper.cpp via FetchContent:**
- CMake now pulls a pinned `whisper.cpp` release at build time, so the large
  sources aren't committed. whisper.cpp's CMake auto-enables ARM NEON/dotprod.
- Removed the stub `cpp/whisper/CMakeLists.txt` that referenced non-existent files.

**Models & downloads:**
- Fixed the Whisper URL (`.gguf` → `.bin`; the old one returned HTTP 404).
- Removed the dead `gemma-3-270m` entry (its URL returned HTTP 401).
- Added **Gemma 4 E2B** (`Q3_K_M`, ~2.5GB), URL verified.
- Downloader now fetches **only the selected** models and auto-enqueues on
  selection / before a run (previously the download call was a no-op).

**Selection actually drives the pipeline:**
- The model chosen in the UI is persisted (`ModelPrefs`) and forwarded through the
  WorkManager job into `io_paths` / `whisper` / `llm`. Previously the choice was
  saved but ignored (paths were hardcoded).

**Other fixes:**
- `AndroidManifest.xml` was missing `MainActivity` entirely — the app could not
  launch. Added it (+ `READ_MEDIA_AUDIO`).
- Removed the unused `langchain_dart` dependency (Map-Reduce is implemented
  directly in `llm.dart`).
- `pubspec.yaml` pinned `llama_cpp_dart ^0.3.0`, which **does not exist** on
  pub.dev (so `pub get` failed). Pinned to `^0.2.2`.

---

## Known Limitations / Next Steps

These require a real device / further work and are **not yet done**:

1. **Gemma 4 runtime load is unverified.** The GGUF downloads fine, but
   `llama_cpp_dart 0.2.x` predates Gemma 4 (April 2026) and may not load its
   architecture. To run Gemma 4 you likely need to bump to the prerelease that
   bundles a recent llama.cpp (e.g. `llama_cpp_dart: ^0.9.0-dev.9`) and verify the
   API used in `lib/src/llm/llm.dart` still matches. Llama/Qwen/Phi are safer on 0.2.x.
2. **`llama_cpp_dart` API.** `llm.dart` was originally written against the
   non-existent 0.3.0. Confirm `LlamaIsolate.load/inference`/`LlamaConfig` match
   whichever version you pin.
3. **Foreground Service is not a real service.** `ForegroundService.kt` only posts
   a notification (`NotificationManager.notify`); it does not extend
   `android.app.Service` or call `startForeground()`. For guaranteed ~2h
   background stability, refactor it into a real foreground service that hosts the
   compute work, and route progress through a channel that the background engine
   can actually reach (the current WorkManager-isolate → UI-engine MethodChannel
   path silently fails).
4. **Native build can't be CI-verified here.** Compile once in Android Studio to
   confirm the `.so` builds for `arm64-v8a`.
5. **Speaker diarization, resumable downloads, free-space checks, and structured
   JSON output** remain as future enhancements.

## Troubleshooting
- **Crash on library load:** verify `libwhisper_ffi.so` built for `arm64-v8a`.
- **LLM fails to load:** check the GGUF path/RAM; for Gemma 4 see limitation #1.
- **FFmpeg fails:** inspect FFmpegKit logs in Logcat.
- **`pub get` fails:** ensure `llama_cpp_dart` resolves to a published version.

## Licensing
whisper.cpp (MIT) is fetched at build time. Review the licenses of any models you
download and ship.
