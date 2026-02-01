import 'package:flutter/material.dart';

class AddWardrobeScreen extends StatelessWidget {
  const AddWardrobeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add to Wardrobe')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/wardrobe/camera'),
          child: const Text('Take photo'),
        ),
      ),
    );
  }
}
