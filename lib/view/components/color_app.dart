import 'package:flutter/material.dart';

class ColorApp {
  // Cores Base (Hexadecimais)
  static const Color orangeHighlight = Color(0xFFFE9636);
  static const Color deepBlack = Color(0xFF121212); 
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color softWhite = Color(0xFFF5F5F5);

  // Esquema de Cores para Modo CLARO
  static ColorScheme get lightScheme => const ColorScheme(
        brightness: Brightness.light,
        primary: orangeHighlight,
        onPrimary: Colors.white,
        secondary: accentBlue,
        onSecondary: Colors.white,
        error: Colors.red,
        onError: Colors.white,
        surface: softWhite, 
        onSurface: deepBlack, 
      );

  // Esquema de Cores para Modo ESCURO
  static ColorScheme get darkScheme => const ColorScheme(
        brightness: Brightness.dark,
        primary: orangeHighlight,
        onPrimary: deepBlack,
        secondary: accentBlue,
        onSecondary: Colors.white,
        error: Colors.redAccent,
        onError: Colors.white,
        surface: deepBlack, 
        onSurface: Colors.white,
      );
}