import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ══════════════════════════════════════════════════════
//  APP THEME
// ══════════════════════════════════════════════════════
class AppTheme {
  final bool isDark;
  const AppTheme({required this.isDark});

  // ── Primary (ثابت) ──
  static const Color primary      = Color(0xFF00D5BE);
  static const Color primaryDark  = Color(0xFF17B4C9);
  static const Color primaryLight = Color(0xFFDFFAF6);

  // ── Backgrounds ──
  Color get bg       => isDark ? const Color(0xFF0D1F2D) : const Color(0xFFF9FBFC);
  Color get card     => isDark ? const Color(0xFF152232) : Colors.white;
  Color get cardDeep => isDark ? const Color(0xFF0F1E2E) : const Color(0xFFF0F4F8);
  Color get fieldBg  => isDark ? const Color(0xFF112640) : Colors.white;
  Color get border   => isDark ? const Color(0xFF1A3550) : const Color(0xFFE6EAF0);

  // ── Text ──
  Color get textPrimary => isDark ? const Color(0xFFE8F0F8) : const Color(0xFF222222);
  Color get textMuted   => isDark ? const Color(0xFF5F7E97) : const Color(0xFF7A7A7A);
  Color get textSub     => isDark ? const Color(0xFF4A6572) : const Color(0xFF9BAAB8);

  // ── Specific screens ──
  Color get loginBg  => isDark ? const Color(0xFF0B1E2D) : const Color(0xFFF9FBFC);
  Color get selectBg => isDark ? const Color(0xFF0F2334) : const Color(0xFFF9FBFC);
  Color get regBg    => isDark ? const Color(0xFF001A2C) : const Color(0xFFF9FBFC);
  Color get mapCard  => isDark ? const Color(0xFF0A1628) : const Color(0xFFEAFBFF);

  // ── Shadows ──
  List<BoxShadow> get cardShadow => isDark
      ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12)]
      : [BoxShadow(color: const Color(0x1A979797), blurRadius: 14,
          offset: const Offset(0, 6))];

  // ── Gradient button decoration ──
  BoxDecoration get gradientBtn => BoxDecoration(
    gradient: const LinearGradient(
      colors: [primary, primaryDark],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    borderRadius: BorderRadius.circular(14),
    boxShadow: [BoxShadow(
      color: primary.withOpacity(0.25),
      blurRadius: 18, offset: const Offset(0, 8))],
  );

  // ── Flutter ThemeData ──
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primary,
    scaffoldBackgroundColor: const Color(0xFF0D1F2D),
    colorScheme: const ColorScheme.dark(primary: primary),
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primary,
    scaffoldBackgroundColor: const Color(0xFFF9FBFC),
    colorScheme: const ColorScheme.light(primary: primary),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      hintStyle: const TextStyle(color: Color(0xFFB9C0CA), fontSize: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE6EAF0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primary, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: Color(0xFFE6EAF0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        foregroundColor: const Color(0xFF222222),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════
//  THEME PROVIDER
// ══════════════════════════════════════════════════════
class ThemeProvider extends ChangeNotifier {
  bool _isDark = true;

  bool get isDark => _isDark;
  AppTheme get theme => AppTheme(isDark: _isDark);

  ThemeProvider() { _loadTheme(); }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('isDarkMode') ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDark);
  }
}