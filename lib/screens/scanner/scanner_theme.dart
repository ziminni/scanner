import 'package:flutter/material.dart';

class ScannerTheme {
  const ScannerTheme._();

  static const background = Color(0xFFF4FBF6);
  static const backgroundAccent = Color(0xFFE8F6ED);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFEAF7EE);
  static const border = Color(0xFFD1E7D8);
  static const primary = Color(0xFF176B43);
  static const primarySoft = Color(0xFFDDF2E5);
  static const primaryDeep = Color(0xFF0E4F31);
  static const text = Color(0xFF123822);
  static const mutedText = Color(0xFF5A705F);

  static BoxDecoration panelDecoration({Color color = surface}) {
    return BoxDecoration(
      color: color,
      border: Border.all(color: border),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0B3D24).withAlpha(13),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }

  static BoxDecoration heroDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryDeep, primary],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: primary.withAlpha(38),
          blurRadius: 28,
          offset: const Offset(0, 16),
        ),
      ],
    );
  }
}
