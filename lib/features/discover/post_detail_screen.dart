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

  // Live author data
  Map<String, dynamic>? _authorData;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _likeCount = (widget.data['likes'] as int?) ?? 0;
    _checkLiked();
    _checkSaved();
    _streamAuthor();
    _streamLikeCount();
  }

  void _streamAuthor() {
    final authorUid = (widget.data['uid'] ?? '').toString();
    if (authorUid.isEmpty) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(authorUid)
        .snapshots()
        .listen((doc) {
      if (doc.exists && mounted) {
        setState(() => _authorData = doc.data());
      }
    });
  }

  void _streamLikeCount() {
    FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .snapshots()
        .listen((doc) {
      if (doc.exists && mounted) {
        final count = (doc.data()?['likes'] as int?) ?? 0;
        setState(() => _likeCount = count);
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

    // Update UI immediately
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
          'imageUrl': widget.data['imageUrl'] ?? '',
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
        'imageUrl': widget.data['imageUrl'] ?? '',
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

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final imageUrl = data['imageUrl'] as String?;
    final authorUid = (data['uid'] ?? '').toString();
    // Use live author data if available, fallback to post data
    final username = (_authorData?['username'] as String?) ??
        (data['username'] ?? 'User').toString();
    final photoUrl = (_authorData?['photoUrl'] as String?) ??
        (data['photoUrl'] ?? '').toString();
    final description = (data['description'] ?? '').toString();
    final savedOutfit = (data['savedOutfit'] ?? '').toString();
    final wardrobeItem = (data['wardrobeItem'] ?? '').toString();
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
                backgroundImage: photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl.isEmpty
                    ? const Icon(Icons.person, size: 16)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(username, style: const TextStyle(fontSize: 15)),
            ],
          ),
        ),
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
                    child: imageUrl != null && imageUrl.isNotEmpty
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

                // Like / Save + description + outfit info
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Action row
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _toggleLike,
                              child: Icon(
                                _liked ? Icons.favorite : Icons.favorite_border,
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

                        if (savedOutfit.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(children: [
                            const Icon(Icons.style_outlined,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            const Text('Saved Outfit: ',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey)),
                            Expanded(
                              child: Text(savedOutfit,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                            ),
                          ]),
                        ],

                        if (wardrobeItem.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(children: [
                            const Icon(Icons.checkroom_outlined,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            const Text('Wardrobe: ',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey)),
                            Expanded(
                              child: Text(wardrobeItem,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                            ),
                          ]),
                        ],

                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 4),
                        Text('Comments',
                            style: theme.textTheme.titleSmall),
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
                                    text:
                                        '${c['username'] ?? 'User'}  ',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                      text:
                                          (c['text'] ?? '').toString()),
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
                border: Border(
                    top: BorderSide(color: Colors.grey.shade300)),
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
                          child: CircularProgressIndicator(strokeWidth: 2),
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
