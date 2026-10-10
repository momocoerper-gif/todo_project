
import 'package:flutter/material.dart';

// --------------------------------------------------
// ZENTRALE FARBPALETTEN
// --------------------------------------------------

class AppColors {
  // LIGHT MODE
  static const lightBackground = Color(0xFFF9F0D9);
  static const lightSurface = Color(0xFFFFF9EB);
  static const lightPrimary = Color(0xFF77945A);
  static const lightText = Color(0xFF4B382C);
  static const lightBorder = Color(0xFFB88656);
  static const lightError = Color(0xFFB74439);

  // DARK MODE
  static const darkBackground = Color(0xFF171D35);
  static const darkSurface = Color(0xFF303453);
  static const darkPrimary = Color(0xFFB7A0E3);
  static const darkText = Color(0xFFF2E6D8);
  static const darkBorder = Color(0xFF665B92);
  static const darkError = Color(0xFFFF8982);
}

// --------------------------------------------------
// GLOBALES APP-THEME
// --------------------------------------------------

class AppTheme {
  static final ThemeData lightTheme = _buildTheme(
    brightness: Brightness.light,
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    primary: AppColors.lightPrimary,
    text: AppColors.lightText,
    border: AppColors.lightBorder,
    error: AppColors.lightError,
  );

  static final ThemeData darkTheme = _buildTheme(
    brightness: Brightness.dark,
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    primary: AppColors.darkPrimary,
    text: AppColors.darkText,
    border: AppColors.darkBorder,
    error: AppColors.darkError,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color primary,
    required Color text,
    required Color border,
    required Color error,
  }) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      onPrimary: isDark ? AppColors.darkBackground : Colors.white,
      surface: surface,
      onSurface: text,
      surfaceContainerLow: surface,
      surfaceContainer: background,
      outline: border,
      outlineVariant: border,
      error: error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,

      // Allgemeiner Hintergrund
      scaffoldBackgroundColor: background,

      // Obere AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: colorScheme.onPrimary,
        centerTitle: true,
        elevation: 0,
      ),

      // Sidebar
      drawerTheme: DrawerThemeData(
        backgroundColor: background,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
      ),

      // Sidebar-Einträge
      listTileTheme: ListTileThemeData(
        iconColor: primary,
        textColor: text,
        selectedColor: primary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
        ),
      ),

      // Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Filled Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Floating Action Button (+)
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: colorScheme.onPrimary,
      ),

      // Textfelder
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: primary,
            width: 2,
          ),
        ),
      ),

      // Dialogfenster
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border),
        ),
      ),

      // Checkboxen
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return null;
        }),
        checkColor: WidgetStatePropertyAll(
          colorScheme.onPrimary,
        ),
      ),

      // Trennlinien
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
      ),

      // Allgemeines Kartendesign
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
      ),

      // Standard-Textfarben
      textTheme: ThemeData(
        brightness: brightness,
      ).textTheme.apply(
        bodyColor: text,
        displayColor: text,
      ),
    );
  }
}

// --------------------------------------------------
// DESIGN DER TO-DO-BLÖCKE
// --------------------------------------------------

class TodoTileStyle {
  // Formen
  static const double borderRadius = 10;
  static const double borderWidth = 2;

  // Abstände
  static const double horizontalPadding = 16;
  static const double verticalPadding = 10;
  static const double spacing = 10;

  // Schriftgrößen
  static const double titleFontSize = 17;
  static const double dateFontSize = 13;
  static const double descriptionFontSize = 14;

  // Hintergrund
  static Color backgroundColor(BuildContext context) {
    return Theme.of(context).colorScheme.surfaceContainerLow;
  }

  // Rahmen
  static Color borderColor(BuildContext context) {
    return Theme.of(context).colorScheme.outlineVariant;
  }

  // Titel
  static Color titleColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  // Überfällige Aufgaben
  static Color overdueColor(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }

  // Beschreibung
  static Color descriptionColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}
