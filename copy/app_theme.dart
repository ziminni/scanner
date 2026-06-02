import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.primary);
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    );
  }

  static ThemeData systemAdmin(ThemeData base) {
    final textTheme = GoogleFonts.outfitTextTheme(
      base.textTheme,
    ).apply(bodyColor: AppColors.adminText, displayColor: AppColors.adminText);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.adminBackground,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.adminAccent,
        secondary: AppColors.adminAccent,
        surface: AppColors.adminSurface,
        onSurface: AppColors.adminText,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.adminSurface,
        foregroundColor: AppColors.adminText,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        shape: const Border(
          bottom: BorderSide(color: AppColors.adminBorder, width: 0.8),
        ),
        titleTextStyle: GoogleFonts.poppins(
          color: AppColors.adminText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.adminSurface,
        indicatorColor: AppColors.adminAccent.withValues(alpha: 0.12),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.adminSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: textTheme.copyWith(
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w400),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.adminAccent,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.adminAccent,
          side: BorderSide(
            color: AppColors.adminAccent.withValues(alpha: 0.55),
          ),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.adminAccent,
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: AppColors.adminSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.adminAccent.withValues(alpha: 0.22),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.adminAccent.withValues(alpha: 0.22),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.adminAccent,
            width: 1.5,
          ),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: GoogleFonts.outfit(
          color: AppColors.adminText,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        dataTextStyle: GoogleFonts.outfit(
          color: AppColors.adminText,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        headingRowColor: WidgetStatePropertyAll(
          AppColors.adminBackground,
        ),
        dividerThickness: 0.8,
        dataRowMinHeight: 56,
        dataRowMaxHeight: 76,
        headingRowHeight: 56,
        columnSpacing: 24,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.adminSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.poppins(
          color: AppColors.adminText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.adminAccent,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.adminText.withValues(alpha: 0.66),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.adminAccent),
      ),
    );
  }
}
