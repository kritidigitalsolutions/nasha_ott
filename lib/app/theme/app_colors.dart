import 'package:flutter/material.dart';

class AppColors {

  // Primary Colors (Golden)
  static const Color primary = Color(0xFFC29B47);
  static const Color secondary = Color(0xFFB8860B);


  static const Color goldShadow = Color(0xFF4A3010);
  static const Color goldMid = Color(0xFF8A6529);
  static const Color goldBase = Color(0xFFC29B47);
  static const Color goldHighlight = Color(0xFFEAD28B);
  static const Color goldGlint = Color(0xFFFFF3D1);


  // Golden Gradient Colors
  static const Color goldDark = Color(0xFF5A3F12);
  // static const Color goldBase = Color(0xFFB88728);
  static const Color goldLight = Color(0xFFFCEFA2);


  static const LinearGradient goldenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      // goldShadow,    // गहरा कोना साया
      goldMid,       // मिड-टोन ट्रांज़िशन
      goldBase,      // असली रिच गोल्ड बॉडी
      // goldHighlight, // सबसे ब्राइट पॉइंट (यह पूरी तरह गोल्ड है, वाइट नहीं)
      // goldBase,      // वापस असली गोल्ड पर
      // goldShadow,    // आखिरी कोना साया
    ],
    // स्टॉप्स को एडजस्ट किया है ताकि बीच में स्मूथ रिच गोल्ड शेड मिले
    stops: [
      0.0,  // goldShadow
      0.2,  // goldMid
      // 0.45, // goldBase
      // 0.55, // goldHighlight (यहाँ अब कोई वाइटिश शेड नहीं है)
      // 0.75, // goldBase
      // 1.0,  // goldShadow
    ],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      goldShadow,    // Deep left shadow edge
      goldMid,       // Rich transition
      goldBase,      // Main metallic body
      // goldHighlight, // Chiseled light stripe
      // goldGlint,     // Pure metallic shine
      goldBase,      // Returning to main gold
      goldShadow,    // Deep right shadow edge
    ],
    // Tightened stops to keep the reflection sharp across a wide button
    stops: [
      0.0,
      0.15,
      0.35,
      // 0.48,
      // 0.0,
      0.70,
      1.0,
    ],
  );

  // static const LinearGradient goldenGradient = LinearGradient(
  //   colors: [
  //     goldDark, // Dark Shadow
  //     goldBase, // Base Gold
  //     secondary, // Bright Highlight
  //     goldBase, // Base Gold
  //     goldDark, // Dark Shadow
  //   ],
  //   begin: Alignment.topCenter,
  //   end: Alignment.bottomCenter,
  // );

  // static const LinearGradient buttonGradient = LinearGradient(
  //   colors: [
  //     goldDark, // Dark Shadow
  //     goldBase, // Base Gold
  //     secondary, // Bright Highlight
  //     goldBase, // Base Gold
  //     goldDark, // Dark Shadow
  //   ],
  //   begin: Alignment.topCenter,
  //   end: Alignment.bottomCenter,
  // );

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
