import 'package:flutter/material.dart';

class AppTheme {
  // Essa cor principal foi baseada no verde do seu AppBar atual
  static const Color corPrimaria = Color(0xFF2E7D32); 

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: corPrimaria,
      colorScheme: ColorScheme.fromSeed(
        seedColor: corPrimaria,
        primary: corPrimaria,
      ),
      // Padroniza todas as barras superiores do app
      appBarTheme: const AppBarTheme(
        backgroundColor: corPrimaria,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      // Padroniza todos os botões do app
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: corPrimaria,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}