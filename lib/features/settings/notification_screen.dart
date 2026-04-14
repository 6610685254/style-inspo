import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _newPosts = true;
  bool _likes = true;
  bool _suggestions = false;
  bool _weeklyPlanner = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Center')),
      body: ListView(
        children: [
          _Toggle(
            label: 'New posts from people you follow',
            value: _newPosts,
            onChanged: (v) => setState(() => _newPosts = v),
          ),
          _Toggle(
            label: 'Likes on your posts',
            value: _likes,
            onChanged: (v) => setState(() => _likes = v),
          ),
          _Toggle(
            label: 'AI outfit suggestions',
            value: _suggestions,
            onChanged: (v) => setState(() => _suggestions = v),
          ),
          _Toggle(
            label: 'Weekly planner reminder',
            value: _weeklyPlanner,
            onChanged: (v) => setState(() => _weeklyPlanner = v),
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _Toggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      activeThumbColor: Theme.of(context).colorScheme.onSurface,
    );
  }
}
