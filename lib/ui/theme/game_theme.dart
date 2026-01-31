import 'package:flutter/material.dart';

/// Game color palette - dark, gritty zombie apocalypse aesthetic
class GameColors {
  // Primary colors
  static const background = Color(0xFF0D0D0D);
  static const surface = Color(0xFF1A1A1A);
  static const surfaceLight = Color(0xFF2A2A2A);
  static const card = Color(0xFF1E1E1E);
  
  // Text colors
  static const textPrimary = Color(0xFFE8E8E8);
  static const textSecondary = Color(0xFF9E9E9E);
  static const textMuted = Color(0xFF666666);
  
  // Accent colors
  static const danger = Color(0xFFD32F2F);
  static const dangerDark = Color(0xFF8B1E1E);
  static const warning = Color(0xFFE65100);
  static const success = Color(0xFF2E7D32);
  static const info = Color(0xFF1565C0);
  
  // Stat colors
  static const hp = Color(0xFFB71C1C);
  static const hunger = Color(0xFFE65100);
  static const thirst = Color(0xFF0277BD);
  static const fatigue = Color(0xFF6A1B9A);
  static const infection = Color(0xFF1B5E20);
  static const stress = Color(0xFF4A148C);
  static const morale = Color(0xFF00897B);
  static const noise = Color(0xFFFF8F00);
  static const smell = Color(0xFF6D4C41);
  static const hope = Color(0xFF2E7D32);
  static const signalHeat = Color(0xFFD32F2F);
  
  // Special colors
  static const gold = Color(0xFFFFB300);
  static const zombie = Color(0xFF4E342E);
  static const blood = Color(0xFF6D0000);
  static const rust = Color(0xFF5D4037);
  
  // Rarity colors
  static const common = Color(0xFF757575);
  static const uncommon = Color(0xFF43A047);
  static const rare = Color(0xFF1976D2);
  static const epic = Color(0xFF7B1FA2);
  static const legendary = Color(0xFFFF8F00);
}

/// Game typography using a gritty, survivalist font
class GameTypography {
  static const String fontFamily = 'Roboto Condensed';
  static const String fontFamilyMono = 'Roboto Mono';
  
  static const heading1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: GameColors.textPrimary,
    letterSpacing: 0.5,
  );
  
  static const heading2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: GameColors.textPrimary,
  );
  
  static const heading3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: GameColors.textPrimary,
  );
  
  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: GameColors.textPrimary,
    height: 1.5,
  );
  
  static const bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: GameColors.textSecondary,
  );
  
  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: GameColors.textMuted,
  );
  
  static const button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  
  static const stat = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: GameColors.textPrimary,
  );
  
  static const logEntry = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: GameColors.textPrimary,
    height: 1.6,
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
