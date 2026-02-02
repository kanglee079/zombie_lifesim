import 'package:flutter/material.dart';

/// Game color palette - dark, gritty zombie apocalypse aesthetic
class GameColors {
  // Primary colors
  static const background = Color(0xFF0A0A0A);
  static const surface = Color(0xFF141414);
  static const surfaceLight = Color(0xFF1E1E1E);
  static const surfaceLighter = Color(0xFF282828);
  static const card = Color(0xFF181818);
  static const cardElevated = Color(0xFF1C1C1C);

  // Text colors (WCAG AA compliant on dark backgrounds)
  static const textPrimary = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFFB8B8B8);
  static const textMuted =
      Color(0xFF8A8A8A); // Improved contrast (was 0x707070)
  static const textDim = Color(0xFF6A6A6A); // Improved contrast (was 0x505050)

  // Accent colors
  static const danger = Color(0xFFEF4444);
  static const dangerDark = Color(0xFF991B1B);
  static const dangerLight = Color(0xFFFCA5A5);
  static const warning = Color(0xFFF97316);
  static const warningLight = Color(0xFFFDBA74);
  static const success = Color(0xFF22C55E);
  static const successLight = Color(0xFF86EFAC);
  static const info = Color(0xFF3B82F6);
  static const infoLight = Color(0xFF93C5FD);

  // Stat colors - more vibrant
  static const hp = Color(0xFFEF4444);
  static const hpGlow = Color(0x40EF4444);
  static const hunger = Color(0xFFF97316);
  static const hungerGlow = Color(0x40F97316);
  static const thirst = Color(0xFF0EA5E9);
  static const thirstGlow = Color(0x400EA5E9);
  static const fatigue = Color(0xFFA855F7);
  static const fatigueGlow = Color(0x40A855F7);
  static const infection = Color(0xFF84CC16);
  static const infectionGlow = Color(0x4084CC16);
  static const stress = Color(0xFF8B5CF6);
  static const stressGlow = Color(0x408B5CF6);
  static const morale = Color(0xFF14B8A6);
  static const moraleGlow = Color(0x4014B8A6);
  static const noise = Color(0xFFFBBF24);
  static const noiseGlow = Color(0x40FBBF24);
  static const smell = Color(0xFF78716C);
  static const smellGlow = Color(0x4078716C);
  static const hope = Color(0xFF10B981);
  static const hopeGlow = Color(0x4010B981);
  static const signalHeat = Color(0xFFF43F5E);
  static const signalHeatGlow = Color(0x40F43F5E);

  // Special colors
  static const gold = Color(0xFFFBBF24);
  static const goldGlow = Color(0x40FBBF24);
  static const zombie = Color(0xFF4E342E);
  static const blood = Color(0xFF7F1D1D);
  static const rust = Color(0xFF78350F);

  // Rarity colors
  static const common = Color(0xFF9CA3AF);
  static const uncommon = Color(0xFF22C55E);
  static const rare = Color(0xFF3B82F6);
  static const epic = Color(0xFFA855F7);
  static const legendary = Color(0xFFF59E0B);

  // Gradient presets
  static const dangerGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const warningGradient = LinearGradient(
    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const successGradient = LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const infoGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const surfaceGradient = LinearGradient(
    colors: [Color(0xFF1E1E1E), Color(0xFF141414)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

/// Game typography - App Store compliant (minimum 11pt)
/// Using system fonts for best readability and emoji support
class GameTypography {
  static const String? fontFamily = null; // System default
  static const String? fontFamilyMono = null; // System default mono

  // Headings
  static const heading1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: GameColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const heading2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    color: GameColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const heading3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: GameColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const heading4 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: GameColors.textPrimary,
  );

  // Body text - main readable content
  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: GameColors.textPrimary,
    height: 1.5,
  );

  static const bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: GameColors.textPrimary,
    height: 1.5,
  );

  static const bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: GameColors.textSecondary,
    height: 1.4,
  );

  // Captions and labels - minimum 12pt for accessibility
  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: GameColors.textMuted,
    height: 1.3,
  );

  static const captionBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: GameColors.textMuted,
  );

  // Small text - minimum 11pt for App Store
  static const small = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: GameColors.textMuted,
    letterSpacing: 0.3,
  );

  static const tiny = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: GameColors.textMuted,
    letterSpacing: 0.4,
  );

  // Buttons
  static const button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static const buttonSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  // Stats and numbers
  static const stat = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: GameColors.textPrimary,
  );

  static const statLarge = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: GameColors.textPrimary,
  );

  // Log entries - optimized for readability
  static const logEntry = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: GameColors.textPrimary,
    height: 1.45,
  );

  static const logEntryBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: GameColors.textPrimary,
    height: 1.45,
  );

  // Labels
  static const label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: GameColors.textSecondary,
    letterSpacing: 0.5,
  );

  static const labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: GameColors.textSecondary,
    letterSpacing: 0.3,
  );
}

