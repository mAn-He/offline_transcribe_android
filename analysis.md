Notes for maintainers (non-distributed):
- The native whisper C API is a stub. Implement whisper_full path with proper PCM loading.
- Consider enabling NEON and ARMv8.2 dotprod: -mcpu=cortex-a78c -mfpu=neon -mfloat-abi=hard (check NDK Clang flags).
- For Galaxy S24+ (Snapdragon 8 Gen 3), tune threads and mmap flags.
