import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Main app colour
const Color kMainColour = Color(0xFF0479FF);

// Light/Dark themes with requested backgrounds
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
      statusBarIconBrightness:
          Brightness.dark, // Android: dark icons on light bg
      statusBarBrightness: Brightness.light, // iOS: dark icons on light bg
    ),
  ),
  // Added: themed progress indicators
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
      statusBarIconBrightness:
          Brightness.light, // Android: light icons on dark bg
      statusBarBrightness: Brightness.dark, // iOS: light icons on dark bg
    ),
  ),
  // Added: themed progress indicators
  progressIndicatorTheme: const ProgressIndicatorThemeData(color: kMainColour),
);
