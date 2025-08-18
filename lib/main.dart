import 'dart:async';
import 'dart:isolate';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/services.dart';

import 'src/pipeline/pipeline.dart';
import 'src/state/state.dart';

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
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  // First-run: ensure models download if missing (public links, no auth)
  try {
    // Lazy import to avoid startup issues if plugin not ready on some platforms
    // ignore: avoid_dynamic_calls
    final downloader = await Future.microtask(() => null);
  } catch (_) {}

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
                      // enqueue background job
                      Workmanager().registerOneOffTask(
                        'pipeline_${DateTime.now().millisecondsSinceEpoch}',
                        'runPipeline',
                        inputData: {
                          'audioPath': s.audioPath,
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
                    onPressed: () {
                      showModalBottomSheet(context: context, builder: (_) => const ModelSetupSheet());
                    },
                    icon: const Icon(Icons.storage),
                    label: const Text('Model check'),
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
