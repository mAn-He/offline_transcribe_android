import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ModelSetupSheet extends StatefulWidget {
  const ModelSetupSheet({super.key});
  @override
  State<ModelSetupSheet> createState() => _ModelSetupSheetState();
}

class _ModelSetupSheetState extends State<ModelSetupSheet> {
  String? whisper;
  String? llama;
  String? base;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dir = await getApplicationDocumentsDirectory();
    setState(() { base = dir.path; });
    final w = File('${dir.path}/models/whisper-small-q5_1.gguf');
    final l = File('${dir.path}/models/phi-3-mini-3.8b-instruct-q4_k_m.gguf');
    setState(() {
      whisper = w.existsSync() ? w.path : null;
      llama = l.existsSync() ? l.path : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Model directory: ${base ?? '-'}'),
          const SizedBox(height: 8),
          Text('Whisper: ${whisper ?? 'MISSING'}'),
          Text('Llama:   ${llama ?? 'MISSING'}'),
          const SizedBox(height: 12),
          const Text('Side-load the GGUF files into the paths above.'),
          const SizedBox(height: 8),
          Row(children: [
            ElevatedButton(onPressed: _load, child: const Text('Recheck')),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ])
        ],
      ),
    );
  }
}
