class ModelItem {
  final String name; // human-friendly
  final String filename; // local filename under models/
  final String url; // public, no-auth download URL
  final int? sizeBytes; // optional, for display/check
  final String? sha256; // optional, for later integrity check
  const ModelItem({required this.name, required this.filename, required this.url, this.sizeBytes, this.sha256});
}

// NOTE:
// - URLs verified to return HTTP 200 (public, token-free) as of 2026-06.
// - Whisper.cpp models use the `.bin` (ggml) extension, NOT `.gguf`.
// - Gemma 4 E2B is Google's on-device "edge" model (April 2026); GGUFs are
//   officially convertible and hosted. We use a compact Q3_K_M quant (~2.5GB)
//   so it fits comfortably on-device while keeping multilingual (incl. Korean) quality.

ModelItem? modelByFilename(String filename) {
  for (final it in kModelManifest) {
    if (it.filename == filename) return it;
  }
  return null;
}

const kModelManifest = <ModelItem>[
  // ---- ASR (Whisper) ----
  ModelItem(
    name: 'whisper-small-q5_1',
    filename: 'whisper-small-q5_1.bin',
    url: 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small-q5_1.bin?download=true',
    sizeBytes: 190 * 1000 * 1000,
  ),

  // ---- LLM family ----
  // Gemma 4 E2B (on-device edge, 140 languages). Compact Q3_K_M (~2.5GB).
  ModelItem(
    name: 'gemma-4-E2B-it-q3_k_m',
    filename: 'gemma-4-E2B-it-Q3_K_M.gguf',
    url: 'https://huggingface.co/unsloth/gemma-4-E2B-it-GGUF/resolve/main/gemma-4-E2B-it-Q3_K_M.gguf?download=true',
    sizeBytes: 2540 * 1000 * 1000,
  ),
  // Qwen 2.5 0.5B instruct (smallest baseline)
  ModelItem(
    name: 'qwen2.5-0.5b-instruct-q4_k_m',
    filename: 'qwen2.5-0.5b-instruct-q4_k_m.gguf',
    url: 'https://huggingface.co/bartowski/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/Qwen2.5-0.5B-Instruct-Q4_K_M.gguf?download=true',
    sizeBytes: 400 * 1000 * 1000,
  ),
  // Llama 3.2 1B instruct (balanced default)
  ModelItem(
    name: 'llama-3.2-1b-instruct-q4_k_m',
    filename: 'llama-3.2-1b-instruct-q4_k_m.gguf',
    url: 'https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf?download=true',
    sizeBytes: 800 * 1000 * 1000,
  ),
  // Phi-3 Mini 3.8B instruct (accuracy first)
  ModelItem(
    name: 'phi-3-mini-3.8b-instruct-q4_k_m',
    filename: 'phi-3-mini-3.8b-instruct-q4_k_m.gguf',
    url: 'https://huggingface.co/bartowski/Phi-3-mini-3.8B-Instruct-GGUF/resolve/main/Phi-3-mini-3.8B-instruct-Q4_K_M.gguf?download=true',
    sizeBytes: 2300 * 1000 * 1000,
  ),
];
