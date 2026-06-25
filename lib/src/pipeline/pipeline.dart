import 'dart:isolate';
import 'dart:io';
import 'dart:convert';

import '../utils/io_paths.dart';
import '../utils/ffmpeg.dart';
import '../whisper/whisper.dart';
import '../llm/llm.dart';

class PipelineIsolateInit {
  final SendPort port;
  final Map input;
  PipelineIsolateInit(this.port, this.input);
}

void runPipelineIsolate(PipelineIsolateInit init) async {
  final SendPort port = init.port;
  final Map input = init.input;

  try {
    final audioPath = input['audioPath'] as String?;
    if (audioPath == null) throw 'audioPath missing';

    // Forwarded from the UI selection (ModelPrefs), so the pipeline honors it.
    final asrFile = input['asrFile'] as String?;
    final llmFile = input['llmFile'] as String?;

    void progress(double p, String stage) => port.send({'type': 'progress', 'value': p, 'stage': stage});

    progress(0.02, 'prepare-paths');
    final paths = await ensureModelAndPaths(whisperFilename: asrFile, llamaFilename: llmFile);

    // Fail early with a clear message if the selected models were not downloaded.
    if (!await File(paths.whisperModelPath).exists()) {
      throw 'Whisper model missing: ${paths.whisperModelPath} (download it first)';
    }
    if (!await File(paths.llamaModelPath).exists()) {
      throw 'LLM model missing: ${paths.llamaModelPath} (download it first)';
    }

    progress(0.06, 'ffmpeg-preprocess');
    final wavPath = await ensureWav16kMono(audioPath);

    progress(0.12, 'whisper-asr');
    final asr = await runWhisperASR(wavPath, modelPath: paths.whisperModelPath, onProgress: (p) => progress(0.12 + p * 0.58, 'whisper-asr'));

    progress(0.70, 'map-reduce');
    final minutes = await summarizeAndTranslate(asr.text, modelPath: paths.llamaModelPath, onProgress: (p) => progress(0.70 + p * 0.28, 'llm'));

    final out = '--- ASR (timestamps suppressed) ---\n${asr.text}\n\n--- Final Minutes (KO) ---\n$minutes\n';

    // Persist result to file for large output safety
    final outFile = File(paths.outputDir + '/minutes.txt');
    await outFile.writeAsString(out);

    port.send({'type': 'done', 'path': outFile.path});
  } catch (e, st) {
    port.send({'type': 'error', 'error': e.toString(), 'stack': st.toString()});
  }
}
