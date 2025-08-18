// Minimal manual FFI bindings matching android/app/src/main/cpp/whisper_c_api.h
// For production, use: dart run ffigen --config ffigen.yaml

import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart' as pkgffi;

class WhisperParams extends ffi.Struct {
  @ffi.Uint8()
  external int translate;

  @ffi.Uint8()
  external int print_progress;

  @ffi.Uint8()
  external int print_realtime;

  @ffi.Uint8()
  external int print_timestamps;
}

typedef _whisper_load_model_c = ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Uint8>);
typedef _whisper_load_model_d = ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Uint8>);

typedef _whisper_free_model_c = ffi.Void Function(ffi.Pointer<ffi.Void>);
typedef _whisper_free_model_d = void Function(ffi.Pointer<ffi.Void>);

typedef _whisper_init_ctx_c = ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Uint8>, ffi.Pointer<ffi.Void>);
typedef _whisper_init_ctx_d = ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Uint8>, ffi.Pointer<ffi.Void>);

typedef _whisper_free_c = ffi.Void Function(ffi.Pointer<ffi.Void>);
typedef _whisper_free_d = void Function(ffi.Pointer<ffi.Void>);

typedef _whisper_full_default_params_c = WhisperParams Function(ffi.Int32);
typedef _whisper_full_default_params_d = WhisperParams Function(int);

typedef _whisper_full_c = ffi.Int32 Function(ffi.Pointer<ffi.Void>, WhisperParams, ffi.Int32);
typedef _whisper_full_d = int Function(ffi.Pointer<ffi.Void>, WhisperParams, int);

typedef _whisper_collect_text_c = ffi.Pointer<ffi.Uint8> Function(ffi.Pointer<ffi.Void>);
typedef _whisper_collect_text_d = ffi.Pointer<ffi.Uint8> Function(ffi.Pointer<ffi.Void>);

class WhisperFFI {
  final ffi.DynamicLibrary _lib;
  late final _whisper_load_model_d whisper_load_model;
  late final _whisper_free_model_d whisper_free_model;
  late final _whisper_init_ctx_d whisper_init_from_file_with_params;
  late final _whisper_free_d whisper_free;
  late final _whisper_full_default_params_d whisper_full_default_params;
  late final _whisper_full_d whisper_full;
  late final _whisper_collect_text_d whisper_collect_text;

  WhisperFFI(this._lib) {
    whisper_load_model = _lib.lookupFunction<_whisper_load_model_c, _whisper_load_model_d>('whisper_load_model');
    whisper_free_model = _lib.lookupFunction<_whisper_free_model_c, _whisper_free_model_d>('whisper_free_model');
    whisper_init_from_file_with_params = _lib.lookupFunction<_whisper_init_ctx_c, _whisper_init_ctx_d>('whisper_init_from_file_with_params');
    whisper_free = _lib.lookupFunction<_whisper_free_c, _whisper_free_d>('whisper_free');
    whisper_full_default_params = _lib.lookupFunction<_whisper_full_default_params_c, _whisper_full_default_params_d>('whisper_full_default_params');
    whisper_full = _lib.lookupFunction<_whisper_full_c, _whisper_full_d>('whisper_full');
    whisper_collect_text = _lib.lookupFunction<_whisper_collect_text_c, _whisper_collect_text_d>('whisper_collect_text');
  }
}
