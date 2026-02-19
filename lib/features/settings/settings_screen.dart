import 'package:flutter/material.dart';
import 'theme_screen.dart';
import 'language_screen.dart';
import 'notification_screen.dart';
import 'help_screen.dart';
import 'about_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/Login_Screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No user logged in")));
      return;
    }
    try {
      await user.delete();
      _goToLogin(context);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _showReAuthDialog(context, user);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Error deleting account")),
        );
      }
    }
  }

  void _goToLogin(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _showReAuthDialog(BuildContext context, User user) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Password"),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: "Enter your password"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              try {
                final credential = EmailAuthProvider.credential(
                  email: user.email!,
                  password: passwordController.text.trim(),
                );
                await user.reauthenticateWithCredential(credential);
                await user.delete();
                Navigator.pop(context);
                _goToLogin(context);
              } on FirebaseAuthException catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.message ?? "Wrong password")),
                );
              }
            },
            child: const Text("Confirm", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Theme'),
            onTap: () => _open(context, const ThemeScreen()),
          ),
          ListTile(
            title: const Text('Language'),
            onTap: () => _open(context, const LanguageScreen()),
          ),
          ListTile(
            title: const Text('Notification center'),
            onTap: () => _open(context, const NotificationScreen()),
          ),
          ListTile(
            title: const Text('Help center'),
            onTap: () => _open(context, const HelpScreen()),
          ),
          ListTile(
            title: const Text('About app'),
            onTap: () => _open(context, const AboutScreen()),
          ),
          const Divider(),
          ListTile(
            title: const Text(
              'Delete account',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Account'),
                  content: const Text(
                    'Are you sure you want to permanently delete your account?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteAccount(context);
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
