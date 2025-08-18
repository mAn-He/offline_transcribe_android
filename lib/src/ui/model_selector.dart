import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../download/model_manifest.dart';
import '../models/model_options.dart';

class ModelSelectorSheet extends StatefulWidget {
  final String? initialLlmFilename;
  final String? initialAsrFilename;
  const ModelSelectorSheet({super.key, this.initialLlmFilename, this.initialAsrFilename});

  @override
  State<ModelSelectorSheet> createState() => _ModelSelectorSheetState();
}

class _ModelSelectorSheetState extends State<ModelSelectorSheet> {
  String? llm;
  String? asr;

  @override
  void initState() {
    super.initState();
    llm = widget.initialLlmFilename;
    asr = widget.initialAsrFilename;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('모델을 선택하세요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('LLM'),
            ...llmOptions.map((o) => RadioListTile<String>(
                  title: Text(o.titleKo),
                  subtitle: Text(o.subtitleKo),
                  value: o.manifestFilename,
                  groupValue: llm,
                  onChanged: (v) => setState(() => llm = v),
                )),
            const Divider(),
            const Text('ASR'),
            ...asrOptions.map((o) => RadioListTile<String>(
                  title: Text(o.titleKo),
                  subtitle: Text(o.subtitleKo),
                  value: o.manifestFilename,
                  groupValue: asr,
                  onChanged: (v) => setState(() => asr = v),
                )),
            const SizedBox(height: 8),
            Row(children: [
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context, {'llm': llm, 'asr': asr});
                },
                child: const Text('확인'),
              ),
              const SizedBox(width: 8),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            ])
          ],
        ),
      ),
    );
  }
}
