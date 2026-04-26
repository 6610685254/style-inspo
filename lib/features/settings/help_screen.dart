import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    {
      'q': 'How do I add clothes to my wardrobe?',
      'a':
          'Go to the Wardrobe tab and tap the + button. You can take a photo or pick one from your gallery, then select the category, color, and season.',
    },
    {
      'q': 'How does the AI outfit suggestion work?',
      'a':
          'Open Styles Lab and tap "Suggest Outfit". The AI analyzes your wardrobe and generates a matching outfit for you.',
    },
    {
      'q': 'How do I plan outfits for the week?',
      'a':
          'Go to Styles Planner from the Home screen. Tap "Add Plan" to assign an outfit to a specific day of the week.',
    },
    {
      'q': 'How do I post an outfit?',
      'a':
          'Go to the Discover tab and tap the + button. Upload a photo, write a description, and optionally link items from your wardrobe or saved outfits.',
    },
    {
      'q': 'How do I delete my account?',
      'a':
          'Go to Settings and tap "Delete Account" at the bottom. You will be asked to confirm your password before deletion.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _faqs.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final faq = _faqs[index];
          return ExpansionTile(
            title: Text(
              faq['q']!,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  faq['a']!,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
