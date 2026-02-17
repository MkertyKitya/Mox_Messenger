import 'package:mox_beta/themes/light_mode.dart';
import 'package:flutter/material.dart';
import 'dark_mode.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData = darkMode;

  ThemeData get themeData => _themeData;

  bool get isLightMode => _themeData == lightMode;

  set themeData(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeData == darkMode) {
      themeData = lightMode;
    } else {
      themeData = darkMode;
    }
  }
}
