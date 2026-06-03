import 'package:flutter/material.dart';

class ScannerTheme {
  const ScannerTheme._();

  static const background = Color(0xFFF1FAF3);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFE5F6EA);
  static const border = Color(0xFFB8DEC4);
  static const primary = Color(0xFF2E7D4F);
  static const primarySoft = Color(0xFFCFEFDA);
  static const text = Color(0xFF173C28);

  static BoxDecoration panelDecoration({Color color = surface}) {
    return BoxDecoration(
      color: color,
      border: Border.all(color: border),
      borderRadius: BorderRadius.circular(8),
    );
  }
}
