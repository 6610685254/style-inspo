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

  String? _selectedSavedOutfit;
  String? _selectedWardrobeItem;

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
      _snack('Upload failed: ${e.code} — ${e.message}');
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

      // Get username
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final username =
          (userDoc.data()?['username'] as String?) ?? 'User';
      final photoUrl =
          (userDoc.data()?['photoUrl'] as String?) ?? '';

      final imageUrl = await _uploadImage(_imageFile!);
      if (imageUrl == null) throw Exception('Image upload failed');

      await FirebaseFirestore.instance.collection('posts').add({
        'uid': uid,
        'username': username,
        'photoUrl': photoUrl,
        'imageUrl': imageUrl,
        'description': _descController.text.trim(),
        'savedOutfit': _selectedSavedOutfit ?? '',
        'wardrobeItem': _selectedWardrobeItem ?? '',
        'likes': 0,
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
        title: Row(
          children: const [
            CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
            SizedBox(width: 8),
            Text('New Post', style: TextStyle(fontSize: 15)),
          ],
        ),
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
                              style:
                                  TextStyle(color: Colors.grey.shade500)),
                        ],
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Write the description of the post that you will create',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // Select from Saved Outfits
            const Text('Select Clothes from Saved Outfits',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

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
                  return DropdownButtonFormField<String>(
                    value: _selectedSavedOutfit,
                    hint: const Text('Choose an outfit'),
                    decoration: const InputDecoration(
                        border: OutlineInputBorder()),
                    items: docs.map((doc) {
                      final title =
                          (doc.data()['title'] ?? 'Outfit').toString();
                      return DropdownMenuItem(
                          value: title, child: Text(title));
                    }).toList(),
                    onChanged: (v) =>
                        setState(() => _selectedSavedOutfit = v),
                  );
                },
              ),

            const SizedBox(height: 20),

            // Select from Wardrobe
            const Text('Select Clothes from Wardrobe',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

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
                  return DropdownButtonFormField<String>(
                    value: _selectedWardrobeItem,
                    hint: const Text('Choose an item'),
                    decoration: const InputDecoration(
                        border: OutlineInputBorder()),
                    items: docs.map((doc) {
                      final type =
                          (doc.data()['type'] ?? 'Item').toString();
                      final color =
                          (doc.data()['color'] ?? '').toString();
                      final label =
                          color.isNotEmpty ? '$type ($color)' : type;
                      return DropdownMenuItem(
                          value: label, child: Text(label));
                    }).toList(),
                    onChanged: (v) =>
                        setState(() => _selectedWardrobeItem = v),
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
