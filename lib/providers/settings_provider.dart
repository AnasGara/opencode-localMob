import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/gemini_service.dart';

class SettingsProvider with ChangeNotifier {
  String? _apiKey;
  bool _isDarkMode = true;
  String? _selectedModel;

  String? _geminiApiKey;
  String? _openaiApiKey;
  String? _claudeApiKey;

  String? get apiKey => _apiKey;
  bool get isDarkMode => _isDarkMode;

  String? get geminiApiKey => _geminiApiKey;
  String? get openaiApiKey => _openaiApiKey;
  String? get claudeApiKey => _claudeApiKey;

  String get selectedModel {
    if (_selectedModel != null) return _selectedModel!;
    return apiKey == 'free' ? 'big-pickle' : 'gemini-2.0-flash';
  }

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _apiKey = prefs.getString('gemini_api_key');
      _geminiApiKey = prefs.getString('gemini_api_key');
      _openaiApiKey = prefs.getString('openai_api_key');
      _claudeApiKey = prefs.getString('claude_api_key');
      _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
      _selectedModel = prefs.getString('selected_model');
    } catch (e, stackTrace) {
      debugPrint('Error loading settings from SharedPreferences: $e\n$stackTrace');
    }
    notifyListeners();
  }

  Future<bool> setApiKey(String key) async {
    final isValid = await GeminiService.validateKey(key);
    if (isValid) {
      _apiKey = key;
      _geminiApiKey = key;
      _selectedModel = 'gemini-2.0-flash';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gemini_api_key', key);
      await prefs.setString('selected_model', 'gemini-2.0-flash');
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> setGeminiApiKey(String? key) async {
    _geminiApiKey = key;
    final prefs = await SharedPreferences.getInstance();
    if (key == null || key.isEmpty) {
      await prefs.remove('gemini_api_key');
      _apiKey = null;
    } else {
      await prefs.setString('gemini_api_key', key);
      _apiKey = key;
    }
    notifyListeners();
  }

  Future<void> setOpenaiApiKey(String? key) async {
    _openaiApiKey = key;
    final prefs = await SharedPreferences.getInstance();
    if (key == null || key.isEmpty) {
      await prefs.remove('openai_api_key');
    } else {
      await prefs.setString('openai_api_key', key);
    }
    notifyListeners();
  }

  Future<void> setClaudeApiKey(String? key) async {
    _claudeApiKey = key;
    final prefs = await SharedPreferences.getInstance();
    if (key == null || key.isEmpty) {
      await prefs.remove('claude_api_key');
    } else {
      await prefs.setString('claude_api_key', key);
    }
    notifyListeners();
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
    _geminiApiKey = null;
    _openaiApiKey = null;
    _claudeApiKey = null;
    _selectedModel = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('gemini_api_key');
    await prefs.remove('openai_api_key');
    await prefs.remove('claude_api_key');
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
