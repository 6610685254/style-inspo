import 'package:flutter/material.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selected = 'English';

  final List<Map<String, String>> _languages = [
    {'label': 'English', 'flag': '🇬🇧'},
    {'label': 'Thai', 'flag': '🇹🇭'},
    {'label': 'Japanese', 'flag': '🇯🇵'},
    {'label': 'Korean', 'flag': '🇰🇷'},
    {'label': 'Chinese', 'flag': '🇨🇳'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Language')),
      body: ListView(
        children: _languages.map((lang) {
          final label = lang['label']!;
          final flag = lang['flag']!;
          final isSelected = _selected == label;

          return ListTile(
            leading: Text(flag, style: const TextStyle(fontSize: 24)),
            title: Text(label),
            trailing: isSelected
                ? const Icon(Icons.check, color: Colors.black)
                : null,
            onTap: () {
              setState(() => _selected = label);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Language set to $label')),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
