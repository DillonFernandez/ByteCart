import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color kMainColour = Color(0xFF0479FF);

const String _kThemePrefKey = 'app_theme_mode';
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(
  ThemeMode.system,
);

Future<void> loadSavedThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final idx = prefs.getInt(_kThemePrefKey);
  if (idx != null && idx >= 0 && idx < ThemeMode.values.length) {
    themeModeNotifier.value = ThemeMode.values[idx];
  }
}

Future<void> setAppThemeMode(ThemeMode mode) async {
  themeModeNotifier.value = mode;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_kThemePrefKey, mode.index);
}

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kMainColour,
    brightness: Brightness.light,
  ).copyWith(background: Colors.white),
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    elevation: 0,
    backgroundColor: Colors.transparent,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(color: kMainColour),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kMainColour,
    brightness: Brightness.dark,
  ).copyWith(background: Colors.black),
  scaffoldBackgroundColor: Colors.black,
  appBarTheme: const AppBarTheme(
    elevation: 0,
    backgroundColor: Colors.transparent,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(color: kMainColour),
);
