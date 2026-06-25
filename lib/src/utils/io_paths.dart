import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ModelPaths {
  final String baseDir;
  final String whisperModelPath;
  final String llamaModelPath;
  final String outputDir;
  ModelPaths({required this.baseDir, required this.whisperModelPath, required this.llamaModelPath, required this.outputDir});
}

// Defaults used when no explicit selection is passed in.
const kDefaultWhisperFilename = 'whisper-small-q5_1.bin';
const kDefaultLlamaFilename = 'llama-3.2-1b-instruct-q4_k_m.gguf';

Future<String> modelsBaseDir() async {
  final dir = await getApplicationDocumentsDirectory();
  final base = Directory('${dir.path}/models');
  if (!await base.exists()) await base.create(recursive: true);
  return base.path;
}

Future<String> outputsDir() async {
  final dir = await getApplicationDocumentsDirectory();
  final out = Directory('${dir.path}/outputs');
  if (!await out.exists()) await out.create(recursive: true);
  return out.path;
}

/// Resolves model paths. When [whisperFilename]/[llamaFilename] are provided
/// (e.g. forwarded from the UI selection), those are used; otherwise defaults.
Future<ModelPaths> ensureModelAndPaths({String? whisperFilename, String? llamaFilename}) async {
  final base = await modelsBaseDir();
  final out = await outputsDir();

  final whisper = File('$base/${(whisperFilename != null && whisperFilename.isNotEmpty) ? whisperFilename : kDefaultWhisperFilename}');
  final llama = File('$base/${(llamaFilename != null && llamaFilename.isNotEmpty) ? llamaFilename : kDefaultLlamaFilename}');

  return ModelPaths(
    baseDir: base,
    whisperModelPath: whisper.path,
    llamaModelPath: llama.path,
    outputDir: out,
  );
}
