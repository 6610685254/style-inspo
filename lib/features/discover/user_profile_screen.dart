import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String username;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _following = false;
  bool _loading = true;
  Map<String, dynamic>? _userData;

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = _currentUid;
    if (uid == null) return;

    final results = await Future.wait([
      FirebaseFirestore.instance.collection('users').doc(widget.userId).get(),
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('following')
          .doc(widget.userId)
          .get(),
    ]);

    final userDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final followDoc = results[1] as DocumentSnapshot<Map<String, dynamic>>;

    if (mounted) {
      setState(() {
        _userData = userDoc.data();
        _following = followDoc.exists;
        _loading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final uid = _currentUid;
    if (uid == null) return;

    final myFollowingRef = FirebaseFirestore.instance
        .collection('users').doc(uid).collection('following').doc(widget.userId);
    final theirFollowersRef = FirebaseFirestore.instance
        .collection('users').doc(widget.userId).collection('followers').doc(uid);
    final myDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    final theirDoc =
        FirebaseFirestore.instance.collection('users').doc(widget.userId);

    if (_following) {
      await myFollowingRef.delete();
      await theirFollowersRef.delete();
      await myDoc.update({'following': FieldValue.increment(-1)});
      await theirDoc.update({'followers': FieldValue.increment(-1)});
      setState(() => _following = false);
    } else {
      await myFollowingRef.set({'followedAt': FieldValue.serverTimestamp()});
      await theirFollowersRef.set({'followedAt': FieldValue.serverTimestamp()});
      await myDoc.update({'following': FieldValue.increment(1)});
      await theirDoc.update({'followers': FieldValue.increment(1)});
      setState(() => _following = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photoUrl = (_userData?['photoUrl'] as String?) ?? '';
    final username = (_userData?['username'] as String?) ?? widget.username;
    final followers = (_userData?['followers'] as int?) ?? 0;
    final following = (_userData?['following'] as int?) ?? 0;
    final isMe = _currentUid == widget.userId;

    return Scaffold(
      appBar: AppBar(title: Text(username)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 44,
                  backgroundImage: photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl.isEmpty
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
                const SizedBox(height: 10),
                Text(
                  username,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _statItem(following.toString(), 'following'),
                    const SizedBox(width: 32),
                    _statItem(followers.toString(), 'followers'),
                  ],
                ),
                const SizedBox(height: 12),
                if (!isMe)
                  ElevatedButton(
                    onPressed: _toggleFollow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _following ? theme.colorScheme.surfaceContainerHighest : Colors.black,
                      foregroundColor: _following ? theme.colorScheme.onSurface : Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 48, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(_following ? 'Following' : 'Follow'),
                  ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .where('uid', isEqualTo: widget.userId)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Center(
                          child: Text('No posts yet.',
                              style: TextStyle(
                                  color: Colors.grey.shade500)),
                        );
                      }
                      return GridView.builder(
                        padding: const EdgeInsets.all(2),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final imageUrl =
                              docs[i].data()['imageUrl'] as String?;
                          return imageUrl != null && imageUrl.isNotEmpty
                              ? Image.network(imageUrl, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                      color: Colors.grey.shade300))
                              : Container(
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.checkroom,
                                      color: Colors.grey),
                                );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _statItem(String count, String label) {
    return Column(
      children: [
        Text(count,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
