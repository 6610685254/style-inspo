import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/bottom_nav.dart';
import '../../asset/style_button.dart';
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
            // Outfit Of Today — latest AI suggestion items
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: uid == null
                      ? _placeholderGrid()
                      : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .collection('suggestions')
                              .orderBy('createdAt', descending: true)
                              .limit(1)
                              .snapshots(),
                          builder: (context, snapshot) {
                            final docs = snapshot.data?.docs ?? [];
                            if (docs.isEmpty) return _placeholderGrid();

                            final clothingIds = List<String>.from(
                                docs.first.data()['clothingIds'] ?? []);

                            if (clothingIds.isEmpty) return _placeholderGrid();

                            return FutureBuilder<
                                List<DocumentSnapshot<Map<String, dynamic>>>>(
                              future: Future.wait(
                                clothingIds.take(4).map((id) =>
                                    FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(uid)
                                        .collection('clothes')
                                        .doc(id)
                                        .get()),
                              ),
                              builder: (context, itemSnap) {
                                final items = itemSnap.data ?? [];
                                if (items.isEmpty) return _placeholderGrid();

                                return GridView.count(
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: 6,
                                  crossAxisSpacing: 6,
                                  childAspectRatio: 1,
                                  children: List.generate(4, (i) {
                                    if (i >= items.length) {
                                      return _placeholderTile();
                                    }
                                    final data = items[i].data();
                                    final imageUrl =
                                        data?['imageUrl'] as String?;
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: imageUrl != null &&
                                              imageUrl.isNotEmpty
                                          ? Image.network(imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  _placeholderTile())
                                          : _placeholderTile(),
                                    );
                                  }),
                                );
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Other styles you might like.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, '/style-lab'),
                        child: Text(
                          'Suggest new →',
                          style: TextStyle(
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Quick action buttons
            Row(
              children: [
                Expanded(
                  child: StyleButton(
                    label: 'Style Labs',
                    icon: Icons.checkroom_outlined,
                    color: Colors.black,
                    onPressed: () =>
                        Navigator.pushNamed(context, '/style-lab'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StyleButton(
                    label: 'Styles Planner',
                    icon: Icons.calendar_month_outlined,
                    color: Colors.black,
                    onPressed: () =>
                        Navigator.pushNamed(context, '/planner'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              'Trending Outfits',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Real posts from Firestore
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
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                    children: List.generate(4, (_) => _placeholderTile(radius: 12)),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final doc = posts[index];
                    final data = doc.data();
                    final imageUrl = data['imageUrl'] as String?;
                    final username =
                        (data['username'] ?? 'User').toString();

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
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (imageUrl != null && imageUrl.isNotEmpty)
                              Image.network(imageUrl, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _placeholderTile(radius: 12))
                            else
                              _placeholderTile(radius: 12),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.6),
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

  Widget _placeholderGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 1,
      children: List.generate(4, (_) => _placeholderTile()),
    );
  }

  Widget _placeholderTile({double radius = 8}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
