import 'dart:io';

import 'package:flutter_downloader/flutter_downloader.dart';

import '../utils/io_paths.dart';
import 'model_manifest.dart';

class ModelDownloader {
  /// Enqueue downloads for the given local filenames if they are not already
  /// present under <docs>/models. Returns the filenames that were enqueued.
  ///
  /// We download only what the user selected (ASR + LLM) rather than the whole
  /// manifest, which would be 15GB+. flutter_downloader shows its own progress
  /// notification and survives app backgrounding.
  static Future<List<String>> ensureDownloaded(List<String> filenames) async {
    final basePath = await modelsBaseDir();
    final enqueued = <String>[];

    for (final filename in filenames) {
      if (filename.isEmpty) continue;
      final item = modelByFilename(filename);
      if (item == null) continue; // unknown filename, skip silently

      final f = File('$basePath/${item.filename}');
      if (await f.exists() && await f.length() > 0) continue; // already there

      await FlutterDownloader.enqueue(
        url: item.url,
        savedDir: basePath,
        fileName: item.filename,
        showNotification: true,
        openFileFromNotification: false,
        saveInPublicStorage: false,
      );
      enqueued.add(item.filename);
    }
    return enqueued;
  }

  /// True only when every requested filename exists locally with non-zero size.
  static Future<bool> allPresent(List<String> filenames) async {
    final basePath = await modelsBaseDir();
    for (final filename in filenames) {
      if (filename.isEmpty) continue;
      final f = File('$basePath/$filename');
      if (!await f.exists() || await f.length() == 0) return false;
    }
    return true;
  }
}
