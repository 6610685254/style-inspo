import 'package:flutter/material.dart';
import '../../core/widgets/bottom_nav.dart';
import '../home/ootd_menu.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),

      endDrawer: const OotdMenu(),

      body: const Center(child: Text('User profile')),

      bottomNavigationBar: const AppBottomNav(current: 2),
    );
  }
}
