import 'package:flutter/material.dart';
import '../../core/widgets/bottom_nav.dart';
import '../home/ootd_menu.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        onPressed: () {
          Navigator.of(context).pushNamed('/wardrobe/add');
        },
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),

      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await FirebaseFirestore.instance.collection('test').add({
              'message': 'Firebase is working 🔥',
              'createdAt': FieldValue.serverTimestamp(),
            });

            print("Data added!");
          },
          child: const Text("Test Firestore"),
        ),
      ),

      bottomNavigationBar: const AppBottomNav(current: 1),
    );
  }
}
