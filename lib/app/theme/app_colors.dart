import 'package:flutter/material.dart';

class AppColors {

  // Primary Colors (Golden)
  static const Color primary = Color(0xFFFFD700);
  static const Color secondary = Color(0xFFB8860B);

  // Golden Gradient Colors
  static const Color goldDark = Color(0xFF5A3F12);
  static const Color goldBase = Color(0xFFB88728);
  static const Color goldLight = Color(0xFFFCEFA2);

  static const LinearGradient goldenGradient = LinearGradient(
    colors: [
      goldDark, // Dark Shadow
      goldBase, // Base Gold
      goldLight, // Bright Highlight
      goldBase, // Base Gold
      goldDark, // Dark Shadow
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [
      goldBase,
      primary,
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Background Colors
  static const Color background = Colors.black;
  static const Color scaffoldBackground = Colors.black;

  // Text Colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Colors.grey;

  // Button Colors
  static const Color buttonColor = Color(0xFFFFD700);
  static const Color buttonTextColor = Colors.black;

  // Border & Divider
  static const Color borderColor = Colors.white24;

  // Other Colors
  static const Color error = Color(0xFFD32F2F);
  static const Color icon = Colors.white;

}
