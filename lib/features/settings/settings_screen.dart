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

  Widget buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget page,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 236, 236, 236),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _open(context, page),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildSettingItem(
              context,
              icon: Icons.language,
              title: "Language",
              page: const LanguageScreen(),
            ),
            buildSettingItem(
              context,
              icon: Icons.notifications,
              title: "Notification Center",
              page: const NotificationScreen(),
            ),
            buildSettingItem(
              context,
              icon: Icons.help_outline,
              title: "Help Center",
              page: const HelpScreen(),
            ),
            buildSettingItem(
              context,
              icon: Icons.info_outline,
              title: "About Us",
              page: const AboutScreen(),
            ),
            buildSettingItem(
              context,
              icon: Icons.color_lens_outlined,
              title: "Theme",
              page: const ThemeScreen(),
            ),

            const SizedBox(height: 30),

            //Delete Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
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
                child: const Text(
                  "Delete Account",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
