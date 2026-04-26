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

  // Cache of wardrobe items: id -> data
  Map<String, Map<String, dynamic>> _wardrobeCache = {};

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadWardrobeCache();
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

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    return <String>[];
  }

  String _inferRole(String type) {
    final t = type.toLowerCase();
    if (t.contains('top') || t.contains('shirt') || t.contains('hoodie') || t.contains('tee')) {
      return 'top';
    }
    if (t.contains('bottom') || t.contains('pant') || t.contains('skirt') || t.contains('short') || t.contains('jean')) {
      return 'bottom';
    }
    if (t.contains('shoe') || t.contains('sneaker') || t.contains('boot') || t.contains('heel')) {
      return 'shoes';
    }
    if (t.contains('outerwear') || t.contains('jacket') || t.contains('coat') || t.contains('blazer')) {
      return 'outerwear';
    }
    return 'other';
  }

  int _matchCount(List<String> a, List<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    return a.toSet().intersection(b.toSet()).length;
  }

  String _buildOutfitSignature(List<String> clothingIds) {
    final normalized = clothingIds.toSet().toList()..sort();
    return normalized.join('|');
  }

  Future<Set<String>> _loadRecentOutfitSignatures(String uid) async {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 7));
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('suggestions')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();

    final signatures = <String>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      final ts = data['createdAt'];
      if (ts is Timestamp && ts.toDate().isBefore(cutoff)) continue;
      final signature = (data['outfitSignature'] ?? '').toString();
      if (signature.isNotEmpty) {
        signatures.add(signature);
        continue;
      }
      final ids = _asStringList(data['clothingIds']);
      if (ids.isNotEmpty) {
        signatures.add(_buildOutfitSignature(ids));
      }
    }
    return signatures;
  }

  ({List<String> ids, bool reusedRecent}) _pickOutfitWithDedup({
    required List<MapEntry<String, Map<String, dynamic>>> usableItems,
    required Set<String> recentSignatures,
    required String season,
    Map<String, String> preferredByRole = const {},
  }) {
    final byRole = <String, List<String>>{
      'top': [],
      'bottom': [],
      'shoes': [],
      'outerwear': [],
      'other': [],
    };
    for (final item in usableItems) {
      final role = _inferRole((item.value['type'] ?? '').toString());
      byRole.putIfAbsent(role, () => []).add(item.key);
    }

    void prioritize(String role) {
      final preferred = preferredByRole[role];
      if (preferred == null) return;
      final list = byRole[role] ?? [];
      if (list.remove(preferred)) {
        list.insert(0, preferred);
      }
      byRole[role] = list;
    }

    prioritize('top');
    prioritize('bottom');
    prioritize('shoes');
    prioritize('outerwear');

    final tops = byRole['top']!;
    final bottoms = byRole['bottom']!;
    final shoes = byRole['shoes']!;
    final outer = byRole['outerwear']!;
    final others = byRole['other']!;

    final candidateIds = <List<String>>[];
    if (tops.isNotEmpty && bottoms.isNotEmpty) {
      final topChoices = tops.take(3).toList();
      final bottomChoices = bottoms.take(3).toList();
      final shoesChoices = shoes.take(2).toList();
      final outerChoices = outer.take(2).toList();
      for (final t in topChoices) {
        for (final b in bottomChoices) {
          final base = <String>[t, b];
          candidateIds.add(base);
          for (final s in shoesChoices) {
            candidateIds.add([...base, s]);
          }
          if (season == 'winter' || season == 'autumn') {
            for (final o in outerChoices) {
              candidateIds.add([...base, o]);
              for (final s in shoesChoices) {
                candidateIds.add([...base, o, s]);
              }
            }
          }
        }
      }
    }

    if (candidateIds.isEmpty) {
      final fallbackPool = [
        ...tops,
        ...bottoms,
        ...shoes,
        ...outer,
        ...others,
      ];
      for (var i = 0; i < fallbackPool.length; i++) {
        candidateIds.add(fallbackPool.skip(i).take(3).toList());
      }
    }

    candidateIds.removeWhere((ids) => ids.isEmpty);
    for (final ids in candidateIds) {
      final signature = _buildOutfitSignature(ids);
      if (!recentSignatures.contains(signature)) {
        return (ids: ids.toSet().toList(), reusedRecent: false);
      }
    }

    final fallback = candidateIds.isNotEmpty
        ? candidateIds.first.toSet().toList()
        : usableItems.take(3).map((e) => e.key).toList();
    return (ids: fallback, reusedRecent: true);
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
      const season = 'all';
      final allItems = _wardrobeCache.entries.toList();
      var usableItems = allItems.where((entry) {
        final itemSeason = (entry.value['season'] ?? 'all').toString().toLowerCase();
        if (season == 'all') return true;
        return itemSeason == season || itemSeason == 'all';
      }).toList();
      bool usedFallback = false;
      if (usableItems.length < 2) {
        usableItems = allItems;
        usedFallback = true;
      }

      final uid = _uid;
      final ownedIds = usableItems.map((e) => e.key).toSet();
      final recentSignatures = uid == null
          ? <String>{}
          : await _loadRecentOutfitSignatures(uid);
      if (uid != null) {
        final aiSuggestionId = await _repository.generateAIOutfit();
        if (aiSuggestionId != null) {
          final aiDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('suggestions')
              .doc(aiSuggestionId)
              .get();
          final aiIds = _asStringList(aiDoc.data()?['clothingIds']);
          final usesOnlyOwned = aiIds.isNotEmpty && aiIds.every(ownedIds.contains);
          final aiSignature = _buildOutfitSignature(aiIds);
          final isDuplicateRecent = recentSignatures.contains(aiSignature);
          if (usesOnlyOwned && !isDuplicateRecent) {
            await aiDoc.reference.update({
              'title': 'Outfit suggestion',
              'source': 'balanced',
              'status': 'suggested',
              'outfitSignature': aiSignature,
              'reasoning': 'Based on your saved style preferences and matched with your wardrobe.',
            });
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Suggested outfit')),
            );
            return;
          }
          await aiDoc.reference.delete();
        }
      }

      final roleSelections = <String, String>{};
      String source = 'balanced';
      String reasoning = 'Fallback suggestion based on your wardrobe.';

      if (uid != null) {
        final likedSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('likedPosts')
            .get();
        final likedPostIds = likedSnap.docs.map((d) => d.id).toSet();

        final postsSnap = await FirebaseFirestore.instance.collection('posts').get();
        final posts = postsSnap.docs
            .where((d) => (d.data()['outfitMeta'] is List) && (d.data()['outfitMeta'] as List).isNotEmpty)
            .toList();
        posts.sort((a, b) {
          final aLikes = ((a.data()['likeCount'] ?? a.data()['likes'] ?? 0) as num).toInt();
          final bLikes = ((b.data()['likeCount'] ?? b.data()['likes'] ?? 0) as num).toInt();
          return bLikes.compareTo(aLikes);
        });

        int bestPostScore = -1;
        Map<String, dynamic>? bestPostData;

        for (final post in posts.take(40)) {
          final postData = post.data();
          final metaEntries = (postData['outfitMeta'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
              .toList();
          if (metaEntries.isEmpty) continue;

          final roleBest = <String, Map<String, dynamic>>{};
          int aggregateScore = 0;

          for (final template in metaEntries) {
            final templateType = (template['type'] ?? '').toString().toLowerCase();
            final role = _inferRole(templateType);
            if (role == 'other') continue;
            int bestScore = -1;
            String? bestId;
            for (final item in usableItems) {
              final data = item.value;
              final itemRole = _inferRole((data['type'] ?? '').toString());
              if (itemRole != role) continue;
              int score = 0;
              if (itemRole == role) score += 5;
              if ((data['color'] ?? '').toString().toLowerCase() ==
                  (template['color'] ?? '').toString().toLowerCase()) {
                score += 3;
              }
              score += _matchCount(
                    _asStringList(data['styleTags']),
                    _asStringList(template['styleTags']),
                  ) *
                  3;
              score += _matchCount(
                    _asStringList(data['occasionTags']),
                    _asStringList(template['occasionTags']),
                  ) *
                  2;
              score += _matchCount(
                    _asStringList(data['weatherTags']),
                    _asStringList(template['weatherTags']),
                  ) *
                  2;
              if (score > bestScore) {
                bestScore = score;
                bestId = item.key;
              }
            }
            if (bestId != null && bestScore >= 5) {
              roleBest[role] = {'id': bestId, 'score': bestScore};
              aggregateScore += bestScore;
            }
          }

          final likeCount = ((postData['likeCount'] ?? postData['likes'] ?? 0) as num).toInt();
          aggregateScore += likeCount ~/ 10;
          if (likedPostIds.contains(post.id)) {
            aggregateScore += 8;
          }
          if (aggregateScore > bestPostScore && roleBest.isNotEmpty) {
            bestPostScore = aggregateScore;
            bestPostData = {
              'post': postData,
              'roleBest': roleBest,
            };
          }
        }

        if (bestPostData != null) {
          final roleBest = (bestPostData['roleBest'] as Map<String, dynamic>);
          roleSelections.addAll(
            roleBest.map((key, value) => MapEntry(key, (value as Map<String, dynamic>)['id'].toString())),
          );
          source = 'balanced';
          reasoning = 'Inspired by community trends and matched with your wardrobe.';
        }
      }

      if (roleSelections.isEmpty) {
        String? topId;
        String? bottomId;
        String? outerId;
        String? shoesId;
        for (final entry in usableItems) {
          final role = _inferRole((entry.value['type'] ?? '').toString());
          if (topId == null && role == 'top') topId = entry.key;
          if (bottomId == null && role == 'bottom') bottomId = entry.key;
          if (outerId == null && role == 'outerwear') outerId = entry.key;
          if (shoesId == null && role == 'shoes') shoesId = entry.key;
        }
        if (topId != null) roleSelections['top'] = topId;
        if (bottomId != null) roleSelections['bottom'] = bottomId;
        if (shoesId != null) roleSelections['shoes'] = shoesId;
        if (outerId != null) {
          roleSelections['outerwear'] = outerId;
        }
      }
      final dedupPick = _pickOutfitWithDedup(
        usableItems: usableItems,
        recentSignatures: recentSignatures,
        season: season,
        preferredByRole: roleSelections,
      );
      final clothingIds = dedupPick.ids.where(ownedIds.contains).toSet().toList();
      if (clothingIds.isEmpty) {
        clothingIds.addAll(usableItems.take(3).map((e) => e.key));
      }
      final reusedRecent = dedupPick.reusedRecent;
      final outfitSignature = _buildOutfitSignature(clothingIds);

      const title = 'Outfit suggestion';
      await _repository.createSuggestion(
        title: title,
        clothingIds: clothingIds,
        outfitSignature: outfitSignature,
        generatedBy: 'hybrid-community-recommender',
        source: source,
        reasoning: reusedRecent
            ? 'Limited wardrobe options, so a recent combination may be reused.'
            : roleSelections.isEmpty
                ? 'Fallback suggestion based on your wardrobe.'
                : reasoning,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Suggested outfit')));
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
                    'No outfit yet.\nTap below to suggest one.',
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
                        'Add some clothes to your wardrobe first, then come back to suggest an outfit.',
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
                    label: Text(_isGenerating ? 'Thinking...' : 'Suggest Outfit'),
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
