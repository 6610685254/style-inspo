import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/bottom_nav.dart';
import '../home/ootd_menu.dart';
import 'wardrobe_repository.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  final WardrobeRepository _repository = WardrobeRepository();

  final List<Color> _filterColors = [
    Colors.black,
    Colors.grey,
    Colors.red,
    Colors.pink,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.brown,
  ];

  final List<String> _filterColorNames = [
    'black',
    'grey',
    'red',
    'pink',
    'orange',
    'yellow',
    'green',
    'blue',
    'purple',
    'brown',
  ];

  int? _selectedColorIndex;

  Color _nameToColor(String colorName) {
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
      case 'pink':
        return Colors.pink;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Wardrobe'),
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
        onPressed: () => Navigator.of(context).pushNamed('/wardrobe/add'),
        child: const Icon(Icons.add_a_photo_outlined),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color filter dots
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _filterColors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = _selectedColorIndex == index;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedColorIndex = selected ? null : index;
                  }),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _filterColors[index],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.black : Colors.grey.shade300,
                        width: selected ? 2.5 : 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Wardrobe items
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _repository.watchClothes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data?.docs ?? [];

                // Apply color filter
                final docs = _selectedColorIndex == null
                    ? allDocs
                    : allDocs.where((doc) {
                        final color =
                            (doc.data()['color'] ?? '').toString().toLowerCase();
                        return color
                            .contains(_filterColorNames[_selectedColorIndex!]);
                      }).toList();


                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.checkroom_outlined,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _selectedColorIndex == null
                              ? 'No clothes yet.\nTap + to add your first item.'
                              : 'No items with that color.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                // Group by type
                final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> grouped = {};
                for (final doc in docs) {
                  final type = (doc.data()['type'] ?? 'Other').toString();
                  final category = _capitalize(type);
                  grouped.putIfAbsent(category, () => []).add(doc);
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  children: grouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.85,
                          children: entry.value.map((doc) {
                            final data = doc.data();
                            final imageUrl = data['imageUrl'] as String?;
                            final color = (data['color'] ?? '').toString();

                            return GestureDetector(
                              onTap: () => _showEditSheet(context, doc),
                              onLongPress: () => _confirmDelete(context, doc.id),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (imageUrl != null && imageUrl.isNotEmpty)
                                      Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.checkroom,
                                                size: 32),
                                      )
                                    else
                                      const Icon(Icons.checkroom, size: 32),
                                    if (color.isNotEmpty)
                                      Positioned(
                                        bottom: 6,
                                        right: 6,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: _nameToColor(color),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white, width: 1),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(current: 1),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Future<void> _showEditSheet(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final colorController =
        TextEditingController(text: data['color']?.toString() ?? '');
    String selectedType = _capitalize(data['type']?.toString() ?? 'Top');
    String selectedSeason =
        _capitalize(data['season']?.toString() ?? 'All');

    final clothingTypes = ['Top', 'Bottom', 'Shoes', 'Outerwear', 'Dress', 'Accessory'];
    final seasons = ['All', 'Spring', 'Summer', 'Autumn', 'Winter'];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final onSurface = Theme.of(ctx).colorScheme.onSurface;
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Edit Item',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _confirmDelete(context, doc.id);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Category
                const Text('Category',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: clothingTypes.map((type) {
                    final sel = selectedType == type;
                    return ChoiceChip(
                      label: Text(type),
                      selected: sel,
                      selectedColor: onSurface,
                      labelStyle: TextStyle(
                        color: sel
                            ? Theme.of(ctx).colorScheme.surface
                            : onSurface,
                      ),
                      onSelected: (_) =>
                          setSheetState(() => selectedType = type),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Color
                const Text('Color',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: colorController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Navy Blue',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Season
                const Text('Season',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: seasons.map((season) {
                    final sel = selectedSeason == season;
                    return ChoiceChip(
                      label: Text(season),
                      selected: sel,
                      selectedColor: onSurface,
                      labelStyle: TextStyle(
                        color: sel
                            ? Theme.of(ctx).colorScheme.surface
                            : onSurface,
                      ),
                      onSelected: (_) =>
                          setSheetState(() => selectedSeason = season),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: onSurface,
                      foregroundColor: Theme.of(ctx).colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      await _repository.updateClothingItem(
                        clothingId: doc.id,
                        type: selectedType.toLowerCase(),
                        color: colorController.text.trim().toLowerCase(),
                        season: selectedSeason.toLowerCase(),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Save changes'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _repository.deleteClothingItem(docId);
    }
  }
}
