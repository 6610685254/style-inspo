import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:share_plus/share_plus.dart';

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
  bool _wardrobeCacheLoaded = false;
  String _selectedSeason = 'auto';

  // Cache of wardrobe items: id -> data
  Map<String, Map<String, dynamic>> _wardrobeCache = {};

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadWardrobeCache();
  }

  String _getAutoSeason() {
    final month = DateTime.now().month;

    if (month >= 3 && month <= 5) return 'spring';
    if (month >= 6 && month <= 8) return 'summer';
    if (month >= 9 && month <= 11) return 'autumn';
    return 'winter';
  }

  Future<void> _loadWardrobeCache() async {
    try {
      final items = await _repository.getWardrobeItems();
      if (mounted) {
        setState(() {
          _wardrobeCache = {
            for (final doc in items) doc.id: doc.data(),
          };
          _wardrobeCacheLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _wardrobeCacheLoaded = true);
    }
  }

  String _friendlyErrorMessage(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'You must be signed in to generate an outfit. Please log in and try again.';
      case 'failed-precondition':
        return 'Your wardrobe needs at least a few items before the AI can suggest an outfit.';
      case 'internal':
        return 'The outfit generator encountered an error. Please try again in a moment.';
      case 'unavailable':
        return 'Cannot reach the outfit generator right now. Check your internet connection.';
      case 'not-found':
        return 'Outfit generation service is unavailable. Please try again later.';
      default:
        return 'Could not generate outfit (${e.code}). Please try again.';
    }
  }

  Future<void> _generateSuggestion() async {
    if (_wardrobeCache.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add clothes to your wardrobe first.')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final season = _selectedSeason == 'auto'
          ? _getAutoSeason()
          : _selectedSeason;

      final allItems = _wardrobeCache.entries.toList();

      // 1) First try clothes matching selected season OR all-season
      var usableItems = allItems.where((entry) {
        final data = entry.value;
        final itemSeason = (data['season'] ?? 'all').toString().toLowerCase();

        if (season == 'all') return true;

        return itemSeason == season || itemSeason == 'all';
      }).toList();

      // 2) If not enough clothes, allow every season as fallback
      bool usedFallback = false;
      if (usableItems.length < 2) {
        usableItems = allItems;
        usedFallback = true;
      }

      String? topId;
      String? bottomId;
      String? outerId;

      for (final entry in usableItems) {
        final data = entry.value;
        final type = (data['type'] ?? '').toString().toLowerCase();

        if (topId == null &&
            (type.contains('top') ||
                type.contains('shirt') ||
                type.contains('hoodie'))) {
          topId = entry.key;
        }

        if (bottomId == null &&
            (type.contains('bottom') ||
                type.contains('pant') ||
                type.contains('skirt') ||
                type.contains('short'))) {
          bottomId = entry.key;
        }

        if (outerId == null &&
            (type.contains('outerwear') ||
                type.contains('jacket') ||
                type.contains('coat'))) {
          outerId = entry.key;
        }
      }

      final clothingIds = <String>[];

      if (topId != null) clothingIds.add(topId);
      if (bottomId != null) clothingIds.add(bottomId);
      if (outerId != null && (season == 'winter' || season == 'autumn')) {
        clothingIds.add(outerId);
      }

      // 3) If category logic failed, just use first available items
      if (clothingIds.isEmpty) {
        clothingIds.addAll(usableItems.take(3).map((e) => e.key));
      }

      final title = usedFallback
          ? 'Outfit for $season (mixed seasons)'
          : 'Outfit for $season';

      final reasoning = usedFallback
          ? 'Not enough $season clothes found, so other seasons were used as backup.'
          : 'This outfit prioritizes clothes marked for $season or all-season.';

      await _repository.createSuggestion(
        title: title,
        clothingIds: clothingIds,
        generatedBy: 'local-season-generator',
      );

      final uid = _uid;
      if (uid != null) {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('suggestions')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        if (snap.docs.isNotEmpty) {
          await snap.docs.first.reference.update({
            'reasoning': reasoning,
            'season': season,
            'usedFallback': usedFallback,
          });
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generated outfit for $season')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong: $e')),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _showSaveDialog(
    QueryDocumentSnapshot<Map<String, dynamic>> suggestion,
  ) async {
    final data = suggestion.data();
    final defaultTitle = (data['title'] ?? 'Saved Outfit').toString();
    final controller = TextEditingController(text: defaultTitle);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Outfit'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Outfit name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _repository.saveSuggestedOutfit(
      suggestionId: suggestion.id,
      title: controller.text.trim().isEmpty ? defaultTitle : controller.text.trim(),
      clothingIds: List<String>.from(data['clothingIds'] ?? []),
    );
    controller.dispose();
  }
  Future<void> _deleteSuggestion(String suggestionId) async {
  final uid = _uid;
  if (uid == null) return;

  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('suggestions')
        .doc(suggestionId)
        .delete();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleted')),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Delete failed: $e')),
    );
  }
}

  Future<void> _shareOutfit(Map<String, dynamic> data) async {
    final title = (data['title'] ?? 'My Outfit').toString();
    final clothingIds = List<String>.from(data['clothingIds'] ?? []);

    final itemDescriptions = clothingIds.map((id) {
      final item = _wardrobeCache[id];
      if (item == null) return 'Item';
      final type = (item['type'] as String?) ?? 'Item';
      final color = (item['color'] as String?) ?? '';
      return color.isNotEmpty ? '$color $type' : type;
    }).toList();

    final shareText = itemDescriptions.isEmpty
        ? 'Check out my outfit: $title'
        : 'Check out my outfit: $title\n\nItems:\n${itemDescriptions.map((d) => '• $d').join('\n')}';

    await Share.share(shareText, subject: title);
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
          // All suggestions except the latest (which is shown as "Today's Outfit")
          final historyDocs = docs.length > 1
              ? docs.sublist(1)
              : <QueryDocumentSnapshot<Map<String, dynamic>>>[];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                "Today's Outfit",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (latest != null)
                _OutfitCard(
                  data: latest.data(),
                  wardrobeCache: _wardrobeCache,
                  onSave: () => _showSaveDialog(latest),
                  onShare: () => _shareOutfit(latest.data()),
                  onDelete: () => _deleteSuggestion(latest.id),
                  
                )
              else
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

              const SizedBox(height: 16),

              if (_wardrobeCacheLoaded && _wardrobeCache.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.checkroom_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'Your wardrobe is empty',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Add some clothes to your wardrobe first, then come back to generate an outfit suggestion.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pushReplacementNamed('/wardrobe'),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Go to Wardrobe'),
                      ),
                    ],
                  ),
                )
              else ...[
                DropdownButtonFormField<String>(
                  value: _selectedSeason,
                  decoration: const InputDecoration(
                    labelText: 'Generate for season',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'auto', child: Text('Auto Today')),
                    DropdownMenuItem(value: 'all', child: Text('All Season')),
                    DropdownMenuItem(value: 'spring', child: Text('Spring')),
                    DropdownMenuItem(value: 'summer', child: Text('Summer')),
                    DropdownMenuItem(value: 'autumn', child: Text('Autumn')),
                    DropdownMenuItem(value: 'winter', child: Text('Winter')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedSeason = value!;
                    });
                  },
                ),

                const SizedBox(height: 12),

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
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome, size: 18),
                    label: Text(_isGenerating ? 'Thinking...' : 'Suggest New Outfit'),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              const Text(
                'Past Suggestions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (historyDocs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No past suggestions yet. Generate your first outfit above!',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                )
              else
                ...historyDocs.map((doc) {
                  final data = doc.data();
                  final title = (data['title'] ?? 'Outfit').toString();
                  final clothingIds =
                      List<String>.from(data['clothingIds'] ?? []);
                  final isSaved = (data['status'] as String?) == 'saved';
                  final imageUrls = clothingIds
                      .map((id) =>
                          (_wardrobeCache[id]?['imageUrl'] as String?) ?? '')
                      .where((u) => u.isNotEmpty)
                      .take(3)
                      .toList();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageUrls.isNotEmpty)
                          SizedBox(
                            height: 80,
                            child: Row(
                              children: imageUrls.map((url) {
                                return Expanded(
                                  child: Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    height: 80,
                                    errorBuilder: (context, error, stack) =>
                                        Container(color: Colors.grey.shade300),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    Text(
                                      '${clothingIds.length} piece${clothingIds.length == 1 ? '' : 's'}${isSaved ? ' · Saved' : ''}',
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.share_outlined, size: 20),
                                onPressed: () => _shareOutfit(data),
                                tooltip: 'Share outfit',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => _deleteSuggestion(doc.id),
                                tooltip: 'Delete suggestion',
                              ),
                              if (isSaved)
                                const Icon(Icons.bookmark,
                                    color: Colors.black, size: 20)
                              else
                                IconButton(
                                  icon:
                                      const Icon(Icons.bookmark_border, size: 20),
                                  onPressed: () => _showSaveDialog(doc),
                                  tooltip: 'Save outfit',
                                ),
                            ],
                          ),
                        ),
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
  final Map<String, Map<String, dynamic>> wardrobeCache;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _OutfitCard({
    required this.data,
    required this.wardrobeCache,
    required this.onSave,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = (data['title'] ?? 'Suggested Outfit').toString();
    final reasoning = (data['reasoning'] ?? '').toString();
    final status = (data['status'] ?? 'suggested').toString();
    final isSaved = status == 'saved';
    final clothingIds = List<String>.from(data['clothingIds'] ?? []);

    // Resolve images from the wardrobe cache
    final imageUrls = clothingIds
        .map((id) => (wardrobeCache[id]?['imageUrl'] as String?) ?? '')
        .where((u) => u.isNotEmpty)
        .toList();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clothing images strip
          if (imageUrls.isNotEmpty)
            SizedBox(
              height: 130,
              child: Row(
                children: imageUrls.take(3).map((url) {
                  return Expanded(
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      height: 130,
                      errorBuilder: (context, error, stack) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.checkroom, color: Colors.grey),
                      ),
                    ),
                  );
                }).toList(),
              ),
            )
          else if (clothingIds.isNotEmpty)
            // IDs exist but not in cache yet — show loading placeholders
            SizedBox(
              height: 130,
              child: Row(
                children: List.generate(
                  clothingIds.length.clamp(1, 3),
                  (_) => Expanded(
                    child: Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 100,
              color: Colors.grey.shade200,
              child: const Center(
                child: Icon(Icons.checkroom, size: 40, color: Colors.grey),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                if (reasoning.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(reasoning,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 13)),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSaved ? null : onSave,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: isSaved ? Colors.grey : Colors.black),
                        ),
                        child: Text(
                          isSaved ? 'Saved' : 'Save Look',
                          style: TextStyle(
                              color: isSaved ? Colors.grey : Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onShare,
                      icon: const Icon(Icons.share_outlined),
                      tooltip: 'Share outfit',
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete suggestion',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
