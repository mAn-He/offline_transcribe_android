class LlmOption {
  final String id; // key in manifest filename mapping
  final String titleKo; // Korean label
  final String subtitleKo; // desc
  final String manifestFilename; // matches ModelItem.filename
  const LlmOption({required this.id, required this.titleKo, required this.subtitleKo, required this.manifestFilename});
}

// LLM choices (install-time selectable). gemma-3-270m was removed (dead/gated link).
const llmOptions = <LlmOption>[
  LlmOption(
    id: 'gemma4_e2b',
    titleKo: '온디바이스 멀티링궐 (신형)',
    subtitleKo: 'Gemma 4 E2B Q3_K_M · 약 2.5GB · 140개 언어 · 모바일 엣지 전용',
    manifestFilename: 'gemma-4-E2B-it-Q3_K_M.gguf',
  ),
  LlmOption(
    id: 'qwen05b',
    titleKo: '가장 가볍고 빠름',
    subtitleKo: 'Qwen2.5 0.5B Instruct · 초소형 · 빠름',
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
    titleKo: '정확도 우선(권장)',
    subtitleKo: 'Whisper Small Q5_1 · 약 190MB · 정확도↑',
    manifestFilename: 'whisper-small-q5_1.bin',
  ),
];
