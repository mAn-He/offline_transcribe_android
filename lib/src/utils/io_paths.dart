import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ModelPaths {
  final String baseDir;
  final String whisperModelPath;
  final String llamaModelPath;
  final String outputDir;
  ModelPaths({required this.baseDir, required this.whisperModelPath, required this.llamaModelPath, required this.outputDir});
}

Future<ModelPaths> ensureModelAndPaths() async {
  final dir = await getApplicationDocumentsDirectory();
  final base = Directory('${dir.path}/models');
  if (!await base.exists()) await base.create(recursive: true);

  final out = Directory('${dir.path}/outputs');
  if (!await out.exists()) await out.create(recursive: true);

  // For demo, assume fixed filenames; downloader will fetch if missing elsewhere
  final whisper = File('${base.path}/whisper-small-q5_1.gguf');
  final llama = File('${base.path}/phi-3-mini-3.8b-instruct-q4_k_m.gguf');

  return ModelPaths(
    baseDir: base.path,
    whisperModelPath: whisper.path,
    llamaModelPath: llama.path,
    outputDir: out.path,
  );
}
