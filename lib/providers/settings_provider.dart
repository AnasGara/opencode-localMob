import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/gemini_service.dart';

class SettingsProvider with ChangeNotifier {
  String? _apiKey;
  bool _isDarkMode = true;
  String? _selectedModel;

  String? get apiKey => _apiKey;
  bool get isDarkMode => _isDarkMode;

  String get selectedModel {
    if (_selectedModel != null) return _selectedModel!;
    return apiKey == 'free' ? 'big-pickle' : 'gemini-2.0-flash';
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('gemini_api_key');
    _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
    _selectedModel = prefs.getString('selected_model');
    notifyListeners();
  }

  Future<bool> setApiKey(String key) async {
    final isValid = await GeminiService.validateKey(key);
    if (isValid) {
      _apiKey = key;
      _selectedModel = 'gemini-2.0-flash';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gemini_api_key', key);
      await prefs.setString('selected_model', 'gemini-2.0-flash');
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> setFreeMode() async {
    _apiKey = 'free';
    _selectedModel = 'big-pickle';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', 'free');
    await prefs.setString('selected_model', 'big-pickle');
    notifyListeners();
  }

  Future<void> setSelectedModel(String model) async {
    _selectedModel = model;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_model', model);
    notifyListeners();
  }

  Future<void> clearApiKey() async {
    _apiKey = null;
    _selectedModel = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('gemini_api_key');
    await prefs.remove('selected_model');
    notifyListeners();
  }

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    notifyListeners();
  }
}
