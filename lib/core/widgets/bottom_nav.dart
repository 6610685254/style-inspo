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
    final bool hasSelection = current >= 0 && current <= 3;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(
            color: colors.outline.withOpacity(0.5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: hasSelection ? current : 0,
        onTap: (i) => _onTap(context, i),
        backgroundColor: colors.surface,
        selectedItemColor: hasSelection
            ? colors.onSurface
            : colors.onSurface.withOpacity(0.55),
        unselectedItemColor: colors.onSurface.withOpacity(0.55),
        selectedLabelStyle: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: colors.onSurface.withOpacity(0.55),
        ),
        selectedIconTheme: IconThemeData(
          size: 23,
          color: hasSelection
              ? colors.onSurface
              : colors.onSurface.withOpacity(0.55),
        ),
        unselectedIconTheme: IconThemeData(
          size: 21,
          color: colors.onSurface.withOpacity(0.55),
        ),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.checkroom_rounded), label: 'Wardrobe'),
          BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
