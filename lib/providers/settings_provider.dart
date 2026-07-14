import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/gemini_service.dart';

class SettingsProvider with ChangeNotifier {
  String? _apiKey;
  bool _isDarkMode = true;

  String? get apiKey => _apiKey;
  bool get isDarkMode => _isDarkMode;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('gemini_api_key');
    _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
    notifyListeners();
  }

  Future<bool> setApiKey(String key) async {
    final isValid = await GeminiService.validateKey(key);
    if (isValid) {
      _apiKey = key;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gemini_api_key', key);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> setFreeMode() async {
    _apiKey = 'free';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', 'free');
    notifyListeners();
  }

  Future<void> clearApiKey() async {
    _apiKey = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('gemini_api_key');
    notifyListeners();
  }

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    notifyListeners();
  }
}
