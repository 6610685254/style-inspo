import 'package:flutter/material.dart';
import '../../core/widgets/bottom_nav.dart';
import '../home/ootd_menu.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
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

      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.trending_up),
            title: const Text("What's Trending"),
            onTap: () => Navigator.pushNamed(context, '/posts'),
          ),
        ],
      ),

      bottomNavigationBar: const AppBottomNav(current: 2),
    );
  }
}
