import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Us')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Image.asset('assets/images/logo.png', height: 120),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Style Inspo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const Center(
            child: Text('Version 1.0.0',
                style: TextStyle(color: Colors.grey)),
          ),
          const SizedBox(height: 32),
          const Text(
            'About',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Style Inspo is a trend-aware wardrobe and outfit suggestion app. '
            'Build your digital closet, get AI-powered outfit suggestions, '
            'plan your weekly looks, and share your style with the community.',
            style: TextStyle(color: Colors.grey.shade700, height: 1.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'Features',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...[
            'Digital wardrobe management',
            'AI-powered outfit suggestions',
            'Weekly style planner',
            'Discover & share outfits',
            'Trend-aware recommendations',
          ].map(
            (f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 18, color: Colors.black),
                  const SizedBox(width: 8),
                  Text(f),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
