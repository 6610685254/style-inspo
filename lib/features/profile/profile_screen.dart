import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });
    _username = widget.username ?? '';
    if (_username.isEmpty) {
      _loadUsername();
    }
  }

  Future<void> _loadUsername() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!doc.exists) return;
      final data = doc.data();
      final name = data != null && data['username'] is String ? data['username'] as String : null;
      if (name != null && mounted) {
        setState(() {
          _username = name;
        });
      }
    } catch (_) {
      // ignore errors and keep default username
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
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

      body: Column(
        children: [
          const SizedBox(height: 20),

          Text(
            _username.isNotEmpty ? _username : 'User',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          const CircleAvatar(
            radius: 45,
            backgroundImage: AssetImage("assets/images/logo.png"),
          ),

          const SizedBox(height: 8),

          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit, size: 16),
            label: const Text("Edit profile"),
          ),

          const Divider(),

          //Tab Bar
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.transparent,
            tabs: [
              Tab(
                child: Text(
                  "post",
                  style: TextStyle(
                    color: _selectedIndex == 0 ? Colors.blue : Colors.grey,
                  ),
                ),
              ),
              Tab(
                child: Icon(
                  Icons.favorite,
                  color: _selectedIndex == 1 ? Colors.pink : Colors.grey,
                ),
              ),
              Tab(
                child: Icon(
                  Icons.bookmark,
                  color: _selectedIndex == 2 ? Colors.blue : Colors.grey,
                ),
              ),
            ],
          ),

          //Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [buildGrid(), buildGrid(), buildGrid()],
            ),
          ),
        ],
      ),

      bottomNavigationBar: const AppBottomNav(current: 3),
    );
  }

  Widget buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 9,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}
