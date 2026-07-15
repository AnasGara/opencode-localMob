import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';
import 'file_browser_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    ChatScreen(),
    FileBrowserScreen(),
  ];

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.apiKey != null || settings.openaiApiKey != null || settings.claudeApiKey != null) {
      Provider.of<ChatProvider>(context, listen: false).initialize(
        settings.apiKey ?? 'free',
        modelName: settings.selectedModel,
        openaiApiKey: settings.openaiApiKey,
        claudeApiKey: settings.claudeApiKey,
        geminiApiKey: settings.geminiApiKey,
      );
    }
  }

  void _showSettingsDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) {
        final currentModel = settings.selectedModel;

        final List<String> availableModels = ['big-pickle', 'minimax-m2.5-free', 'mimo-v2-pro-free', 'nemotron-3-super-free'];
        if (settings.geminiApiKey != null && settings.geminiApiKey!.isNotEmpty) {
          availableModels.addAll(['gemini-2.0-flash', 'gemini-1.5-flash', 'gemini-1.5-pro']);
        }
        if (settings.openaiApiKey != null && settings.openaiApiKey!.isNotEmpty) {
          availableModels.addAll(['gpt-4o', 'gpt-4o-mini', 'o1-mini', 'o3-mini']);
        }
        if (settings.claudeApiKey != null && settings.claudeApiKey!.isNotEmpty) {
          availableModels.addAll(['claude-3-5-sonnet', 'claude-3-5-haiku']);
        }

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
                          settings.apiKey ?? 'free',
                          modelName: newModel,
                          openaiApiKey: settings.openaiApiKey,
                          claudeApiKey: settings.claudeApiKey,
                          geminiApiKey: settings.geminiApiKey,
                        );
                      }
                    }
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'Configure API Keys',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: settings.geminiApiKey,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Google AI Studio Key',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.vpn_key_rounded),
                  ),
                  onChanged: (val) async {
                    await settings.setGeminiApiKey(val.trim());
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: settings.openaiApiKey,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'OpenAI API Key',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.vpn_key_rounded),
                  ),
                  onChanged: (val) async {
                    await settings.setOpenaiApiKey(val.trim());
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: settings.claudeApiKey,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Anthropic Claude Key',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.vpn_key_rounded),
                  ),
                  onChanged: (val) async {
                    await settings.setClaudeApiKey(val.trim());
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Re-initialize ChatProvider with updated key configurations upon closing
                Provider.of<ChatProvider>(context, listen: false).initialize(
                  settings.apiKey ?? 'free',
                  modelName: settings.selectedModel,
                  openaiApiKey: settings.openaiApiKey,
                  claudeApiKey: settings.claudeApiKey,
                  geminiApiKey: settings.geminiApiKey,
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
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Reset Keys'),
                  content: const Text('Are you sure you want to delete this configuration?'),
                  actions: [
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                    TextButton(
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await settings.clearApiKey();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, '/setup');
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_open_outlined),
            activeIcon: Icon(Icons.folder),
            label: 'Files',
          ),
        ],
      ),
    );
  }
}
