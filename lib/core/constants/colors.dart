import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();
  // Primary brand color (kept for backward compat)
  static const primary = Color(0xFF03913F);

  // Legacy green tones (kept for places that still reference them)
  static const mint = Color(0xFFEFF8F4);
  static const dark = Color(0xFF092916);

  // Status colors
  static const warn = Color(0xFFF6A623);
  static const success = Color(0xFF03913F);

  // Admin / sidebar palette (new design)
  static const adminPrimary = Color(0xFF026B2F);
  static const adminAccent = Color(0xFF03913F);
  static const adminText = Color(0xFF092916);
  static const adminSurface = Color(0xFFFFFFFF);
  static const adminBackground = Color(0xFFF5FAF7);
  static const adminSidebar = Color.fromARGB(255, 5, 75, 55);
  static const adminSidebarActive = Color.fromARGB(255, 32, 107, 63);
  static const adminSidebarMuted = Color(0xFF4A8D67);
  static const adminBorder = Color(0xFFD3EDE0);
}
