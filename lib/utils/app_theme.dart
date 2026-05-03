import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────
//  AppColors — exact match to website CSS variables
//
//  --red:#C8102E       --red-dark:#9B0B22   --red-light:#FEF1F3
//  --bg:#F2F5FA        --bg3:#F7F9FC        --surface:#FFFFFF
//  --text:#18213A      --text2:#566080      --text3:#9BA3BC
//  --border:#DDE2EF    --border2:#EBF0F8
// ─────────────────────────────────────────────────────────────

class AppColors {
  // ── Primary ───────────────────────────────────────────────
  static const Color primary      = Color(0xFFC8102E); // --red
  static const Color primaryDark  = Color(0xFF9B0B22); // --red-dark
  static const Color primaryLight = Color(0xFFFEF1F3); // --red-light

  // ── Backgrounds ───────────────────────────────────────────
  static const Color background   = Color(0xFFF2F5FA); // --bg
  static const Color background3  = Color(0xFFF7F9FC); // --bg3
  static const Color surface      = Color(0xFFFFFFFF); // --surface

  // ── Text ──────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF18213A); // --text  (navy)
  static const Color textSecondary = Color(0xFF566080); // --text2
  static const Color textMuted     = Color(0xFF9BA3BC); // --text3
  static const Color textVeryMuted = Color(0xFFB8C0D4);

  // ── Borders ───────────────────────────────────────────────
  static const Color border     = Color(0xFFDDE2EF); // --border
  static const Color borderSoft = Color(0xFFEBF0F8); // --border2

  // ── Bottom Nav (Option B — Deep Navy) ─────────────────────
  static const Color navBg          = Color(0xFF18213A); // website --text
  static const Color navActiveIcon  = Color(0xFFC8102E); // website --red
  static const Color navActiveLabel = Color(0xFFC8102E);
  static const Color navInactive    = Color(0xFF9BA3BC); // website --text3 at ~50%

  // ── Semantic urgency ──────────────────────────────────────
  static const Color urgentBg     = Color(0xFFFEF1F3);
  static const Color urgentText   = Color(0xFF9B0B22);
  static const Color urgentAccent = Color(0xFFF0997B);
  static const Color urgentBorder = Color(0xFFF5C4B3);

  static const Color moderateBg     = Color(0xFFFAEEDA);
  static const Color moderateText   = Color(0xFF633806);
  static const Color moderateAccent = Color(0xFFEF9F27);
  static const Color moderateBorder = Color(0xFFFAC775);

  static const Color plannedBg     = Color(0xFFE6F1FB);
  static const Color plannedText   = Color(0xFF0C447C);
  static const Color plannedAccent = Color(0xFF85B7EB);
  static const Color plannedBorder = Color(0xFFB5D4F4);

  static const Color closedBg     = Color(0xFFF1EFE8);
  static const Color closedText   = Color(0xFF5F5E5A);
  static const Color closedAccent = Color(0xFFB4B2A9);
  static const Color closedBorder = Color(0xFFD3D1C7);

  static const Color secondary      = Color(0xFF1D9E75);
  static const Color secondaryLight = Color(0xFFE1F5EE);
  static const Color linkColor      = Color(0xFF378ADD);
}

// ─────────────────────────────────────────────────────────────
//  Font helpers — website 3-font system
//
//  --font-display : Cormorant Garamond  → screen titles / brand
//  --font-ui      : Syne                → labels, buttons, caps
//  --font-body    : DM Sans             → body copy
// ─────────────────────────────────────────────────────────────

class AppFonts {
  static TextStyle display({
    double fontSize = 28,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.textPrimary,
    double letterSpacing = 0.01,
  }) =>
      GoogleFonts.cormorantGaramond(
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle ui({
    double fontSize = 12,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.textSecondary,
    double letterSpacing = 0.05,
    TextDecoration? decoration,
  }) =>
      GoogleFonts.syne(
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        decoration: decoration,
      );

  static TextStyle body({
    double fontSize = 13,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? height,
  }) =>
      GoogleFonts.dmSans(
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        height: height,
      );
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        surface: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.dmSansTextTheme().copyWith(
        displayLarge: GoogleFonts.cormorantGaramond(
            fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        displayMedium: GoogleFonts.cormorantGaramond(
            fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleLarge: GoogleFonts.syne(
            fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        titleMedium: GoogleFonts.syne(
            fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        titleSmall: GoogleFonts.syne(
            fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        bodyLarge: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
        bodyMedium: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary),
        bodySmall: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary),
        labelLarge: GoogleFonts.syne(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: AppColors.textSecondary, letterSpacing: 0.05),
        labelSmall: GoogleFonts.syne(
            fontSize: 10, fontWeight: FontWeight.w700,
            color: AppColors.textMuted, letterSpacing: 0.08),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.navBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navInactive),
        titleTextStyle: GoogleFonts.syne(
            fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}