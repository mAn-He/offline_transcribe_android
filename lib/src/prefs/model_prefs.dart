import 'package:shared_preferences/shared_preferences.dart';

class ModelPrefs {
  static const _kLlmFile = 'selected_llm_filename';
  static const _kAsrFile = 'selected_asr_filename';

  static Future<void> save({required String llmFilename, required String asrFilename}) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kLlmFile, llmFilename);
    await sp.setString(_kAsrFile, asrFilename);
  }

  static Future<(String?, String?)> load() async {
    final sp = await SharedPreferences.getInstance();
    return (sp.getString(_kLlmFile), sp.getString(_kAsrFile));
  }
}
