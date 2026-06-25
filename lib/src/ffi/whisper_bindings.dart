// Minimal manual FFI bindings matching android/app/src/main/cpp/whisper_c_api.h
// For production, regenerate via: dart run ffigen --config ffigen.yaml
//
// Symbols are the `wffi_*` C ABI (distinct from whisper.cpp's own symbols).

import 'dart:ffi' as ffi;

// Mirrors `wffi_params_t` in whisper_c_api.h:
//   int  n_threads;   // 4 bytes
//   bool translate;   // 1 byte
//   bool print_progress;
//   bool print_timestamps;
final class WffiParams extends ffi.Struct {
  @ffi.Int32()
  external int n_threads;

  @ffi.Uint8()
  external int translate;

  @ffi.Uint8()
  external int print_progress;

  @ffi.Uint8()
  external int print_timestamps;
}

typedef _load_model_c = ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Uint8>);
typedef _load_model_d = ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Uint8>);

typedef _free_model_c = ffi.Void Function(ffi.Pointer<ffi.Void>);
typedef _free_model_d = void Function(ffi.Pointer<ffi.Void>);

typedef _prepare_c = ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Uint8>, ffi.Pointer<ffi.Void>);
typedef _prepare_d = ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Uint8>, ffi.Pointer<ffi.Void>);

typedef _free_ctx_c = ffi.Void Function(ffi.Pointer<ffi.Void>);
typedef _free_ctx_d = void Function(ffi.Pointer<ffi.Void>);

typedef _default_params_c = WffiParams Function();
typedef _default_params_d = WffiParams Function();

typedef _full_c = ffi.Int32 Function(ffi.Pointer<ffi.Void>, WffiParams);
typedef _full_d = int Function(ffi.Pointer<ffi.Void>, WffiParams);

typedef _collect_text_c = ffi.Pointer<ffi.Uint8> Function(ffi.Pointer<ffi.Void>);
typedef _collect_text_d = ffi.Pointer<ffi.Uint8> Function(ffi.Pointer<ffi.Void>);

class WhisperFFI {
  final ffi.DynamicLibrary _lib;
  late final _load_model_d wffiLoadModel;
  late final _free_model_d wffiFreeModel;
  late final _prepare_d wffiPrepare;
  late final _free_ctx_d wffiFreeCtx;
  late final _default_params_d wffiDefaultParams;
  late final _full_d wffiFull;
  late final _collect_text_d wffiCollectText;

  WhisperFFI(this._lib) {
    wffiLoadModel = _lib.lookupFunction<_load_model_c, _load_model_d>('wffi_load_model');
    wffiFreeModel = _lib.lookupFunction<_free_model_c, _free_model_d>('wffi_free_model');
    wffiPrepare = _lib.lookupFunction<_prepare_c, _prepare_d>('wffi_prepare');
    wffiFreeCtx = _lib.lookupFunction<_free_ctx_c, _free_ctx_d>('wffi_free_ctx');
    wffiDefaultParams = _lib.lookupFunction<_default_params_c, _default_params_d>('wffi_default_params');
    wffiFull = _lib.lookupFunction<_full_c, _full_d>('wffi_full');
    wffiCollectText = _lib.lookupFunction<_collect_text_c, _collect_text_d>('wffi_collect_text');
  }
}
