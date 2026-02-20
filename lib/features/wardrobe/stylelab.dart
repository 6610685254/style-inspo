import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<void> _generateSuggestion() async {
    setState(() => _isGenerating = true);

    try {
      final items = await _repository.getWardrobeItems();
      if (items.length < 2) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add at least 2 wardrobe items to generate a look.'),
          ),
        );
        return;
      }

      final tops = items.where((doc) {
        final type = (doc.data()['type'] ?? '').toString().toLowerCase();
        return type.contains('shirt') ||
            type.contains('top') ||
            type.contains('jacket');
      }).toList();

      final bottoms = items.where((doc) {
        final type = (doc.data()['type'] ?? '').toString().toLowerCase();
        return type.contains('pants') ||
            type.contains('skirt') ||
            type.contains('shorts');
      }).toList();

      final selected = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      if (tops.isNotEmpty && bottoms.isNotEmpty) {
        selected
          ..add(tops.first)
          ..add(bottoms.first);
      } else {
        selected
          ..add(items.first)
          ..add(items[1]);
      }

      final clothingIds = selected.map((item) => item.id).toList();
      final title =
          'Suggested Look ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';

      await _repository.createSuggestion(
        title: title,
        clothingIds: clothingIds,
        confidence: 0.76,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New outfit suggestion generated.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _saveOutfit(
    DocumentSnapshot<Map<String, dynamic>> suggestion,
  ) async {
    final data = suggestion.data();
    if (data == null) return;

    final clothingIds = List<String>.from(data['clothingIds'] ?? []);

    await _repository.saveSuggestedOutfit(
      suggestionId: suggestion.id,
      title: (data['title'] ?? 'Saved Outfit').toString(),
      clothingIds: clothingIds,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Outfit saved to your collection.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Style Lab')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: _isGenerating ? null : _generateSuggestion,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _isGenerating ? 'Generating...' : 'Generate Outfit Suggestion',
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
                        ),
                        subtitle: Text('$itemCount pieces • status: $status'),
                        trailing: FilledButton.tonal(
                          onPressed: status == 'saved'
                              ? null
                              : () => _saveOutfit(suggestion),
                          child: const Text('Save'),
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
