import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    Provider.of<ChatProvider>(context, listen: false).initialize(
      'free',
      modelName: settings.selectedModel,
    );
  }

  void _showSettingsDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) {
        final currentModel = settings.selectedModel;

        final List<String> availableModels = [
          'big-pickle',
          'deepseek-v4-flash-free',
          'mimo-v2.5-free',
          'hy3-free',
          'nemotron-3-ultra-free',
          'north-mini-code-free',
        ];

        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.settings_rounded, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text('Settings'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Active Model',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: availableModels.contains(currentModel) ? currentModel : availableModels.first,
                  items: availableModels.map((model) {
                    return DropdownMenuItem<String>(
                      value: model,
                      child: Text(model),
                    );
                  }).toList(),
                  onChanged: (newModel) async {
                    if (newModel != null) {
                      await settings.setSelectedModel(newModel);
                      if (context.mounted) {
                        Provider.of<ChatProvider>(context, listen: false).initialize(
                          'free',
                          modelName: newModel,
                        );
                      }
                    }
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Provider.of<ChatProvider>(context, listen: false).initialize(
                  'free',
                  modelName: settings.selectedModel,
                );
                Navigator.pop(ctx);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bou3orrif'),
            Text(
              'Model: ${settings.selectedModel}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings & Model Selection',
            onPressed: () => _showSettingsDialog(context, settings),
          ),
          IconButton(
            icon: Icon(settings.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: settings.toggleTheme,
          ),
        ],
      ),
      body: const ChatScreen(),
    );
  }
}
