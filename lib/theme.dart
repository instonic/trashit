import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Distinct brand palettes for quick switching. The first (red)
/// is the original vibrant red theme.
enum AppThemeVariant { red, crimson, slate, ocean, violet, forest, sunset }

class FontSizes {
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 24.0;
  static const double headlineSmall = 22.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = 18.0;
  static const double titleSmall = 16.0;
  static const double labelLarge = 16.0;
  static const double labelMedium = 14.0;
  static const double labelSmall = 12.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
}

// Default red palette - the original vibrant theme
ThemeData get lightTheme => themeFor(AppThemeVariant.red, Brightness.light);
ThemeData get darkTheme => themeFor(AppThemeVariant.red, Brightness.dark);

ThemeData themeFor(AppThemeVariant variant, Brightness brightness) {
  final seed = _seedFor(variant);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
  );

  final textTheme = TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.normal,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.normal,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w600,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.normal,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w500,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w500,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w500,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w500,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w500,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.normal,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.normal,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.normal,
    ),
  ).apply(
    // Apply comprehensive font fallbacks for multilingual content  
    fontFamilyFallback: const [
      'Inter',
      'SF Pro Text', 
      'SF Pro Display',
      'Helvetica Neue',
      'Roboto',
      'Segoe UI',
      'Arial',
      'Noto Sans',
      'Noto Sans CJK SC',
      'Noto Sans CJK TC', 
      'Noto Sans CJK JP',
      'Noto Sans CJK KR',
      'Noto Sans Arabic',
      'Noto Sans Devanagari',
      'Noto Sans Thai',
      'Noto Sans Hebrew',
      'Noto Color Emoji',
      'Apple Color Emoji',
      'Segoe UI Emoji',
      'sans-serif',
    ],
  );

  // Component theming tuned to feel bold and consistent across palettes,
  // with special care for the original Red default.
  final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

  final filledButtonTheme = FilledButtonThemeData(
    style: ButtonStyle(
      shape: WidgetStateProperty.all<OutlinedBorder>(buttonShape),
      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
      textStyle: WidgetStateProperty.all(textTheme.labelLarge),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.primary.withValues(alpha: 0.5);
        }
        return scheme.primary;
      }),
      foregroundColor: WidgetStateProperty.all(scheme.onPrimary),
      overlayColor: WidgetStateProperty.all(scheme.onPrimary.withValues(alpha: 0.08)),
    ),
  );

  final elevatedButtonTheme = ElevatedButtonThemeData(
    style: ButtonStyle(
      shape: WidgetStateProperty.all<OutlinedBorder>(buttonShape),
      backgroundColor: WidgetStateProperty.all(scheme.primaryContainer),
      foregroundColor: WidgetStateProperty.all(scheme.onPrimaryContainer),
      textStyle: WidgetStateProperty.all(textTheme.labelLarge),
    ),
  );

  final outlinedButtonTheme = OutlinedButtonThemeData(
    style: ButtonStyle(
      shape: WidgetStateProperty.all<OutlinedBorder>(buttonShape),
      side: WidgetStateProperty.all(BorderSide(color: scheme.outline)),
      foregroundColor: WidgetStateProperty.all(scheme.primary),
      overlayColor: WidgetStateProperty.all(scheme.primary.withValues(alpha: 0.08)),
      textStyle: WidgetStateProperty.all(textTheme.labelLarge),
    ),
  );

  final textButtonTheme = TextButtonThemeData(
    style: ButtonStyle(
      shape: WidgetStateProperty.all<OutlinedBorder>(buttonShape),
      foregroundColor: WidgetStateProperty.all(scheme.primary),
      overlayColor: WidgetStateProperty.all(scheme.primary.withValues(alpha: 0.08)),
      textStyle: WidgetStateProperty.all(textTheme.labelLarge),
    ),
  );

  final chipTheme = ChipThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    side: BorderSide(color: scheme.outline.withValues(alpha: 0.2)),
    backgroundColor: scheme.surfaceContainerHighest,
    labelStyle: textTheme.labelSmall,
    iconTheme: IconThemeData(color: scheme.primary),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  );

  final inputTheme = InputDecorationTheme(
    filled: true,
    fillColor: scheme.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: scheme.primary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );

  final snackTheme = SnackBarThemeData(
    backgroundColor: scheme.inverseSurface,
    contentTextStyle: textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface),
    actionTextColor: scheme.primary,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  final fabTheme = FloatingActionButtonThemeData(
    backgroundColor: _seedFor(variant), // Use exact brand color for FAB
    foregroundColor: Colors.white,
    shape: buttonShape,
  );

  final dividerTheme = DividerThemeData(
    color: scheme.outlineVariant,
    thickness: 1,
  );

  final iconButtonTheme = IconButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.all(scheme.onSurface),
      overlayColor: WidgetStateProperty.all(scheme.primary.withValues(alpha: 0.08)),
      shape: WidgetStateProperty.all(buttonShape),
    ),
  );

  final switchTheme = SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return scheme.outline;
      if (states.contains(WidgetState.selected)) return scheme.primary;
      return scheme.outline;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return scheme.outline.withValues(alpha: 0.2);
      if (states.contains(WidgetState.selected)) return scheme.primary.withValues(alpha: 0.5);
      return scheme.outline.withValues(alpha: 0.3);
    }),
  );

  // For the original RED theme, force pure white/neutral surfaces to eliminate pink tints
  final adjustedScheme = (variant == AppThemeVariant.red && brightness == Brightness.light)
      ? scheme.copyWith(
          surface: Colors.white,
          background: Colors.white,
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: const Color(0xFFFCFCFC),
          surfaceContainer: const Color(0xFFF8F9FA),
          surfaceContainerHigh: const Color(0xFFF1F3F4),
          surfaceContainerHighest: const Color(0xFFE8EAED),
          primaryContainer: const Color(0xFFFFEBEE),
          onPrimaryContainer: const Color(0xFFB71C1C),
        )
      : (variant == AppThemeVariant.red && brightness == Brightness.dark)
          ? scheme.copyWith(
              surface: const Color(0xFF121212),
              background: const Color(0xFF121212),
              surfaceContainerLowest: const Color(0xFF0F0F0F),
              surfaceContainerLow: const Color(0xFF1A1A1A),
              surfaceContainer: const Color(0xFF1E1E1E),
              surfaceContainerHigh: const Color(0xFF232323),
              surfaceContainerHighest: const Color(0xFF2C2C2C),
            )
          : scheme;

  return ThemeData(
    useMaterial3: true,
    colorScheme: adjustedScheme,
    brightness: brightness,
    appBarTheme: AppBarTheme(
      // Preserve original brand hue on AppBar in both light and dark
      backgroundColor: _seedFor(variant),
      foregroundColor: scheme.onPrimary,
      elevation: 0,
    ),
    textTheme: textTheme,

    // Opinionated components (restore the impressive, high-contrast feel)
    cardTheme: const CardThemeData(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: scheme.surfaceTint,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: scheme.onSurface,
      indicatorColor: scheme.primary,
    ),

    filledButtonTheme: filledButtonTheme,
    elevatedButtonTheme: elevatedButtonTheme,
    outlinedButtonTheme: outlinedButtonTheme,
    textButtonTheme: textButtonTheme,
    chipTheme: chipTheme,
    inputDecorationTheme: inputTheme,
    snackBarTheme: snackTheme,
    floatingActionButtonTheme: fabTheme,
    dividerTheme: dividerTheme,
    iconButtonTheme: iconButtonTheme,
    switchTheme: switchTheme,
  );
}

Color _seedFor(AppThemeVariant variant) {
  switch (variant) {
    case AppThemeVariant.red:
      return const Color(0xFFDC2626); // Original vibrant red
    case AppThemeVariant.crimson:
      return const Color(0xFFE53E3E);
    case AppThemeVariant.slate:
      return const Color(0xFF64748B); // slate
    case AppThemeVariant.ocean:
      return const Color(0xFF0EA5E9); // sky
    case AppThemeVariant.violet:
      return const Color(0xFF7C3AED); // violet
    case AppThemeVariant.forest:
      return const Color(0xFF10B981); // emerald
    case AppThemeVariant.sunset:
      return const Color(0xFFF97316); // orange
  }
}
