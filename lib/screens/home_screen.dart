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
      openaiApiKey: settings.openaiApiKey,
    );
  }

  void _showSettingsDialog(BuildContext context, SettingsProvider settings) {
    final keyController = TextEditingController(text: settings.openaiApiKey ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final currentModel = settings.selectedModel;

            final List<String> freeModels = [
              'big-pickle',
              'deepseek-v4-flash-free',
              'mimo-v2.5-free',
              'hy3-free',
              'nemotron-3-ultra-free',
              'north-mini-code-free',
            ];

            final List<String> allAvailableModels = [
              ...freeModels,
              ...settings.openaiModels,
            ];

            final activeModel = allAvailableModels.contains(currentModel)
                ? currentModel
                : 'big-pickle';

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.settings_rounded, color: Colors.deepPurple),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Active Model',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: activeModel,
                        isExpanded: true,
                        items: allAvailableModels.map((model) {
                          String displayName = model;
                          if (model == 'big-pickle') {
                            displayName = 'big-pickle (Recommended Free)';
                          } else if (model == 'gpt-4o') {
                            displayName = 'gpt-4o (Recommended OpenAI 🔥)';
                          } else if (model == 'gpt-4o-mini') {
                            displayName = 'gpt-4o-mini (Recommended OpenAI ✨)';
                          }
                          return DropdownMenuItem<String>(
                            value: model,
                            child: Text(displayName, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (newModel) async {
                          if (newModel != null) {
                            await settings.setSelectedModel(newModel);
                            if (context.mounted) {
                              Provider.of<ChatProvider>(context, listen: false).initialize(
                                'free',
                                modelName: newModel,
                                openaiApiKey: settings.openaiApiKey,
                              );
                            }
                            setState(() {});
                          }
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      const Divider(height: 32),
                      const Text(
                        'OpenAI Integration',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: keyController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'OpenAI API Key',
                          hintText: 'sk-...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (settings.isValidating) ...[
                        const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurple),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Validating & fetching models...',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ] else if (settings.openaiError != null) ...[
                        Text(
                          settings.openaiError!,
                          style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                      ] else if (settings.openaiApiKey != null) ...[
                        Text(
                          '✅ Connected: ${settings.openaiModels.length} models fetched.',
                          style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: const Text('Validate & Save'),
                              onPressed: settings.isValidating
                                  ? null
                                  : () async {
                                      final key = keyController.text.trim();
                                      if (key.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Please enter an OpenAI API Key')),
                                        );
                                        return;
                                      }
                                      final success = await settings.validateAndFetchOpenAIModels(key);
                                      if (success) {
                                        if (context.mounted) {
                                          Provider.of<ChatProvider>(context, listen: false).initialize(
                                            'free',
                                            modelName: settings.selectedModel,
                                            openaiApiKey: key,
                                          );
                                        }
                                      }
                                      setState(() {});
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () async {
                              keyController.clear();
                              await settings.clearOpenAiApiKey();
                              if (context.mounted) {
                                Provider.of<ChatProvider>(context, listen: false).initialize(
                                  'free',
                                  modelName: settings.selectedModel,
                                );
                              }
                              setState(() {});
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Provider.of<ChatProvider>(context, listen: false).initialize(
                      'free',
                      modelName: settings.selectedModel,
                      openaiApiKey: settings.openaiApiKey,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
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
