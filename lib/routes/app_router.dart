import 'package:flutter/material.dart';

import '../features/home/home_screen.dart';
import '../features/social/social_screen.dart';
import '../features/social/posts_screen.dart';
import '../features/social/posting_screen.dart';
import '../features/wardrobe/wardrobe_screen.dart';
import '../features/wardrobe/add_wardrobe_screen.dart';
import '../features/wardrobe/take_photo_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/theme_screen.dart';
import '../features/settings/language_screen.dart';
import '../features/settings/notification_screen.dart';
import '../features/settings/help_screen.dart';
import '../features/settings/about_screen.dart';

class AppRouter {
  static Map<String, WidgetBuilder> routes = {
    '/': (_) => const HomeScreen(),
    '/social': (_) => const SocialScreen(),
    '/posts': (_) => const PostsScreen(),
    '/posting': (_) => const PostingScreen(),
    '/wardrobe': (_) => const WardrobeScreen(),
    '/wardrobe/add': (_) => const AddWardrobeScreen(),
    '/wardrobe/camera': (_) => const TakePhotoScreen(),
    '/profile': (_) => const ProfileScreen(),
    '/settings': (_) => const SettingsScreen(),
    '/settings/theme': (_) => const ThemeScreen(),
    '/settings/language': (_) => const LanguageScreen(),
    '/settings/notification': (_) => const NotificationScreen(),
    '/settings/help': (_) => const HelpScreen(),
    '/settings/about': (_) => const AboutScreen(),
  };
}
