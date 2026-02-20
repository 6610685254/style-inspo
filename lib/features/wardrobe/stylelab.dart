import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart'; // Make sure this is in pubspec.yaml
import 'package:flutter/material.dart';

import 'wardrobe_repository.dart';

class StyleLabScreen extends StatefulWidget {
  const StyleLabScreen({super.key});

  @override
  State<StyleLabScreen> createState() => _StyleLabScreenState();
}

class _StyleLabScreenState extends State<StyleLabScreen> {
  final WardrobeRepository _repository = WardrobeRepository();
  bool _isGenerating = false;

  // 1. Upgraded to call your new Genkit AI Cloud Function!
  Future<void> _generateSuggestion() async {
    setState(() => _isGenerating = true);

    try {
      // Call the Firebase Cloud Function we created
      final callable = FirebaseFunctions.instance.httpsCallable(
        'generateOutfitSuggestion',
      );
      final response = await callable.call();

      // The AI returns { title: "...", clothingIds: [...], reasoning: "..." }
      final result = response.data;

      // Save the AI's suggestion to Firestore using your repository
      await _repository.createSuggestion(
        title: result['title'] ?? 'AI Styled Look',
        clothingIds: List<String>.from(result['clothingIds'] ?? []),
        generatedBy: 'genkit:v1',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('AI Outfit Generated! ✨')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating outfit: $e')));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // 2. Added the missing save method
  Future<void> _saveOutfit(
    QueryDocumentSnapshot<Map<String, dynamic>> suggestion,
  ) async {
    final data = suggestion.data();

    await _repository.saveSuggestedOutfit(
      suggestionId: suggestion.id,
      title: (data['title'] ?? 'Saved Outfit').toString(),
      clothingIds: List<String>.from(data['clothingIds'] ?? []),
    );

    // Update the local status so the button turns grey
    await suggestion.reference.update({'status': 'saved'});
  }

  // 3. Complete Build UI pieced together from your snippets
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Style Lab')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateSuggestion,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _isGenerating ? 'AI is thinking...' : 'Generate AI Outfit',
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _repository.watchSuggestions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading suggestions'));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No suggestions yet. Tap generate to create one.',
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final suggestion = docs[index];
                    final data = suggestion.data();
                    final itemCount =
                        (data['clothingIds'] as List?)?.length ?? 0;
                    final status = (data['status'] ?? 'suggested').toString();

                    return Card(
                      child: ListTile(
                        title: Text(
                          (data['title'] ?? 'Suggested Outfit').toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('$itemCount pieces • status: $status'),
                        trailing: FilledButton.tonal(
                          onPressed: status == 'saved'
                              ? null
                              : () => _saveOutfit(suggestion),
                          child: Text(status == 'saved' ? 'Saved' : 'Save'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
