import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  bool _isDarkMode = true;
  String? _selectedModel;

  bool get isDarkMode => _isDarkMode;

  String get selectedModel {
    return _selectedModel ?? 'big-pickle';
  }

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
      _selectedModel = prefs.getString('selected_model') ?? 'big-pickle';
    } catch (e, stackTrace) {
      debugPrint('Error loading settings from SharedPreferences: $e\n$stackTrace');
    }
    notifyListeners();
  }

  Future<void> setSelectedModel(String model) async {
    _selectedModel = model;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_model', model);
    notifyListeners();
  }

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    notifyListeners();
  }
}
