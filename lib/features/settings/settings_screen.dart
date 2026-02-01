import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Theme'),
            onTap: () => Navigator.pushNamed(context, '/settings/theme'),
          ),
          ListTile(
            title: const Text('Language'),
            onTap: () => Navigator.pushNamed(context, '/settings/language'),
          ),
          ListTile(
            title: const Text('Notification center'),
            onTap: () => Navigator.pushNamed(context, '/settings/notification'),
          ),
          ListTile(
            title: const Text('Help center'),
            onTap: () => Navigator.pushNamed(context, '/settings/help'),
          ),
          ListTile(
            title: const Text('About app'),
            onTap: () => Navigator.pushNamed(context, '/settings/about'),
          ),
          const Divider(),
          const ListTile(
            title: Text('Delete account', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
