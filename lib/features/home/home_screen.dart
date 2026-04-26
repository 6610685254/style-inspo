import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../asset/style_button.dart';
import '../../core/widgets/bottom_nav.dart';
import '../discover/post_detail_screen.dart';
import 'ootd_menu.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Outfit Of Today'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OutfitOfTodayCard(uid: uid),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StyleButton(
                    label: 'Suggest Outfit',
                    icon: Icons.checkroom_outlined,
                    color: Colors.black,
                    onPressed: () => Navigator.pushNamed(context, '/style-lab'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StyleButton(
                    label: 'Planner',
                    icon: Icons.calendar_month_outlined,
                    color: Colors.black,
                    onPressed: () => Navigator.pushNamed(context, '/planner'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Trending Outfits', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .orderBy('createdAt', descending: true)
                  .limit(4)
                  .snapshots(),
              builder: (context, snapshot) {
                final posts = snapshot.data?.docs ?? [];

                if (posts.isEmpty) {
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                    children: List.generate(
                      4,
                      (_) => _placeholderTile(context, radius: 14),
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final doc = posts[index];
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
                                    _placeholderTile(context, radius: 14),
                              )
                            else
                              _placeholderTile(context, radius: 14),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.58),
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
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(current: 0),
    );
  }
}

class _OutfitOfTodayCard extends StatelessWidget {
  const _OutfitOfTodayCard({required this.uid});

  final String? uid;

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return _EmptyOutfitState(message: 'Sign in to get outfit suggestions.');
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('suggestions')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _EmptyOutfitState(
            message: 'No suggestion yet. Tap Suggest Outfit to start.',
          );
        }

        final suggestionData = docs.first.data();
        final clothingIds = (suggestionData['clothingIds'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList();

        final reasonRaw = suggestionData['reasoning'] ??
            suggestionData['reason'] ??
            suggestionData['explanation'];
        final reason = (reasonRaw is String && reasonRaw.trim().isNotEmpty)
            ? reasonRaw.trim()
            : 'Based on your wardrobe and community trends.';

        if (clothingIds.isEmpty) {
          return _EmptyOutfitState(
            message: reason,
            icon: Icons.checkroom_outlined,
          );
        }

        return FutureBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
          future: Future.wait(
            clothingIds.map(
              (id) => FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('clothes')
                  .doc(id)
                  .get(),
            ),
          ),
          builder: (context, itemSnap) {
            final items = (itemSnap.data ?? [])
                .where((doc) => doc.exists)
                .toList(growable: false);

            if (items.isEmpty) {
              return _EmptyOutfitState(message: reason);
            }

            final crossAxisCount = items.length == 1
                ? 1
                : items.length == 2
                    ? 2
                    : 2;
            final aspectRatio = items.length >= 4 ? 0.78 : 0.95;

            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.builder(
                    itemCount: items.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: aspectRatio,
                    ),
                    itemBuilder: (_, index) {
                      final imageUrl = items[index].data()?['imageUrl'] as String?;
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _placeholderTile(context, radius: 12),
                              )
                            : _placeholderTile(context, radius: 12),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    reason,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.72),
                        ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyOutfitState extends StatelessWidget {
  const _EmptyOutfitState({
    required this.message,
    this.icon = Icons.auto_awesome,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        children: [
          Icon(icon, size: 26, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

Widget _placeholderTile(BuildContext context, {double radius = 8}) {
  return Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Theme.of(context).colorScheme.outline),
    ),
    child: Icon(
      Icons.image_outlined,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
    ),
  );
}
