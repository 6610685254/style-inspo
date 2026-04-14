import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/widgets/bottom_nav.dart';
import '../home/ootd_menu.dart';

class ProfileScreen extends StatefulWidget {
  final String? username;
  const ProfileScreen({super.key, this.username});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  String _username = '';
  String? _photoUrl;
  int _postCount = 0;
  int _followingCount = 0;
  int _followersCount = 0;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() => _selectedIndex = _tabController.index);
    });
    _loadUsername();
    _loadPostCount();
  }

  void _loadUsername() {
    final uid = _uid;
    if (uid == null) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      if (!doc.exists || !mounted) return;
      final data = doc.data()!;
      setState(() {
        _username = (data['username'] as String?) ?? '';
        _photoUrl = data['photoUrl'] as String?;
        _followingCount = (data['following'] as int?) ?? 0;
        _followersCount = (data['followers'] as int?) ?? 0;
      });
    });
  }

  void _loadPostCount() {
    final uid = _uid;
    if (uid == null) return;
    FirebaseFirestore.instance
        .collection('posts')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .listen((snap) {
      if (mounted) setState(() => _postCount = snap.docs.length);
    });
  }

  Future<void> _changeAvatar() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    final uid = _uid;
    if (uid == null) return;

    try {
      final file = File(picked.path);
      final ref =
          FirebaseStorage.instance.ref('users/$uid/avatar.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'photoUrl': url});
      // Stream listener auto-updates _photoUrl
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update avatar: $e')),
        );
      }
    }
  }

  Future<void> _showEditProfile() async {
    final controller = TextEditingController(text: _username);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Username',
            border: OutlineInputBorder(),
          ),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      final newUsername = controller.text.trim();
      final uid = _uid;
      if (uid == null) return;

      final existing = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: newUsername)
          .get();

      if (existing.docs.isNotEmpty && existing.docs.first.id != uid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username already taken')),
          );
        }
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'username': newUsername});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profile'),
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
      body: Column(
        children: [
          const SizedBox(height: 16),

          // Avatar with camera button overlay
          GestureDetector(
            onTap: _changeAvatar,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundImage: _photoUrl != null && _photoUrl!.isNotEmpty
                      ? NetworkImage(_photoUrl!) as ImageProvider
                      : const AssetImage('assets/images/logo.png'),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.camera_alt,
                        color: theme.colorScheme.surface, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Username
          Text(
            _username.isNotEmpty ? _username : 'User',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statItem(_postCount.toString(), 'posts'),
              const SizedBox(width: 32),
              _statItem(_followingCount.toString(), 'following'),
              const SizedBox(width: 32),
              _statItem(_followersCount.toString(), 'followers'),
            ],
          ),
          const SizedBox(height: 12),

          // Edit profile button
          OutlinedButton(
            onPressed: _showEditProfile,
            style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              side: BorderSide(color: color.withOpacity(0.4)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Edit profile', style: TextStyle(color: color)),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),

          // Tab bar
          TabBar(
            controller: _tabController,
            indicatorColor: color,
            indicatorWeight: 2,
            tabs: [
              Tab(
                child: Text(
                  'Posts',
                  style: TextStyle(
                    color: _selectedIndex == 0 ? color : Colors.grey,
                    fontWeight: _selectedIndex == 0
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              Tab(
                child: Icon(Icons.favorite,
                    color: _selectedIndex == 1 ? Colors.pink : Colors.grey),
              ),
              Tab(
                child: Icon(Icons.bookmark,
                    color: _selectedIndex == 2 ? color : Colors.grey),
              ),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Posts tab
                uid == null
                    ? const SizedBox()
                    : _PostsGrid(
                        stream: FirebaseFirestore.instance
                            .collection('posts')
                            .where('uid', isEqualTo: uid)
                            .snapshots(),
                        emptyLabel: 'No posts yet',
                      ),

                // Liked tab
                uid == null ? const SizedBox() : _LikedGrid(uid: uid),

                // Saved tab — bookmarked posts from Discover
                uid == null ? const SizedBox() : _SavedPostsGrid(uid: uid),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(current: 3),
    );
  }

  Widget _statItem(String count, String label) {
    return Column(
      children: [
        Text(count,
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

// ── Posts grid ────────────────────────────────────────────────────────────────

class _PostsGrid extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final String emptyLabel;

  const _PostsGrid({required this.stream, required this.emptyLabel});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading posts',
                style: TextStyle(color: Colors.grey.shade500)),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        // Sort newest first client-side (avoids composite index requirement)
        final sorted = [...docs]..sort((a, b) {
            final aTime = a.data()['createdAt'] as Timestamp?;
            final bTime = b.data()['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });
        if (sorted.isEmpty) {
          return Center(
            child: Text(emptyLabel,
                style: TextStyle(color: Colors.grey.shade500)),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: sorted.length,
          itemBuilder: (context, index) {
            final imageUrl = sorted[index].data()['imageUrl'] as String?;
            return imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey.shade300))
                : Container(
                    color: Colors.grey.shade300,
                    child:
                        const Icon(Icons.checkroom, color: Colors.grey),
                  );
          },
        );
      },
    );
  }
}

// ── Liked posts grid ──────────────────────────────────────────────────────────

class _LikedGrid extends StatelessWidget {
  final String uid;
  const _LikedGrid({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('likedPosts')
          .orderBy('likedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text('No liked posts yet',
                style: TextStyle(color: Colors.grey.shade500)),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final imageUrl = docs[index].data()['imageUrl'] as String?;
            return imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey.shade300))
                : Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.checkroom, color: Colors.grey),
                  );
          },
        );
      },
    );
  }
}

// ── Saved posts grid ──────────────────────────────────────────────────────────

class _SavedPostsGrid extends StatelessWidget {
  final String uid;
  const _SavedPostsGrid({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('savedPosts')
          .orderBy('savedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text('No saved posts yet',
                style: TextStyle(color: Colors.grey.shade500)),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final imageUrl = docs[index].data()['imageUrl'] as String?;
            return imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey.shade300))
                : Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.bookmark, color: Colors.grey),
                  );
          },
        );
      },
    );
  }
}
