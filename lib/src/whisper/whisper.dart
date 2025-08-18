import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart' as pkgffi;

import '../ffi/whisper_bindings.dart' as gen;

class ASRResult { final String text; ASRResult(this.text); }

Future<ASRResult> runWhisperASR(String wavPath, {required String modelPath, void Function(double p)? onProgress}) async {
  final lib = _openLib();
  final w = gen.WhisperFFI(lib);

  final modelPathPtr = modelPath.toNativeUtf8().cast<ffi.Uint8>();
  final model = w.whisper_load_model(modelPathPtr);
  pkgffi.malloc.free(modelPathPtr);
  if (model.address == 0) throw 'Failed to load whisper model';

  final wavPathPtr = wavPath.toNativeUtf8().cast<ffi.Uint8>();
  final ctx = w.whisper_init_from_file_with_params(wavPathPtr, model);
  pkgffi.malloc.free(wavPathPtr);
  if (ctx.address == 0) throw 'Failed to init whisper context';

  // Use default params for now (struct-by-value); tune in native layer
  final params = w.whisper_full_default_params(0);

  final res = w.whisper_full(ctx, params, 0);
  if (res != 0) throw 'whisper_full failed: $res';

  final outTextPtr = w.whisper_collect_text(ctx);
  final outText = outTextPtr.cast<pkgffi.Utf8>().toDartString();

  w.whisper_free(ctx);
  w.whisper_free_model(model);
  return ASRResult(outText);
}

ffi.DynamicLibrary _openLib() {
  if (Platform.isAndroid) {
    return ffi.DynamicLibrary.open('libwhisper_ffi.so');
  }
  throw UnsupportedError('Only Android supported in this example');
}
