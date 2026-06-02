import 'package:flutter/material.dart';

import '../constants/colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: colorScheme.copyWith(
        primary: AppColors.primary,
        surface: Colors.white,
        secondary: colorScheme.secondary,
      ),
      scaffoldBackgroundColor: AppColors.mint,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.dark,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.dark),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFF3FAF6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textTheme: Typography.material2021().black.apply(
        bodyColor: AppColors.dark,
        displayColor: AppColors.dark,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.dark,
        selectedIconTheme: const IconThemeData(color: Colors.white),
        unselectedIconTheme: IconThemeData(color: AppColors.mint.withAlpha(204)),
        selectedLabelTextStyle: const TextStyle(color: Colors.white),
        unselectedLabelTextStyle: TextStyle(color: AppColors.mint.withAlpha(230)),
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.dark,
        indicatorColor: AppColors.primary.withAlpha(31),
        labelTextStyle: WidgetStateProperty.all(TextStyle(color: AppColors.mint)),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(Colors.transparent),
        dataRowColor: WidgetStateProperty.resolveWith((states) => Colors.white),
        headingTextStyle: TextStyle(
          color: AppColors.dark,
          fontWeight: FontWeight.w700,
        ),
        dataTextStyle: TextStyle(color: AppColors.dark.withAlpha(217)),
        dividerThickness: 1,
      ),
    );
  }

  static ThemeData admin(ThemeData base) {
    final textTheme = base.textTheme.apply(
      bodyColor: AppColors.adminText,
      displayColor: AppColors.adminText,
    );

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
        titleTextStyle: const TextStyle(
          color: AppColors.adminText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.adminSurface,
        indicatorColor: AppColors.adminAccent.withAlpha(31),
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
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
            color: AppColors.adminAccent.withAlpha(140),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            color: AppColors.adminAccent.withAlpha(56),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.adminAccent.withAlpha(56),
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
        headingTextStyle: const TextStyle(
          color: AppColors.adminText,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        dataTextStyle: const TextStyle(
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
        titleTextStyle: const TextStyle(
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
          color: AppColors.adminText.withAlpha(168),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.adminAccent),
      ),
    );
  }
}
