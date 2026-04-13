import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/bottom_nav.dart';
import '../home/ootd_menu.dart';
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
      final callable = FirebaseFunctions.instance.httpsCallable(
        'generateOutfitSuggestion',
      );
      final response = await callable.call();
      final result = response.data;

      await _repository.createSuggestion(
        title: result['title'] ?? 'AI Styled Look',
        clothingIds: List<String>.from(result['clothingIds'] ?? []),
        generatedBy: 'genkit:v1',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New outfit suggested!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _saveOutfit(
    QueryDocumentSnapshot<Map<String, dynamic>> suggestion,
  ) async {
    final data = suggestion.data();
    await _repository.saveSuggestedOutfit(
      suggestionId: suggestion.id,
      title: (data['title'] ?? 'Saved Outfit').toString(),
      clothingIds: List<String>.from(data['clothingIds'] ?? []),
    );
    await suggestion.reference.update({'status': 'saved'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Styles Lab'),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: const OotdMenu(),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _repository.watchSuggestions(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          final latest = docs.isNotEmpty ? docs.first : null;
          final savedLooks =
              docs.where((d) => d.data()['status'] == 'saved').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Today's Outfit section
              const Text(
                "Today's Outfit",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (latest != null) ...[
                _OutfitCard(
                  data: latest.data(),
                  suggestion: latest,
                  onSave: () => _saveOutfit(latest),
                ),
              ] else ...[
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'No outfit yet.\nTap below to generate one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Suggest New Outfit button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateSuggestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: Text(
                      _isGenerating ? 'Thinking...' : 'Suggest New Outfit'),
                ),
              ),

              const SizedBox(height: 28),

              // Saved Looks section
              const Text(
                'Saved Looks',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (savedLooks.isEmpty)
                Text(
                  'No saved looks yet.',
                  style: TextStyle(color: Colors.grey.shade500),
                )
              else
                ...savedLooks.map((doc) {
                  final data = doc.data();
                  final title =
                      (data['title'] ?? 'Saved Outfit').toString();
                  final count =
                      (data['clothingIds'] as List?)?.length ?? 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              Text('$count pieces',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(Icons.bookmark,
                            color: Colors.black, size: 20),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
      bottomNavigationBar: const AppBottomNav(current: 1),
    );
  }
}

class _OutfitCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final QueryDocumentSnapshot<Map<String, dynamic>> suggestion;
  final VoidCallback onSave;

  const _OutfitCard({
    required this.data,
    required this.suggestion,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final title = (data['title'] ?? 'Suggested Outfit').toString();
    final reasoning = (data['reasoning'] ?? '').toString();
    final status = (data['status'] ?? 'suggested').toString();
    final isSaved = status == 'saved';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
          if (reasoning.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(reasoning,
                style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          // Placeholder outfit items grid
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1,
            children: List.generate(
              3,
              (_) => Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.checkroom,
                    color: Colors.grey, size: 28),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isSaved ? null : onSave,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: isSaved ? Colors.grey : Colors.black),
              ),
              child: Text(
                isSaved ? 'Saved' : 'Save',
                style: TextStyle(
                    color: isSaved ? Colors.grey : Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
