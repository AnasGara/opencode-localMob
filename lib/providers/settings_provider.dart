import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  bool _isDarkMode = true;
  String? _selectedModel;
  String? _openaiApiKey;
  List<String> _openaiModels = [];
  bool _isValidating = false;
  String? _openaiError;

  bool get isDarkMode => _isDarkMode;
  String? get openaiApiKey => _openaiApiKey;
  List<String> get openaiModels => _openaiModels;
  bool get isValidating => _isValidating;
  String? get openaiError => _openaiError;

  String get selectedModel {
    return _selectedModel ?? 'big-pickle';
  }

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
      _selectedModel = prefs.getString('selected_model') ?? 'big-pickle';
      _openaiApiKey = prefs.getString('openai_api_key');
      _openaiModels = prefs.getStringList('openai_models') ?? [];
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

  Future<bool> validateAndFetchOpenAIModels(String key) async {
    _isValidating = true;
    _openaiError = null;
    notifyListeners();

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final url = Uri.parse('https://api.openai.com/v1/models');
      final request = await client.getUrl(url);
      request.headers.set('Authorization', 'Bearer $key');

      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = jsonDecode(responseBody);
        final List<dynamic> list = data['data'] as List<dynamic>;

        final List<String> models = list
            .map((item) => item['id'] as String)
            .toList();

        models.sort();

        _openaiModels = models;
        _openaiApiKey = key;
        _openaiError = null;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('openai_api_key', key);
        await prefs.setStringList('openai_models', models);
        notifyListeners();
        client.close();
        return true;
      } else {
        _openaiError = 'Failed: HTTP ${response.statusCode}';
        client.close();
        notifyListeners();
        return false;
      }
    } catch (e) {
      _openaiError = 'Error: $e';
      notifyListeners();
      return false;
    } finally {
      _isValidating = false;
      notifyListeners();
    }
  }

  Future<void> clearOpenAiApiKey() async {
    _openaiApiKey = null;
    _openaiModels = [];
    _openaiError = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('openai_api_key');
    await prefs.remove('openai_models');

    final List<String> freeModels = [
      'big-pickle',
      'deepseek-v4-flash-free',
      'mimo-v2.5-free',
      'hy3-free',
      'nemotron-3-ultra-free',
      'north-mini-code-free',
    ];
    if (!freeModels.contains(selectedModel)) {
      await setSelectedModel('big-pickle');
    }
    notifyListeners();
  }

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    notifyListeners();
  }
}
