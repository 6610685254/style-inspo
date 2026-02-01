import 'package:flutter/material.dart';
import '../../core/widgets/bottom_nav.dart';
import '../home/ootd_menu.dart';

class WardrobeScreen extends StatelessWidget {
  const WardrobeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wardrobe'),
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

      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/wardrobe/add'),
        child: const Icon(Icons.add),
      ),

      body: const Center(
        child: Text('Wardrobe grid'),
      ),

      bottomNavigationBar: const AppBottomNav(current: 1),
    );
  }
}
