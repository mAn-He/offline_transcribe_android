class LlmOption {
  final String id; // key in manifest filename mapping
  final String titleKo; // Korean label
  final String subtitleKo; // desc
  final String manifestFilename; // matches ModelItem.filename
  const LlmOption({required this.id, required this.titleKo, required this.subtitleKo, required this.manifestFilename});
}

// LLM choices (install-time selectable)
const llmOptions = <LlmOption>[
  LlmOption(
    id: 'gemma270m',
    titleKo: '어디에서든 빠르게 도움받기',
    subtitleKo: 'Gemma 3 270M · 초소형 · 매우 빠름 · 메모리 사용량 최소',
    manifestFilename: 'gemma-3-270m-instruct-q4_k_m.gguf',
  ),
  LlmOption(
    id: 'qwen05b',
    titleKo: '추론, 수학 및 코딩',
    subtitleKo: 'Qwen2.5 0.5B Instruct · 소형 · 합리적 품질',
    manifestFilename: 'qwen2.5-0.5b-instruct-q4_k_m.gguf',
  ),
  LlmOption(
    id: 'llama1b',
    titleKo: '균형형 요약/번역',
    subtitleKo: 'Llama 3.2 1B Instruct · 중소형 · 균형',
    manifestFilename: 'llama-3.2-1b-instruct-q4_k_m.gguf',
  ),
  LlmOption(
    id: 'phi38b',
    titleKo: '정확도 우선(전력 소모↑)',
    subtitleKo: 'Phi-3 Mini 3.8B Instruct · 중형 · 품질↑',
    manifestFilename: 'phi-3-mini-3.8b-instruct-q4_k_m.gguf',
  ),
];

class AsrOption {
  final String id;
  final String titleKo;
  final String subtitleKo;
  final String manifestFilename;
  const AsrOption({required this.id, required this.titleKo, required this.subtitleKo, required this.manifestFilename});
}

const asrOptions = <AsrOption>[
  AsrOption(
    id: 'whisper-small',
    titleKo: '정확도 우선(대용량)',
    subtitleKo: 'Whisper Small Q5_1 · 정확도↑ · 용량/전력↑',
    manifestFilename: 'whisper-small-q5_1.gguf',
  ),
];
