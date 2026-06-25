import 'dart:async';
import 'dart:isolate';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/services.dart';

import 'src/pipeline/pipeline.dart';
import 'src/state/state.dart';
import 'src/ui/model_selector.dart';
import 'src/prefs/model_prefs.dart';
import 'src/download/model_downloader.dart';

const _fgChannel = MethodChannel('com.example.webapp/fg');

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await _fgChannel.invokeMethod('start', {'title': 'Transcribing', 'text': 'Preparing...', 'progress': 0});
    } catch (_) {}

    // Start isolate heavy work
    final port = ReceivePort();
    await Isolate.spawn(runPipelineIsolate, PipelineIsolateInit(port.sendPort, inputData ?? {}));

    // Wait for completion
    final completer = Completer<bool>();
    StreamSubscription? sub;
    sub = port.listen((msg) async {
      if (msg is Map && msg['type'] == 'progress') {
        try {
          final p = ((msg['value'] as double) * 100).toInt().clamp(0, 100);
          await _fgChannel.invokeMethod('update', {'stage': msg['stage'], 'progress': p});
        } catch (_) {}
      } else if (msg is Map && msg['type'] == 'done') {
        try { await _fgChannel.invokeMethod('stop'); } catch (_) {}
        completer.complete(true);
        sub?.cancel();
      } else if (msg is Map && msg['type'] == 'error') {
        try { await _fgChannel.invokeMethod('stop'); } catch (_) {}
        completer.complete(false);
        sub?.cancel();
      }
    });

    final ok = await completer.future;
    return Future.value(ok);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // flutter_downloader must be initialized once before any enqueue.
  await FlutterDownloader.initialize(debug: false, ignoreSsl: false);
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    return MaterialApp(
      title: 'On-device Minutes',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: Scaffold(
        appBar: AppBar(title: const Text('Offline Meeting Minutes (On-device)')),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final res = await FilePicker.platform.pickFiles(type: FileType.audio, allowMultiple: false);
                      if (res != null && res.files.single.path != null) {
                        ref.read(appStateProvider.notifier).setAudioPath(res.files.single.path!);
                      }
                    },
                    icon: const Icon(Icons.audiotrack),
                    label: const Text('Pick audio'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: s.audioPath == null ? null : () async {
                      // Resolve the user's model choice (falls back to defaults).
                      final (llmFile, asrFile) = await ModelPrefs.load();

                      // Make sure the selected models are present before running.
                      final needed = [
                        if (asrFile != null && asrFile.isNotEmpty) asrFile,
                        if (llmFile != null && llmFile.isNotEmpty) llmFile,
                      ];
                      if (needed.isNotEmpty && !await ModelDownloader.allPresent(needed)) {
                        await ModelDownloader.ensureDownloaded(needed);
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('모델 다운로드를 시작했습니다. 완료 후 다시 실행하세요.')),
                        );
                        return;
                      }

                      // enqueue background job
                      Workmanager().registerOneOffTask(
                        'pipeline_${DateTime.now().millisecondsSinceEpoch}',
                        'runPipeline',
                        inputData: {
                          'audioPath': s.audioPath,
                          'asrFile': asrFile ?? '',
                          'llmFile': llmFile ?? '',
                        },
                        constraints: Constraints(networkType: NetworkType.not_required),
                        existingWorkPolicy: ExistingWorkPolicy.replace,
                        backoffPolicy: BackoffPolicy.exponential,
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Run pipeline (background)'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final (savedLlm, savedAsr) = await ModelPrefs.load();
                      // ignore: use_build_context_synchronously
                      final selected = await showModalBottomSheet<Map<String, String>?>(
                        context: context,
                        builder: (_) => ModelSelectorSheet(
                          initialLlmFilename: savedLlm,
                          initialAsrFilename: savedAsr,
                        ),
                      );
                      if (selected != null) {
                        final llmFile = selected['llm'] ?? '';
                        final asrFile = selected['asr'] ?? '';
                        await ModelPrefs.save(llmFilename: llmFile, asrFilename: asrFile);

                        // Kick off downloads for whatever is still missing.
                        final enqueued = await ModelDownloader.ensureDownloaded([
                          if (asrFile.isNotEmpty) asrFile,
                          if (llmFile.isNotEmpty) llmFile,
                        ]);
                        final msg = enqueued.isEmpty
                            ? '선택됨 (이미 다운로드됨) → LLM: $llmFile, ASR: $asrFile'
                            : '선택됨 → 다운로드 시작: ${enqueued.join(", ")}';
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                      }
                    },
                    icon: const Icon(Icons.tune),
                    label: const Text('모델 선택'),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Text('Audio: ${s.audioPath ?? '-'}'),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: s.progress, minHeight: 8),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8)),
                  child: SingleChildScrollView(child: Text(s.result ?? 'Results will appear here...')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
