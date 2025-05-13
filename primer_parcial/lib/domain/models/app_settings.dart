import 'package:flutter/material.dart';

final List<Color> colorList = [
  Colors.red,
  Colors.green,
  Colors.blue,
  Colors.black,
  Colors.white,
  Colors.transparent,
];

final List<String> colorNames = [
  "Red",
  "Green",
  "Blue",
  "Black",
  "White",
  "Transparent",
];

class AppSettings {
  final int selectedColor;
  final bool isDarkMode;
  final double fontSize;

  AppSettings({
    this.selectedColor = 0,
    this.isDarkMode = false,
    this.fontSize = 20,
  }) : assert(selectedColor >= 0, 'selectedColor must be greater than 0'),
       assert(
         selectedColor < colorList.length,
         'selectedColor must be less than colorList.length',
       );

  ThemeData getTheme() {
    return ThemeData(
      colorSchemeSeed: colorList[selectedColor],
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(centerTitle: false),
      textTheme: TextTheme(
        bodyLarge: TextStyle(fontSize: fontSize),
        bodyMedium: TextStyle(fontSize: fontSize),
        bodySmall: TextStyle(
          fontSize: fontSize * 0.85,
        ), // para texto un poco más pequeño
        // Configura más estilos según necesites
      ),
    );
  }

  AppSettings copyWith({
    int? selectedColor,
    bool? isDarkMode,
    double? fontSize,
  }) {
    return AppSettings(
      selectedColor: selectedColor ?? this.selectedColor,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}
