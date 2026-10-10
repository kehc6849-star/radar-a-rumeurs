import 'package:flutter/material.dart';

/// Single place for the look of the application.
class ApplicationTheme {
  const ApplicationTheme._();

  static const Color _seedColor = Color(0xFF1F3A5F);

  static ThemeData buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: _seedColor,
      brightness: Brightness.light,
    );
  }
}
