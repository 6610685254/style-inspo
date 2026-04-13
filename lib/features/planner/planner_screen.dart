import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/widgets/bottom_nav.dart';
import '../home/ootd_menu.dart';

class StylesPlannerScreen extends StatefulWidget {
  const StylesPlannerScreen({super.key});

  @override
  State<StylesPlannerScreen> createState() => _StylesPlannerScreenState();
}

class _StylesPlannerScreenState extends State<StylesPlannerScreen> {
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _plansRef => FirebaseFirestore
      .instance
      .collection('users')
      .doc(_uid)
      .collection('plans');

  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  Future<void> _addPlan() async {
    final titleController = TextEditingController();
    final dayNotifier = ValueNotifier<String>('Mon');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Outfit name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<String>(
              valueListenable: dayNotifier,
              builder: (_, selected, __) => DropdownButtonFormField<String>(
                value: selected,
                decoration: const InputDecoration(
                  labelText: 'Day',
                  border: OutlineInputBorder(),
                ),
                items: _weekDays
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => dayNotifier.value = v ?? selected,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (confirmed == true && titleController.text.trim().isNotEmpty) {
      await _plansRef.add({
        'title': titleController.text.trim(),
        'day': dayNotifier.value,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _deletePlan(String docId) async {
    await _plansRef.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Styles Planner'),
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
      body: _uid == null
          ? const Center(child: Text('Please log in'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _plansRef.orderBy('createdAt', descending: false).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                // Planned Outfits grid (all plans)
                // This week grouped by day
                final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> byDay = {};
                for (final doc in docs) {
                  final day = (doc.data()['day'] ?? 'Mon').toString();
                  byDay.putIfAbsent(day, () => []).add(doc);
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Planned Outfits grid preview
                    const Text(
                      'Planned Outfits',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    if (docs.isEmpty)
                      Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'No planned outfits yet.',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      )
                    else
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.9,
                        children: docs.take(6).map((doc) {
                          final title = (doc.data()['title'] ?? '').toString();
                          final day = (doc.data()['day'] ?? '').toString();
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.checkroom, size: 28, color: Colors.grey),
                                const SizedBox(height: 4),
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  day,
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 24),

                    // This week section
                    const Text(
                      'This week',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    ..._weekDays.where((d) => byDay.containsKey(d)).map((day) {
                      final dayPlans = byDay[day]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              day,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey),
                            ),
                          ),
                          ...dayPlans.map((doc) {
                            final title =
                                (doc.data()['title'] ?? 'Outfit').toString();
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.checkroom,
                                      size: 18, color: Colors.grey),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500)),
                                  ),
                                  GestureDetector(
                                    onTap: () => _deletePlan(doc.id),
                                    child: const Icon(Icons.close,
                                        size: 18, color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                        ],
                      );
                    }),

                    const SizedBox(height: 80),
                  ],
                );
              },
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPlan,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Plan'),
      ),
      bottomNavigationBar: const AppBottomNav(current: 0),
    );
  }
}
