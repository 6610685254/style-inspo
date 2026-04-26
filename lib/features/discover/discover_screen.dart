import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/bottom_nav.dart';
import '../home/ootd_menu.dart';
import 'post_detail_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  static const List<String> _styleFilters = [
    'All',
    'Casual',
    'Minimal',
    'Street',
    'Formal',
    'Sporty',
    'Cute',
    'Vintage',
  ];

  String _query = '';
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Discover'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/posting'),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final filtered = docs.where(_matchesFilters).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search outfits, users, styles...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, index) {
                    final label = _styleFilters[index];
                    return ChoiceChip(
                      label: Text(label),
                      selected: _selectedFilter == label,
                      onSelected: (_) => setState(() => _selectedFilter = label),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: _styleFilters.length,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: docs.isEmpty
                    ? _emptyMessage(context, 'No posts yet.\nBe the first to share!')
                    : filtered.isEmpty
                        ? _emptyMessage(context, 'No outfits found')
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(10, 2, 10, 90),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 0.83,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final doc = filtered[index];
                              final data = doc.data();
                              final imageUrl = data['imageUrl'] as String?;
                              final username = (data['username'] ?? 'User').toString();

                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PostDetailScreen(
                                      postId: doc.id,
                                      data: data,
                                    ),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      if (imageUrl != null && imageUrl.isNotEmpty)
                                        Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _fallbackCard(context),
                                        )
                                      else
                                        _fallbackCard(context),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 7),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                Colors.black.withOpacity(0.62),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                          child: Text(
                                            username,
                                            style: const TextStyle(
                                                color: Colors.white, fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const AppBottomNav(current: 2),
    );
  }

  bool _matchesFilters(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final username = (data['username'] ?? '').toString().toLowerCase();
    final caption = (data['caption'] ?? '').toString().toLowerCase();

    final metaRaw = data['outfitMeta'];
    final meta = metaRaw is Map<String, dynamic> ? metaRaw : <String, dynamic>{};
    final styleTags = (meta['styleTags'] as List<dynamic>? ?? [])
        .map((e) => e.toString().toLowerCase())
        .toList();
    final colorTags = (meta['colorTags'] as List<dynamic>? ?? [])
        .map((e) => e.toString().toLowerCase())
        .toList();
    final typeTags = (meta['typeTags'] as List<dynamic>? ?? [])
        .map((e) => e.toString().toLowerCase())
        .toList();

    final selectedFilterLower = _selectedFilter.toLowerCase();
    final styleFilterMatch = _selectedFilter == 'All' || styleTags.contains(selectedFilterLower);
    if (!styleFilterMatch) return false;

    if (_query.isEmpty) return true;

    final searchable = [
      username,
      caption,
      ...styleTags,
      ...colorTags,
      ...typeTags,
    ];

    return searchable.any((value) => value.contains(_query));
  }

  Widget _emptyMessage(BuildContext context, String message) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75)),
      ),
    );
  }

  Widget _fallbackCard(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Icon(
        Icons.checkroom,
        size: 36,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
      ),
    );
  }
}
