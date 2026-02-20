import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/bottom_nav.dart';
import '../home/ootd_menu.dart';
import 'wardrobe_repository.dart';

class WardrobeScreen extends StatelessWidget {
  const WardrobeScreen({super.key});

  Color _chipColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'blue':
        return Colors.blue;
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'brown':
        return Colors.brown;
      default:
        return Colors.grey.shade400;
    }
  }

  Future<void> _seedDemoItem(
    BuildContext context,
    WardrobeRepository repository,
  ) async {
    await repository.createClothingItem(
      imageRef: 'gs://your-project-id/wardrobe/demo_shirt.jpg',
      type: 'shirt',
      color: 'blue',
      season: 'all',
      tags: const ['casual', 'cotton'],
      visionAttributes: const {'pattern': 'solid', 'fit': 'regular'},
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demo item saved to Firestore.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = WardrobeRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wardrobe'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/style-lab'),
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Open Style Lab',
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      endDrawer: const OotdMenu(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed('/wardrobe/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _seedDemoItem(context, repository),
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text('Save Demo Metadata'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/style-lab'),
                    icon: const Icon(Icons.tips_and_updates_outlined),
                    label: const Text('Get Suggestions'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: repository.watchClothes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No clothes saved yet. Add items with photos and metadata to build your online wardrobe.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final type = (data['type'] ?? 'Unknown').toString();
                    final color = (data['color'] ?? 'n/a').toString();
                    final season = (data['season'] ?? 'all').toString();
                    final tags = List<String>.from(data['tags'] ?? []);

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 88,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey.shade200,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.checkroom, size: 36),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              type,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 7,
                                  backgroundColor: _chipColor(color),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '$color • $season',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              tags.isEmpty ? 'No tags' : '#${tags.join(' #')}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey.shade700),
                            ),
                          ],
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
      bottomNavigationBar: const AppBottomNav(current: 1),
    );
  }
}
