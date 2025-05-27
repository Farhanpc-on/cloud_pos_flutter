import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeNotifier extends ChangeNotifier {

  int _themeMode = 1;

  AppThemeNotifier() {
    init();
  }

  init() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    int? data = sharedPreferences.getInt("themeMode");
    _themeMode = data ?? 1; // Use null-aware coalescing operator to provide a default value
    notifyListeners();
  }

  int themeMode() => _themeMode; // Added return type int

  Future<void> updateTheme(int themeMode) async {
    this._themeMode = themeMode;
    notifyListeners();

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setInt("themeMode", themeMode);
  }
}
