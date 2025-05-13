import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:primer_parcial/domain/models/app_settings.dart';

import 'dart:ui';

final Provider<List<Color>> colorListProvider = Provider((ref) => colorList);
final Provider<List<String>> colorNamesProvider = Provider((ref) => colorNames);

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>(
      (ref) => SettingsNotifier(),
    );

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings());

  void toggleDarkMode() {
    state = state.copyWith(isDarkMode: !state.isDarkMode);
  }

  void changeColorSettings(int color) {
    state = state.copyWith(selectedColor: color);
  }

  void changeFontSize(double fontSize) {
    state = state.copyWith(fontSize: fontSize);
  }
}