/// Decoration presets for consistent styling
class GameDecorations {
  static BoxDecoration card({Color? color, Color? borderColor}) =>
      BoxDecoration(
        color: color ?? GameColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? GameColors.surfaceLight.withOpacity(0.5),
          width: 1,
        ),
      );

  static BoxDecoration cardElevated({Color? color}) => BoxDecoration(
        color: color ?? GameColors.cardElevated,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration chip({required Color color}) => BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      );

  static BoxDecoration glowingBorder({required Color color}) => BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      );
}

/// Create the game theme
ThemeData createGameTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: GameColors.background,
    primaryColor: GameColors.danger,
    colorScheme: const ColorScheme.dark(
      primary: GameColors.danger,
      secondary: GameColors.warning,
      surface: GameColors.surface,
      error: GameColors.danger,
      onPrimary: GameColors.textPrimary,
      onSecondary: GameColors.textPrimary,
      onSurface: GameColors.textPrimary,
      onError: GameColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: GameColors.surface,
      foregroundColor: GameColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GameTypography.heading3,
    ),
    cardTheme: const CardThemeData(
      color: GameColors.card,
      elevation: 4,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: GameColors.surface,
      selectedItemColor: GameColors.danger,
      unselectedItemColor: GameColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: GameColors.danger,
        foregroundColor: GameColors.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GameTypography.button,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: GameColors.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        side: const BorderSide(color: GameColors.textMuted),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GameTypography.button,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: GameColors.danger,
        textStyle: GameTypography.button,
      ),
    ),
    iconTheme: const IconThemeData(
      color: GameColors.textSecondary,
      size: 24,
    ),
    dividerTheme: const DividerThemeData(
      color: GameColors.surfaceLight,
      thickness: 1,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: GameColors.danger,
      linearTrackColor: GameColors.surfaceLight,
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: GameColors.danger,
      inactiveTrackColor: GameColors.surfaceLight,
      thumbColor: GameColors.danger,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: GameColors.surfaceLight,
      contentTextStyle: GameTypography.body,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: GameColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
  );
}

/// Extension for rarity colors
extension RarityColor on String {
  Color get rarityColor {
    switch (toLowerCase()) {
      case 'common':
        return GameColors.common;
      case 'uncommon':
        return GameColors.uncommon;
      case 'rare':
        return GameColors.rare;
      case 'epic':
        return GameColors.epic;
      case 'legendary':
        return GameColors.legendary;
      default:
        return GameColors.common;
    }
  }
}

/// Spacing system for consistent layouts
class GameSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Touch target sizes (minimum 48px for accessibility)
class GameSizes {
  static const double minTouchTarget = 48;
  static const double iconButtonSize = 48;
  static const double chipHeight = 36;
  static const double buttonHeight = 48;
  static const double cardRadius = 16;
  static const double chipRadius = 12;
  static const double buttonRadius = 12;
}
