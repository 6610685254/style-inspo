import 'package:flutter/material.dart';

class TakePhotoScreen extends StatelessWidget {
  const TakePhotoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: const Center(child: Text('Camera preview')),
    );
  }
}
