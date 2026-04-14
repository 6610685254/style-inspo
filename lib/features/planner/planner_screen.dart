import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/widgets/bottom_nav.dart';
import '../home/ootd_menu.dart';
import '../wardrobe/wardrobe_repository.dart';

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

  final List<String> _weekDays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  int _selectedDayIndex = _todayIndex();

  static int _todayIndex() {
    // weekday: Mon=1 ... Sun=7
    final w = DateTime.now().weekday;
    return w - 1; // 0-based index matching _weekDays
  }

  Future<void> _addPlan(String defaultDay) async {
    final uid = _uid;
    if (uid == null) return;

    final repo = WardrobeRepository();
    List<QueryDocumentSnapshot<Map<String, dynamic>>> wardrobeItems = [];
    try {
      wardrobeItems = await repo.getWardrobeItems();
    } catch (_) {}

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddPlanSheet(
        initialDay: defaultDay,
        weekDays: _weekDays,
        wardrobeItems: wardrobeItems,
        onSave: (title, day, selectedIds, selectedImageUrls) async {
          await _plansRef.add({
            'title': title,
            'day': day,
            'clothingIds': selectedIds,
            'imageUrls': selectedImageUrls,
            'createdAt': FieldValue.serverTimestamp(),
          });
        },
      ),
    );
  }

  Future<void> _deletePlan(String docId) async {
    await _plansRef.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              stream: _plansRef.snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];

                final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> byDay = {};
                for (final doc in docs) {
                  final day = (doc.data()['day'] ?? 'Mon').toString();
                  byDay.putIfAbsent(day, () => []).add(doc);
                }

                return Column(
                  children: [
                    // Day selector tabs
                    Container(
                      color: theme.colorScheme.surface,
                      child: Row(
                        children: List.generate(_weekDays.length, (i) {
                          final day = _weekDays[i];
                          final isSelected = i == _selectedDayIndex;
                          final hasPlans = byDay.containsKey(day);
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedDayIndex = i),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: isSelected
                                          ? theme.colorScheme.onSurface
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      day,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? theme.colorScheme.onSurface
                                            : Colors.grey,
                                      ),
                                    ),
                                    if (hasPlans)
                                      Container(
                                        margin: const EdgeInsets.only(top: 3),
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? theme.colorScheme.onSurface
                                              : Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const Divider(height: 1),

                    // Plans for selected day
                    Expanded(
                      child: _DayPlansList(
                        day: _weekDays[_selectedDayIndex],
                        plans: byDay[_weekDays[_selectedDayIndex]] ?? [],
                        onDelete: _deletePlan,
                        onAdd: () => _addPlan(_weekDays[_selectedDayIndex]),
                      ),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addPlan(_weekDays[_selectedDayIndex]),
        icon: const Icon(Icons.add),
        label: const Text('Add Outfit'),
      ),
      bottomNavigationBar: const AppBottomNav(current: 0),
    );
  }
}

// ─── Day plans list ───────────────────────────────────────────────────────────

class _DayPlansList extends StatelessWidget {
  const _DayPlansList({
    required this.day,
    required this.plans,
    required this.onDelete,
    required this.onAdd,
  });

  final String day;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> plans;
  final void Function(String docId) onDelete;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (plans.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checkroom_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No outfits planned for $day',
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Plan an outfit'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: plans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final doc = plans[i];
        final data = doc.data();
        final title = (data['title'] ?? 'Outfit').toString();
        final imageUrls = (data['imageUrls'] as List?)
            ?.map((e) => e.toString())
            .where((u) => u.isNotEmpty)
            .toList() ?? [];

        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image strip
              if (imageUrls.isNotEmpty)
                SizedBox(
                  height: 110,
                  child: Row(
                    children: imageUrls.take(3).map((url) {
                      return Expanded(
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          height: 110,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.checkroom, color: Colors.grey),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                )
              else
                Container(
                  height: 80,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.checkroom, size: 36, color: Colors.grey),
                  ),
                ),

              // Title + delete
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => onDelete(doc.id),
                      child: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Add plan bottom sheet ────────────────────────────────────────────────────

class _AddPlanSheet extends StatefulWidget {
  const _AddPlanSheet({
    required this.initialDay,
    required this.weekDays,
    required this.wardrobeItems,
    required this.onSave,
  });

  final String initialDay;
  final List<String> weekDays;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> wardrobeItems;
  final Future<void> Function(
    String title,
    String day,
    List<String> selectedIds,
    List<String> selectedImageUrls,
  ) onSave;

  @override
  State<_AddPlanSheet> createState() => _AddPlanSheetState();
}

class _AddPlanSheetState extends State<_AddPlanSheet> {
  final _titleController = TextEditingController();
  late String _selectedDay;
  final Set<String> _selectedIds = {};
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialDay;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Please enter an outfit name');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final selectedItems = widget.wardrobeItems
        .where((doc) => _selectedIds.contains(doc.id))
        .toList();

    final imageUrls = selectedItems
        .map((doc) => (doc.data()['imageUrl'] as String?) ?? '')
        .where((u) => u.isNotEmpty)
        .toList();

    try {
      await widget.onSave(title, _selectedDay, _selectedIds.toList(), imageUrls);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() {
        _saving = false;
        _error = 'Failed to save. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'Plan an Outfit',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),

            const Divider(height: 1),

            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                children: [
                  // Outfit name
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Outfit name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Day picker
                  const Text('Day', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: widget.weekDays.map((day) {
                      final selected = day == _selectedDay;
                      return ChoiceChip(
                        label: Text(day),
                        selected: selected,
                        onSelected: (_) => setState(() => _selectedDay = day),
                        selectedColor: theme.colorScheme.onSurface,
                        labelStyle: TextStyle(
                          color: selected
                              ? theme.colorScheme.surface
                              : theme.colorScheme.onSurface,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Wardrobe picker
                  Row(
                    children: [
                      const Text('Select Clothes', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      if (_selectedIds.isNotEmpty)
                        Text(
                          '(${_selectedIds.length} selected)',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (widget.wardrobeItems.isEmpty)
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'No clothes in wardrobe yet.',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                      ),
                      itemCount: widget.wardrobeItems.length,
                      itemBuilder: (context, i) {
                        final doc = widget.wardrobeItems[i];
                        final data = doc.data();
                        final imageUrl = (data['imageUrl'] as String?) ?? '';
                        final type = (data['type'] as String?) ?? '';
                        final isSelected = _selectedIds.contains(doc.id);

                        return GestureDetector(
                          onTap: () => setState(() {
                            if (isSelected) {
                              _selectedIds.remove(doc.id);
                            } else {
                              _selectedIds.add(doc.id);
                            }
                          }),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey.shade300,
                                          child: const Icon(Icons.checkroom, color: Colors.grey),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.grey.shade300,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.checkroom, color: Colors.grey),
                                            if (type.isNotEmpty)
                                              Text(type,
                                                  style: const TextStyle(
                                                      fontSize: 10, color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                              ),
                              // Selection overlay
                              if (isSelected)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    color: Colors.black38,
                                    child: const Center(
                                      child: Icon(Icons.check_circle, color: Colors.white, size: 28),
                                    ),
                                  ),
                                ),
                              // Border when selected
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: isSelected
                                        ? Border.all(color: Colors.white, width: 2.5)
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
