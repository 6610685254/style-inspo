import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/widgets/bottom_nav.dart';

class PostingScreen extends StatefulWidget {
  const PostingScreen({super.key});

  @override
  State<PostingScreen> createState() => _PostingScreenState();
}

class _PostingScreenState extends State<PostingScreen> {
  final _descController = TextEditingController();
  final _picker = ImagePicker();

  File? _imageFile;
  bool _isPosting = false;

  // Multi-select wardrobe items: doc id -> label
  final Map<String, String> _selectedWardrobe = {};

  // Multi-select saved outfits: doc id -> title
  final Map<String, String> _selectedOutfits = {};

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<String?> _uploadImage(File image) async {
    final uid = _uid;
    if (uid == null) return null;

    final fileName = 'post_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref('posts/$uid/$fileName');

    try {
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      _snack('Upload failed: ${e.code}');
      return null;
    } catch (e) {
      _snack('Upload failed: $e');
      return null;
    }
  }

  Future<void> _post() async {
    if (_imageFile == null) {
      _snack('Please select an image.');
      return;
    }

    setState(() => _isPosting = true);

    try {
      final uid = _uid;
      if (uid == null) throw Exception('Not logged in');

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final username = (userDoc.data()?['username'] as String?) ?? 'User';
      final photoUrl = (userDoc.data()?['photoUrl'] as String?) ?? '';

      final imageUrl = await _uploadImage(_imageFile!);
      if (imageUrl == null) throw Exception('Image upload failed');
      final outfitMeta = <Map<String, dynamic>>[];
      List<String> asList(dynamic value) => value is List
          ? value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : <String>[];
      for (final clothingId in _selectedWardrobe.keys) {
        final clothingDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('clothes')
            .doc(clothingId)
            .get();
        if (!clothingDoc.exists) continue;
        final data = clothingDoc.data() ?? {};
        outfitMeta.add({
          'clothingId': clothingId,
          'type': (data['type'] ?? '').toString(),
          'color': (data['color'] ?? '').toString(),
          'styleTags': asList(data['styleTags']),
          'occasionTags': asList(data['occasionTags']),
          'weatherTags': asList(data['weatherTags']),
        });
      }

      await FirebaseFirestore.instance.collection('posts').add({
        'uid': uid,
        'username': username,
        'photoUrl': photoUrl,
        'imageUrl': imageUrl,
        'description': _descController.text.trim(),
        // Store as lists now
        'wardrobeItems': _selectedWardrobe.values.toList(),
        'wardrobeItemIds': _selectedWardrobe.keys.toList(),
        'savedOutfits': _selectedOutfits.values.toList(),
        'savedOutfitIds': _selectedOutfits.keys.toList(),
        'likes': 0,
        'likeCount': 0,
        'outfitMeta': outfitMeta,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _snack('Posted!');
        Navigator.pop(context);
      }
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post', style: TextStyle(fontSize: 15)),
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _post,
            child: _isPosting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Post',
                    style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  image: _imageFile != null
                      ? DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _imageFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              size: 48, color: Colors.grey.shade500),
                          const SizedBox(height: 8),
                          Text('Tap to add photo',
                              style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      )
                    : Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Write the description of your outfit...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            // ── Wardrobe items ────────────────────────────────────────────
            Row(
              children: [
                const Text('Tag Wardrobe Items',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                if (_selectedWardrobe.isNotEmpty)
                  Text(
                    '(${_selectedWardrobe.length} selected)',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            if (uid != null)
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('clothes')
                    .snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Text('No wardrobe items yet.',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13));
                  }
                  return _ItemGrid(
                    docs: docs,
                    selectedIds: _selectedWardrobe.keys.toSet(),
                    labelBuilder: (data) {
                      final type = (data['type'] ?? 'Item').toString();
                      final color = (data['color'] ?? '').toString();
                      return color.isNotEmpty ? '$type ($color)' : type;
                    },
                    onToggle: (id, label, selected) {
                      setState(() {
                        if (selected) {
                          _selectedWardrobe[id] = label;
                        } else {
                          _selectedWardrobe.remove(id);
                        }
                      });
                    },
                  );
                },
              ),

            const SizedBox(height: 24),

            // ── Saved outfits ─────────────────────────────────────────────
            Row(
              children: [
                const Text('Tag Saved Outfits',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                if (_selectedOutfits.isNotEmpty)
                  Text(
                    '(${_selectedOutfits.length} selected)',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            if (uid != null)
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('savedOutfits')
                    .snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Text('No saved outfits yet.',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13));
                  }
                  // Outfits have no image, show as chips
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: docs.map((doc) {
                      final title =
                          (doc.data()['title'] ?? 'Outfit').toString();
                      final selected =
                          _selectedOutfits.containsKey(doc.id);
                      return FilterChip(
                        label: Text(title),
                        selected: selected,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedOutfits[doc.id] = title;
                            } else {
                              _selectedOutfits.remove(doc.id);
                            }
                          });
                        },
                        selectedColor:
                            Theme.of(context).colorScheme.onSurface,
                        labelStyle: TextStyle(
                          color: selected
                              ? Theme.of(context).colorScheme.surface
                              : Theme.of(context).colorScheme.onSurface,
                          fontSize: 13,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(current: 2),
    );
  }
}

// ─── Reusable image grid with multi-select ───────────────────────────────────

class _ItemGrid extends StatelessWidget {
  const _ItemGrid({
    required this.docs,
    required this.selectedIds,
    required this.labelBuilder,
    required this.onToggle,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final Set<String> selectedIds;
  final String Function(Map<String, dynamic> data) labelBuilder;
  final void Function(String id, String label, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: docs.length,
      itemBuilder: (context, i) {
        final doc = docs[i];
        final data = doc.data();
        final imageUrl = (data['imageUrl'] as String?) ?? '';
        final label = labelBuilder(data);
        final isSelected = selectedIds.contains(doc.id);

        return GestureDetector(
          onTap: () => onToggle(doc.id, label, !isSelected),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(label),
                      )
                    : _placeholder(label),
              ),
              if (isSelected)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: Colors.black45,
                    child: const Center(
                      child: Icon(Icons.check_circle,
                          color: Colors.white, size: 24),
                    ),
                  ),
                ),
              if (isSelected)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _placeholder(String label) {
    return Container(
      color: Colors.grey.shade300,
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 9, color: Colors.grey),
        ),
      ),
    );
  }
}
