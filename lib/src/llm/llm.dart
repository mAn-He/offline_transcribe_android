import 'dart:async';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import '../utils/io_paths.dart';

Future<String> summarizeAndTranslate(String longText, {void Function(double p)? onProgress}) async {
  final paths = await ensureModelAndPaths();
  final modelPath = paths.llamaModelPath;

  final llama = LlamaIsolate();
  await llama.load(modelPath: modelPath, config: const LlamaConfig());

  final chunks = _splitIntoChunks(longText, 2200); // token-approx by chars
  final results = <String>[];
  for (var i = 0; i < chunks.length; i++) {
    onProgress?.call(i / (chunks.length + 1));
    final prompt = '다음은 긴 회의의 일부 내용입니다. 내용을 요약하고 한국어로 번역하십시오.\n\n---\n${chunks[i]}\n---\n요약:';
    final out = await llama.inference(prompt: prompt, maxTokens: 512, temperature: 0.3);
    results.add(out);
  }

  onProgress?.call(0.9);
  final reducePrompt = '다음은 회의 요약본들입니다. 이를 통합하여 전체 회의의 핵심 안건, 결정 사항, 향후 계획을 포함한 최종 한국어 회의록을 작성하십시오.\n\n${results.join('\n\n')}\n\n최종 회의록:';
  final finalOut = await llama.inference(prompt: reducePrompt, maxTokens: 1024, temperature: 0.3);
  onProgress?.call(1.0);
  await llama.unload();
  return finalOut;
}

List<String> _splitIntoChunks(String text, int chunkSize) {
  final res = <String>[];
  for (int i = 0; i < text.length; i += chunkSize) {
    res.add(text.substring(i, i + chunkSize > text.length ? text.length : i + chunkSize));
  }
  return res;
}
