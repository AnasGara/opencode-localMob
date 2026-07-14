import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _keyController = TextEditingController();
  bool _isValidating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() => _errorMessage = 'API Key is required');
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final success = await settings.setApiKey(key);

    if (success) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      if (mounted) {
        setState(() {
          _isValidating = false;
          _errorMessage = 'Invalid Gemini API Key or connection error.';
        });
      }
    }
  }

  void _skipAndUseFreeModels() async {
    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    await settings.setFreeMode();

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.code_rounded, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 16),
              const Text(
                'Bou3orrif',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your Google Gemini API Key. Stored safely in local state.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _keyController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Google Gemini Key',
                  border: const OutlineInputBorder(),
                  errorText: _errorMessage,
                  prefixIcon: const Icon(Icons.vpn_key_rounded),
                ),
              ),
              const SizedBox(height: 24),
              _isValidating
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                          ),
                          onPressed: _validateAndSubmit,
                          child: const Text('Validate & Start'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                          onPressed: _skipAndUseFreeModels,
                          child: const Text('Skip & Use Free Models'),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
