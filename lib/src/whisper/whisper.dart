import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart' as pkgffi;

import '../ffi/whisper_bindings.dart' as gen;

class ASRResult {
  final String text;
  ASRResult(this.text);
}

Future<ASRResult> runWhisperASR(String wavPath, {required String modelPath, void Function(double p)? onProgress}) async {
  final lib = _openLib();
  final w = gen.WhisperFFI(lib);

  onProgress?.call(0.0);

  final modelPathPtr = modelPath.toNativeUtf8().cast<ffi.Uint8>();
  final model = w.wffiLoadModel(modelPathPtr);
  pkgffi.malloc.free(modelPathPtr);
  if (model.address == 0) throw 'Failed to load whisper model: $modelPath';

  final wavPathPtr = wavPath.toNativeUtf8().cast<ffi.Uint8>();
  final ctx = w.wffiPrepare(wavPathPtr, model);
  pkgffi.malloc.free(wavPathPtr);
  if (ctx.address == 0) {
    w.wffiFreeModel(model);
    throw 'Failed to load/decode WAV: $wavPath';
  }

  try {
    // Auto thread count + Korean auto-detect are handled in the native layer.
    final params = w.wffiDefaultParams();

    final res = w.wffiFull(ctx, params);
    if (res != 0) throw 'whisper_full failed: $res';

    final outTextPtr = w.wffiCollectText(ctx);
    final outText = outTextPtr.cast<pkgffi.Utf8>().toDartString();
    onProgress?.call(1.0);
    return ASRResult(outText);
  } finally {
    w.wffiFreeCtx(ctx);
    w.wffiFreeModel(model);
  }
}

ffi.DynamicLibrary _openLib() {
  if (Platform.isAndroid) {
    return ffi.DynamicLibrary.open('libwhisper_ffi.so');
  }
  throw UnsupportedError('Only Android supported in this example');
}
