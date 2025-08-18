class ModelItem {
  final String name; // human-friendly
  final String filename; // local filename under models/
  final String url; // public, no-auth download URL
  final int? sizeBytes; // optional, for display/check
  final String? sha256; // optional, for later integrity check
  const ModelItem({required this.name, required this.filename, required this.url, this.sizeBytes, this.sha256});
}

// NOTE:
// - Replace URLs with your mirror/CDN if needed.
// - These example links point to typical public-hosted GGUF artifacts on Hugging Face
//   using the `resolve/main` form which does not require tokens for public repos.
// - Filenames are examples and may differ depending on your chosen conversions.

const kModelManifest = <ModelItem>[
  // Whisper
  ModelItem(
    name: 'whisper-small-q5_1',
    filename: 'whisper-small-q5_1.gguf',
    url: 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small-q5_1.gguf?download=true',
  ),
  // Llama family (example tiny baseline)
  ModelItem(
    name: 'llama-3.2-1b-instruct-q4_k_m',
    filename: 'llama-3.2-1b-instruct-q4_k_m.gguf',
    url: 'https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf?download=true',
  ),
  // Qwen (example 0.5B instruct)
  ModelItem(
    name: 'qwen2.5-0.5b-instruct-q4_k_m',
    filename: 'qwen2.5-0.5b-instruct-q4_k_m.gguf',
    url: 'https://huggingface.co/bartowski/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/Qwen2.5-0.5B-Instruct-Q4_K_M.gguf?download=true',
  ),
  // Phi (example 3.8B instruct)
  ModelItem(
    name: 'phi-3-mini-3.8b-instruct-q4_k_m',
    filename: 'phi-3-mini-3.8b-instruct-q4_k_m.gguf',
    url: 'https://huggingface.co/bartowski/Phi-3-mini-3.8B-Instruct-GGUF/resolve/main/Phi-3-mini-3.8B-instruct-Q4_K_M.gguf?download=true',
  ),
  // Gemma 3 270M (example tiny instruct)
  // Ensure a compatible GGUF is available; if using a different source, update the URL below.
  ModelItem(
    name: 'gemma-3-270m-instruct-q4_k_m',
    filename: 'gemma-3-270m-instruct-q4_k_m.gguf',
    url: 'https://huggingface.co/bartowski/Gemma-3-270M-Instruct-GGUF/resolve/main/Gemma-3-270M-Instruct-Q4_K_M.gguf?download=true',
  ),
];
