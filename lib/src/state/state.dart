import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppState {
  final String? audioPath;
  final double progress; // 0..1
  final String? result;
  const AppState({this.audioPath, this.progress = 0, this.result});

  AppState copyWith({String? audioPath, double? progress, String? result}) =>
      AppState(
        audioPath: audioPath ?? this.audioPath,
        progress: progress ?? this.progress,
        result: result ?? this.result,
      );
}

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(const AppState());

  void setAudioPath(String path) => state = state.copyWith(audioPath: path);
  void setProgress(double p) => state = state.copyWith(progress: p);
  void setResult(String r) => state = state.copyWith(result: r);
}

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) => AppStateNotifier());
