import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand Palette ──────────────────────────────────────────────────
  static const primary      = Color(0xFF1A237E); // Deep indigo
  static const primaryLight = Color(0xFF3949AB);
  static const accent       = Color(0xFF00BCD4); // Cyan
  static const accentLight  = Color(0xFF4DD0E1);
  static const success      = Color(0xFF00C853);
  static const warning      = Color(0xFFFF6F00);
  static const danger       = Color(0xFFD50000);
  static const surface      = Color(0xFFF8FAFF);
  static const cardBg       = Color(0xFFFFFFFF);
  static const textDark     = Color(0xFF0D1B4B);
  static const textMid      = Color(0xFF5C6BC0);
  static const textLight    = Color(0xFF9FA8DA);

  // Gradients
  static const gradientPrimary = LinearGradient(
    colors: [Color(0xFF1A237E), Color(0xFF3949AB), Color(0xFF00BCD4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientAccent = LinearGradient(
    colors: [Color(0xFF00BCD4), Color(0xFF26C6DA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientSuccess = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientWarning = LinearGradient(
    colors: [Color(0xFFFF6F00), Color(0xFFFFCA28)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientDanger = LinearGradient(
    colors: [Color(0xFFD50000), Color(0xFFFF5252)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Risk / severity colours
  static const riskLow      = Color(0xFF00C853);
  static const riskModerate = Color(0xFFFF6F00);
  static const riskHigh     = Color(0xFFD50000);

  static Color riskColor(String level) {
    switch (level.toLowerCase()) {
      case 'low':      return riskLow;
      case 'moderate': return riskModerate;
      case 'high':     return riskHigh;
      default:         return Colors.grey;
    }
  }

  static Color severityColor(String sev) {
    switch (sev.toLowerCase()) {
      case 'healthy':  return riskLow;
      case 'mild':     return const Color(0xFF64DD17);
      case 'moderate': return riskModerate;
      case 'severe':   return riskHigh;
      default:         return Colors.grey;
    }
  }

  static LinearGradient severityGradient(String sev) {
    switch (sev.toLowerCase()) {
      case 'healthy':  return gradientSuccess;
      case 'mild':     return const LinearGradient(
          colors: [Color(0xFF64DD17), Color(0xFFCCFF90)]);
      case 'moderate': return gradientWarning;
      case 'severe':   return gradientDanger;
      default:         return gradientPrimary;
    }
  }

  // ── Light Theme ────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = GoogleFonts.poppinsTextTheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary:   primary,
        secondary: accent,
        surface:   surface,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: surface,
      textTheme: base.apply(
        bodyColor:    textDark,
        displayColor: textDark,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE8EAF6), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE8EAF6), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: danger, width: 1.5),
        ),
        labelStyle: GoogleFonts.poppins(color: textMid, fontSize: 14),
        hintStyle:  GoogleFonts.poppins(color: textLight, fontSize: 14),
        prefixIconColor: textMid,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shadowColor: primary.withOpacity(0.15),
        indicatorColor: primary.withOpacity(0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w600, color: primary);
          }
          return GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w400, color: textLight);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 22);
          }
          return IconThemeData(color: textLight, size: 22);
        }),
      ),
    );
  }
}
