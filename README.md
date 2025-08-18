# Offline Multilingual Meeting Minutes (Flutter + On-Device AI)

This repository contains a Flutter application that generates high-quality Korean meeting minutes entirely offline on Galaxy S24+ class devices. It integrates Whisper (ASR) and Llama (LLM) through direct Dart FFI for maximum performance, avoiding platform channels. The design targets long-running audio processing (up to ~2 hours), robust background execution, and post-install model downloads (3–5GB total).

Warning: This repo ships with a skeleton native FFI wrapper and does NOT vendor the full whisper.cpp sources or large GGUF models. Follow the instructions below to fetch them.

## Goals and Key Constraints
- Performance-first: Direct FFI to a C++ engine, aggressive ARM64 optimizations
- 100% Offline: All inference runs on-device (no network required after model download)
- Long-running: Stable processing for up to ~2 hours of audio
- Resource management: Handle 3–5GB models efficiently
- Target: Flutter (Android ARM64)

## Architecture Overview
- Flutter UI + Riverpod state
- Background orchestration via WorkManager (foreground service) -> spawns a dedicated Dart Isolate for heavy compute
- Direct FFI to native C++ (whisper.cpp) for ASR
- LLM via llama_cpp_dart (llama.cpp under the hood)
- FFmpeg for audio pre-processing (normalize to 16kHz mono PCM WAV)
- Post-install model download with flutter_downloader
- Map-Reduce summarization/translation using llama and langchain_dart-like flow (implemented directly here)

```
UI (Flutter) ──▶ WorkManager task ──▶ Compute Isolate ──▶
  ├─ FFmpeg: audio → 16kHz mono PCM WAV
  ├─ Whisper (FFI): ASR with timestamps
  └─ Llama (llama_cpp_dart): Map-Reduce summarization/translation → Final minutes (KO)
```

## Repository Structure
```
lib/
  main.dart                        # UI & WorkManager registration
  src/state/state.dart             # Simple Riverpod state
  src/pipeline/pipeline.dart       # End-to-end pipeline in Isolate
  src/utils/ffmpeg.dart            # Audio preprocessing
  src/utils/io_paths.dart          # Model/output paths
  src/llm/llm.dart                 # Llama orchestration (map-reduce style)
  src/ffi/whisper_bindings.dart    # Minimal manual FFI bindings (replace by ffigen)
  src/whisper/whisper.dart         # Whisper Dart side wrapper
  src/download/model_downloader.dart# Post-install downloads
android/
  app/src/main/cpp/                # CMake, C API shim, vendor whisper.cpp here
  app/src/main/AndroidManifest.xml # Foreground service + permissions
```

## Prerequisites
- Flutter SDK (3.19+), Android Studio, Android NDK (r26+), CMake (3.22+)
- Galaxy S24+ (ARM64, Android 14) or equivalent ARM64 device
- Models (downloaded post-install):
  - Whisper-small (or base) GGUF (quantized)
  - Phi-3 Mini 3.8B Instruct GGUF (quantized)

## Native Build Setup (CMake/NDK)
1) Fetch whisper.cpp into android/app/src/main/cpp/whisper
- Place ggml.c/.h, whisper.cpp/.h and any required sources there
- If you target GPU or DSP acceleration, wire flags and libs in CMake

2) Ensure CMakeLists
- android/app/src/main/cpp/CMakeLists.txt builds a shared lib: libwhisper_ffi.so
- android/app/src/main/cpp/whisper/CMakeLists.txt builds static lib whisper
- Link whisper_ffi against whisper and log

3) Android Gradle
- externalNativeBuild configured with CMake
- arm64-v8a ABI, c++_shared STL, -O3 -DNDEBUG -D_FILE_OFFSET_BITS=64

4) JNI loading
- Dart opens libwhisper_ffi.so on Android

## FFI and Binding Generation
- Header: android/app/src/main/cpp/whisper_c_api.h exposes a stable C ABI
- Generate Dart bindings via ffigen.yaml:
  - dart run ffigen --config ffigen.yaml
- For now, lib/src/ffi/whisper_bindings.dart contains minimal manual bindings for bootstrap

## Post-install Model Downloads
- path_provider chooses app docs dir, models under <docs>/models
- flutter_downloader enqueues downloads on first run
- Configure your real model URLs in lib/src/download/model_downloader.dart
- Ensure foreground notifications are allowed (Android 13+ requires POST_NOTIFICATIONS)

## Long-Running and Foreground Service
- WorkManager registers a one-off task that spins a compute Isolate
- Show a persistent notification (implement native side if you need full control)
- Keep CPU awake with WAKE_LOCK permission; ensure OS power exemptions when testing

## Audio Preprocessing
- ffmpeg_kit_flutter_min converts any input into 16kHz mono PCM WAV required by whisper.cpp

## ASR Pipeline (Whisper)
- Custom C API wraps whisper.cpp; parameters available in whisper_params_t
- Implement real audio ingestion and decoding in android/app/src/main/cpp/whisper_c_api.cpp
- Current code returns a dummy transcript. Replace TODO with calling whisper_full() over the 16k WAV file.

## LLM Pipeline (Llama)
- Uses llama_cpp_dart to load Phi-3 Mini GGUF
- Splits long transcript into chunks (~2200 chars), map summarizes in Korean, then reduce to final minutes
- Tune context length, n_threads, sampling, and chunk sizes for device

## Resource Management Tips (S24+)
- Use arm64-v8a only, avoid fat APKs
- Place models in app docs dir; keep free space checks before download
- Consider mmap load options and ggml offloading where applicable
- Use n_threads equal to big-core count; cap temperature for deterministic summaries

## Building and Running
1) Install Flutter deps
- flutter pub get

2) Generate bindings (optional once you have real header)
- dart run ffigen --config ffigen.yaml

3) Build & run on device
- flutter run --release --target-platform=android-arm64

4) Trigger the pipeline
- Pick an audio file in the UI
- Press "Run pipeline (background)"
- Results saved to <docs>/outputs/minutes.txt

## Model Provisioning
- Update lib/src/download/model_downloader.dart with your HTTPS links
- First app start will schedule downloads; show progress in notification
- Verify files exist at <docs>/models before running pipeline

## Security & Licensing
- You own the C API shim; do not expose or distribute GPL code beyond permissible usage if you embed whisper.cpp. Review licenses carefully.

## Next Steps / Production Hardening
- Implement real whisper.cpp invocation (read PCM, call whisper_full, collect segments + timestamps)
- Add speaker diarization prompt post-processing using the LLM
- Implement foreground notification from the worker (Kotlin Service + NotificationChannel)
- Persist structured JSON (agenda, decisions, action items) in addition to minutes.txt
- Resume-able downloads and storage quota checks
- Thermal and battery-aware throttling; partial batch processing for >2h inputs

## Troubleshooting
- If the app crashes on library load: verify libwhisper_ffi.so built for arm64-v8a and bundled
- If LLM fails to load: check GGUF filename path and available RAM; try lower-quant model
- If FFmpeg fails: inspect logs from FFmpegKit in Logcat
- If background task stops: ensure foreground service and battery optimizations are disabled during tests
