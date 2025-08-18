import 'dart:isolate';
import 'dart:io';
import 'dart:isolate';
import 'dart:io';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';

import 'model_manifest.dart';

class ModelDownloader {
  static Future<void> ensureModelsDownloaded() async {
    await FlutterDownloader.initialize(debug: false, ignoreSsl: true);

    final dir = await getApplicationDocumentsDirectory();
    final models = Directory('${dir.path}/models');
    if (!await models.exists()) await models.create(recursive: true);

    for (final it in kModelManifest) {
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
