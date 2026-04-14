import 'package:flutter/material.dart';

ThemeData darkMode = ThemeData(
  colorScheme: ColorScheme.dark(
    surface: Color.fromARGB(255, 24, 24, 24),
    primary: Color.fromARGB(0, 0, 0, 0),
    onPrimary: Color.fromARGB(57, 255, 255, 255),
    //secondary: const Color.fromARGB(255, 58, 58, 58),
    secondary: const Color.fromARGB(255, 36, 36, 36),
    tertiary: Colors.grey.shade800,
    inversePrimary: Colors.grey.shade300,
    onSurfaceVariant: Color.fromARGB(255, 81, 181, 21),
  ),
);
