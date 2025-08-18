import 'dart:io';

import 'package:ffmpeg_kit_flutter_min/ffmpeg_kit.dart';

Future<String> ensureWav16kMono(String inputPath) async {
  final out = inputPath.replaceAll(RegExp(r'\.[^.]+$'), '') + '_16k_mono.wav';
  if (await File(out).exists()) return out;
  final cmd =
      "-y -i '${inputPath.replaceAll("'", "\\'")}' -ac 1 -ar 16000 -f wav -c:a pcm_s16le '${out.replaceAll("'", "\\'")}'";
  final session = await FFmpegKit.execute(cmd);
  final rc = await session.getReturnCode();
  if (rc?.isValueSuccess() != true) {
    final log = await session.getAllLogsAsString();
    throw 'ffmpeg failed: $rc\n$log';
  }
  return out;
}
