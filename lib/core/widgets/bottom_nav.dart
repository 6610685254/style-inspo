import 'package:flutter/material.dart';
import 'package:ootd_app/features/discover/discover_screen.dart';
import 'package:ootd_app/features/home/home_screen.dart';
import 'package:ootd_app/features/wardrobe/wardrobe_screen.dart';
import '../../features/profile/profile_screen.dart';

class AppBottomNav extends StatelessWidget {
  final int current;
  const AppBottomNav({super.key, required this.current});

  void _onTap(BuildContext context, int index) {
    if (index == current) return;

    Widget page;

    switch (index) {
      case 0:
        page = const HomeScreen();
        break;
      case 1:
        page = const WardrobeScreen();
        break;
      case 2:
        page = const DiscoverScreen();
        break;
      case 3:
        page = const ProfileScreen();
        break;
      default:
        page = const HomeScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: current,
      onTap: (i) => _onTap(context, i),
      backgroundColor: Colors.white,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.checkroom), label: 'Wardrobe'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Discover'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
