import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_profile_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> data;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.data,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _liked = false;
  bool _saved = false;
  int _likeCount = 0;
  final _commentController = TextEditingController();
  bool _submitting = false;

  Map<String, dynamic>? _authorData;
  // Live post data (for edits to reflect immediately)
  late Map<String, dynamic> _postData;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  bool get _isOwner => _uid != null && _uid == _postData['uid'];

  @override
  void initState() {
    super.initState();
    _postData = Map<String, dynamic>.from(widget.data);
    _likeCount = (_postData['likes'] as int?) ?? 0;
    _checkLiked();
    _checkSaved();
    _streamAuthor();
    _streamLikeCount();
    _streamPost();
  }

  void _streamAuthor() {
    final authorUid = (_postData['uid'] ?? '').toString();
    if (authorUid.isEmpty) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(authorUid)
        .snapshots()
        .listen((doc) {
      if (doc.exists && mounted) setState(() => _authorData = doc.data());
    });
  }

  void _streamLikeCount() {
    FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .snapshots()
        .listen((doc) {
      if (doc.exists && mounted) {
        setState(() =>
            _likeCount = (doc.data()?['likes'] as int?) ?? 0);
      }
    });
  }

  void _streamPost() {
    FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .snapshots()
        .listen((doc) {
      if (doc.exists && mounted && doc.data() != null) {
        setState(() => _postData = doc.data()!);
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _checkLiked() async {
    final uid = _uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('likes')
        .doc(uid)
        .get();
    if (mounted) setState(() => _liked = doc.exists);
  }

  Future<void> _checkSaved() async {
    final uid = _uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('savedPosts')
        .doc(widget.postId)
        .get();
    if (mounted) setState(() => _saved = doc.exists);
  }

  Future<void> _toggleLike() async {
    final uid = _uid;
    if (uid == null) return;

    final likeRef = FirebaseFirestore.instance
        .collection('posts').doc(widget.postId).collection('likes').doc(uid);
    final userLikeRef = FirebaseFirestore.instance
        .collection('users').doc(uid).collection('likedPosts').doc(widget.postId);
    final postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.postId);

    if (_liked) {
      setState(() {
        _liked = false;
        _likeCount = (_likeCount - 1).clamp(0, 99999);
      });
      try {
        await likeRef.delete();
        await userLikeRef.delete();
        await postRef.update({'likes': _likeCount});
      } catch (_) {}
    } else {
      setState(() {
        _liked = true;
        _likeCount++;
      });
      try {
        await likeRef.set({'likedAt': FieldValue.serverTimestamp()});
        await userLikeRef.set({
          'postId': widget.postId,
          'likedAt': FieldValue.serverTimestamp(),
          'imageUrl': _postData['imageUrl'] ?? '',
        });
        await postRef.update({'likes': _likeCount});
      } catch (_) {}
    }
  }

  Future<void> _toggleSave() async {
    final uid = _uid;
    if (uid == null) return;

    final savedRef = FirebaseFirestore.instance
        .collection('users').doc(uid).collection('savedPosts').doc(widget.postId);

    if (_saved) {
      await savedRef.delete();
      setState(() => _saved = false);
    } else {
      await savedRef.set({
        'postId': widget.postId,
        'savedAt': FieldValue.serverTimestamp(),
        'imageUrl': _postData['imageUrl'] ?? '',
      });
      setState(() => _saved = true);
    }
  }

  Future<void> _submitComment() async {
    final uid = _uid;
    final text = _commentController.text.trim();
    if (uid == null || text.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(uid).get();
      final username = (userDoc.data()?['username'] as String?) ?? 'User';

      await FirebaseFirestore.instance
          .collection('posts').doc(widget.postId).collection('comments')
          .add({
        'uid': uid,
        'username': username,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Edit post ─────────────────────────────────────────────────────────────

  Future<void> _editPost() async {
    final uid = _uid;
    if (uid == null) return;

    // Load wardrobe + saved outfits for the picker
    final wardrobeSnap = await FirebaseFirestore.instance
        .collection('users').doc(uid).collection('clothes').get();
    final outfitsSnap = await FirebaseFirestore.instance
        .collection('users').doc(uid).collection('savedOutfits').get();

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditPostSheet(
        postId: widget.postId,
        currentData: _postData,
        wardrobeDocs: wardrobeSnap.docs,
        outfitDocs: outfitsSnap.docs,
      ),
    );
  }

  // ── Delete post ───────────────────────────────────────────────────────────

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('This will permanently delete your post.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .delete();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = (_postData['imageUrl'] as String?) ?? '';
    final authorUid = (_postData['uid'] ?? '').toString();
    final username = (_authorData?['username'] as String?) ??
        (_postData['username'] ?? 'User').toString();
    final photoUrl = (_authorData?['photoUrl'] as String?) ??
        (_postData['photoUrl'] ?? '').toString();
    final description = (_postData['description'] ?? '').toString();

    // Support both old (single string) and new (list) format
    final wardrobeItems = _postData['wardrobeItems'] != null
        ? List<String>.from(_postData['wardrobeItems'])
        : (_postData['wardrobeItem'] != null &&
                (_postData['wardrobeItem'] as String).isNotEmpty)
            ? [(_postData['wardrobeItem'] as String)]
            : <String>[];

    final savedOutfits = _postData['savedOutfits'] != null
        ? List<String>.from(_postData['savedOutfits'])
        : (_postData['savedOutfit'] != null &&
                (_postData['savedOutfit'] as String).isNotEmpty)
            ? [(_postData['savedOutfit'] as String)]
            : <String>[];

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            if (authorUid.isNotEmpty && authorUid != _uid) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfileScreen(
                    userId: authorUid,
                    username: username,
                  ),
                ),
              );
            }
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage:
                    photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl.isEmpty
                    ? const Icon(Icons.person, size: 16)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(username, style: const TextStyle(fontSize: 15)),
            ],
          ),
        ),
        actions: [
          if (_isOwner)
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') _editPost();
                if (val == 'delete') _deletePost();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit post')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete post',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Post image
                SliverToBoxAdapter(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.broken_image, size: 48),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.checkroom,
                                size: 64, color: Colors.grey),
                          ),
                  ),
                ),

                // Actions + description + tags
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Like / Save row
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _toggleLike,
                              child: Icon(
                                _liked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _liked
                                    ? Colors.red
                                    : theme.colorScheme.onSurface,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('$_likeCount',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const Spacer(),
                            GestureDetector(
                              onTap: _toggleSave,
                              child: Icon(
                                _saved
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: theme.colorScheme.onSurface,
                                size: 26,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Description
                        if (description.isNotEmpty) ...[
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                  color: theme.colorScheme.onSurface),
                              children: [
                                TextSpan(
                                  text: '$username  ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: description),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        const Divider(),

                        // Wardrobe items tags
                        if (wardrobeItems.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.checkroom_outlined,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: wardrobeItems
                                      .map((item) => Chip(
                                            label: Text(item,
                                                style: const TextStyle(
                                                    fontSize: 12)),
                                            padding: EdgeInsets.zero,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ))
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Saved outfits tags
                        if (savedOutfits.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.style_outlined,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: savedOutfits
                                      .map((outfit) => Chip(
                                            label: Text(outfit,
                                                style: const TextStyle(
                                                    fontSize: 12)),
                                            padding: EdgeInsets.zero,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ))
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 4),
                        Text('Comments', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),

                // Comments list
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .collection('comments')
                      .orderBy('createdAt')
                      .snapshots(),
                  builder: (context, snap) {
                    final comments = snap.data?.docs ?? [];
                    if (comments.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Text('No comments yet.',
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13)),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final c = comments[i].data();
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                    color: theme.colorScheme.onSurface),
                                children: [
                                  TextSpan(
                                    text: '${c['username'] ?? 'User'}  ',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                      text: (c['text'] ?? '').toString()),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: comments.length,
                      ),
                    );
                  },
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),
              ],
            ),
          ),

          // Comment input bar
          SafeArea(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border:
                    Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment…',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor:
                            theme.colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _submitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          onPressed: _submitComment,
                          icon: const Icon(Icons.send),
                          padding: EdgeInsets.zero,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Edit post bottom sheet ───────────────────────────────────────────────────

class _EditPostSheet extends StatefulWidget {
  const _EditPostSheet({
    required this.postId,
    required this.currentData,
    required this.wardrobeDocs,
    required this.outfitDocs,
  });

  final String postId;
  final Map<String, dynamic> currentData;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> wardrobeDocs;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> outfitDocs;

  @override
  State<_EditPostSheet> createState() => _EditPostSheetState();
}

class _EditPostSheetState extends State<_EditPostSheet> {
  late final TextEditingController _descController;
  late Map<String, String> _selectedWardrobe; // id -> label
  late Map<String, String> _selectedOutfits;  // id -> title
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(
      text: (widget.currentData['description'] ?? '').toString(),
    );

    // Pre-select existing wardrobe items by matching IDs
    final existingIds = List<String>.from(
        widget.currentData['wardrobeItemIds'] ?? []);
    _selectedWardrobe = {};
    for (final doc in widget.wardrobeDocs) {
      if (existingIds.contains(doc.id)) {
        final data = doc.data();
        final type = (data['type'] ?? 'Item').toString();
        final color = (data['color'] ?? '').toString();
        _selectedWardrobe[doc.id] =
            color.isNotEmpty ? '$type ($color)' : type;
      }
    }

    // Pre-select existing outfits
    final existingOutfitIds = List<String>.from(
        widget.currentData['savedOutfitIds'] ?? []);
    _selectedOutfits = {};
    for (final doc in widget.outfitDocs) {
      if (existingOutfitIds.contains(doc.id)) {
        _selectedOutfits[doc.id] =
            (doc.data()['title'] ?? 'Outfit').toString();
      }
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update({
        'description': _descController.text.trim(),
        'wardrobeItems': _selectedWardrobe.values.toList(),
        'wardrobeItemIds': _selectedWardrobe.keys.toList(),
        'savedOutfits': _selectedOutfits.values.toList(),
        'savedOutfitIds': _selectedOutfits.keys.toList(),
        'editedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save. Try again.')),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Column(
          children: [
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
                  const Text('Edit Post',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed:
                        _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                children: [
                  // Description
                  TextField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Wardrobe items
                  Row(
                    children: [
                      const Text('Wardrobe Items',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      if (_selectedWardrobe.isNotEmpty)
                        Text('(${_selectedWardrobe.length} selected)',
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (widget.wardrobeDocs.isEmpty)
                    Text('No wardrobe items.',
                        style: TextStyle(color: Colors.grey.shade500))
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                      ),
                      itemCount: widget.wardrobeDocs.length,
                      itemBuilder: (context, i) {
                        final doc = widget.wardrobeDocs[i];
                        final data = doc.data();
                        final imageUrl =
                            (data['imageUrl'] as String?) ?? '';
                        final type =
                            (data['type'] ?? 'Item').toString();
                        final color =
                            (data['color'] ?? '').toString();
                        final label = color.isNotEmpty
                            ? '$type ($color)'
                            : type;
                        final isSelected =
                            _selectedWardrobe.containsKey(doc.id);

                        return GestureDetector(
                          onTap: () => setState(() {
                            if (isSelected) {
                              _selectedWardrobe.remove(doc.id);
                            } else {
                              _selectedWardrobe[doc.id] = label;
                            }
                          }),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: imageUrl.isNotEmpty
                                    ? Image.network(imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _greyBox(label))
                                    : _greyBox(label),
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
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  // Saved outfits
                  Row(
                    children: [
                      const Text('Saved Outfits',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      if (_selectedOutfits.isNotEmpty)
                        Text('(${_selectedOutfits.length} selected)',
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (widget.outfitDocs.isEmpty)
                    Text('No saved outfits.',
                        style: TextStyle(color: Colors.grey.shade500))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.outfitDocs.map((doc) {
                        final title =
                            (doc.data()['title'] ?? 'Outfit').toString();
                        final selected =
                            _selectedOutfits.containsKey(doc.id);
                        return FilterChip(
                          label: Text(title),
                          selected: selected,
                          onSelected: (val) => setState(() {
                            if (val) {
                              _selectedOutfits[doc.id] = title;
                            } else {
                              _selectedOutfits.remove(doc.id);
                            }
                          }),
                          selectedColor: theme.colorScheme.onSurface,
                          labelStyle: TextStyle(
                            color: selected
                                ? theme.colorScheme.surface
                                : theme.colorScheme.onSurface,
                            fontSize: 13,
                          ),
                        );
                      }).toList(),
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

  Widget _greyBox(String label) => Container(
        color: Colors.grey.shade300,
        child: Center(
          child: Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, color: Colors.grey)),
        ),
      );
}
