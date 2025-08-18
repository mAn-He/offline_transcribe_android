import 'dart:isolate';
import 'dart:io';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';

class ModelDownloader {
  static Future<void> ensureModelsDownloaded() async {
    await FlutterDownloader.initialize(debug: false, ignoreSsl: true);

    final dir = await getApplicationDocumentsDirectory();
    final models = Directory('${dir.path}/models');
    if (!await models.exists()) await models.create(recursive: true);

    final items = <_Item>[
      _Item(
        url: 'https://example.com/models/whisper-small-q5_1.gguf',
        filename: 'whisper-small-q5_1.gguf',
      ),
      _Item(
        url: 'https://example.com/models/phi-3-mini-3.8b-instruct-q4_k_m.gguf',
        filename: 'phi-3-mini-3.8b-instruct-q4_k_m.gguf',
      )
    ];

    for (final it in items) {
      final f = File('${models.path}/${it.filename}');
      if (await f.exists()) continue;
      await FlutterDownloader.enqueue(
        url: it.url,
        savedDir: models.path,
        fileName: it.filename,
        showNotification: true,
        openFileFromNotification: false,
      );
    }
  }
}

class _Item { final String url; final String filename; _Item({required this.url, required this.filename}); }
