# Codebase Structure

**Analysis Date:** 2026-04-15

## Directory Layout

```
lib/
├── main.dart                           # App entry, Firebase init, auth gate, theme
├── firebase_options.dart               # Firebase config (auto-generated)
├── asset/
│   └── style_button.dart               # Reusable styled button widget
├── core/
│   ├── theme/
│   │   └── app_theme.dart              # Light/dark theme definitions
│   └── widgets/
│       └── bottom_nav.dart             # Bottom navigation bar with 4 tabs
├── routes/
│   └── app_router.dart                 # Named route definitions
└── features/
    ├── auth/
    │   ├── Login_Screen.dart           # User login screen
    │   ├── Register_Screen.dart        # User registration screen
    │   └── auth_service.dart           # Auth business logic (login, register, logout)
    ├── home/
    │   ├── home_screen.dart            # Main feed (OOTD suggestions + trending posts)
    │   └── ootd_menu.dart              # Drawer menu with settings/logout
    ├── discover/
    │   ├── discover_screen.dart        # Social feed (all posts grid)
    │   ├── posting_screen.dart         # Create new post with image/description
    │   ├── post_detail_screen.dart     # Full post view with comments
    │   └── user_profile_screen.dart    # Other user's profile
    ├── wardrobe/
    │   ├── wardrobe_screen.dart        # Wardrobe browsing and management
    │   ├── add_wardrobe_screen.dart    # Add clothing item workflow
    │   ├── take_photo_screen.dart      # Camera capture for clothing photos
    │   ├── stylelab.dart               # AI outfit suggestion generation
    │   └── wardrobe_repository.dart    # Wardrobe/clothing CRUD operations
    ├── planner/
    │   └── planner_screen.dart         # Weekly outfit planning (7 day tabs)
    ├── profile/
    │   └── profile_screen.dart         # User profile with posts, followers, stats
    └── settings/
        ├── settings_screen.dart        # Settings hub
        ├── theme_screen.dart           # Light/dark theme toggle
        ├── language_screen.dart        # Language selection
        ├── notification_screen.dart    # Push notification settings
        ├── help_screen.dart            # FAQs and support
        └── about_screen.dart           # App version and credits
```

## Directory Purposes

**lib/asset/:**
- Purpose: Custom reusable assets and components not in core
- Contains: style_button.dart (StyleButton widget for quick actions)
- Key files: `lib/asset/style_button.dart`

**lib/core/:**
- Purpose: Shared, cross-app components and configuration
- Contains: Theme definitions, shared widgets, core utilities
- Key files: `lib/core/theme/app_theme.dart` (ThemeData definitions)

**lib/core/widgets/:**
- Purpose: Reusable UI components used by multiple features
- Contains: AppBottomNav (bottom navigation bar with routing logic)
- Key files: `lib/core/widgets/bottom_nav.dart`

**lib/core/theme/:**
- Purpose: App styling and theming
- Contains: Material 3 themes (light: seed black, dark: grey with custom colors)
- Key files: `lib/core/theme/app_theme.dart`

**lib/routes/:**
- Purpose: Navigation routing configuration
- Contains: Static named route map
- Key files: `lib/routes/app_router.dart` (15+ named routes)

**lib/features/auth/:**
- Purpose: User authentication (login/register/logout)
- Contains: Login/Register screens, AuthService class
- Key files: 
  - `lib/features/auth/Login_Screen.dart` (login UI)
  - `lib/features/auth/Register_Screen.dart` (signup UI)
  - `lib/features/auth/auth_service.dart` (Firebase Auth business logic)

**lib/features/home/:**
- Purpose: Main app hub after login
- Contains: HomeScreen (OOTD + trending posts), OotdMenu (drawer)
- Key files:
  - `lib/features/home/home_screen.dart` (AI outfit suggestions + posts grid)
  - `lib/features/home/ootd_menu.dart` (navigation drawer)

**lib/features/discover/:**
- Purpose: Social discovery and posting
- Contains: Discover feed, post creation, post detail view
- Key files:
  - `lib/features/discover/discover_screen.dart` (all posts grid, 2 columns)
  - `lib/features/discover/posting_screen.dart` (create post with wardrobe/outfit tagging)
  - `lib/features/discover/post_detail_screen.dart` (full post view)
  - `lib/features/discover/user_profile_screen.dart` (other users' profiles)

**lib/features/wardrobe/:**
- Purpose: Personal wardrobe management and AI suggestions
- Contains: Wardrobe CRUD, photo capture, AI suggestion generation
- Key files:
  - `lib/features/wardrobe/wardrobe_screen.dart` (wardrobe browsing, color filtering, categorization)
  - `lib/features/wardrobe/add_wardrobe_screen.dart` (add clothing item flow)
  - `lib/features/wardrobe/take_photo_screen.dart` (camera or gallery picker)
  - `lib/features/wardrobe/stylelab.dart` (AI outfit suggestions via Cloud Functions)
  - `lib/features/wardrobe/wardrobe_repository.dart` (business logic for all above)

**lib/features/planner/:**
- Purpose: Weekly outfit planning
- Contains: StylesPlannerScreen with 7-day tabs
- Key files: `lib/features/planner/planner_screen.dart`

**lib/features/profile/:**
- Purpose: User profile and social stats
- Contains: User profile, post history, avatar management
- Key files: `lib/features/profile/profile_screen.dart`

**lib/features/settings/:**
- Purpose: App configuration and preferences
- Contains: Theme selection, language, notifications, help
- Key files:
  - `lib/features/settings/settings_screen.dart` (hub screen)
  - `lib/features/settings/theme_screen.dart` (light/dark toggle via main.dart ValueNotifier)
  - `lib/features/settings/language_screen.dart` (language selection)
  - `lib/features/settings/notification_screen.dart` (notification prefs)
  - `lib/features/settings/help_screen.dart` (FAQs)
  - `lib/features/settings/about_screen.dart` (version, credits)

## Key File Locations

**Entry Points:**
- `lib/main.dart`: App initialization, Firebase setup, auth gate, theme management
- `lib/routes/app_router.dart`: All named route definitions

**Authentication:**
- `lib/features/auth/auth_service.dart`: AuthService with login/register/logout
- `lib/features/auth/Login_Screen.dart`: Login UI
- `lib/features/auth/Register_Screen.dart`: Registration UI

**Core UI:**
- `lib/core/widgets/bottom_nav.dart`: Bottom navigation (4 tabs: Home, Wardrobe, Discover, Profile)
- `lib/core/theme/app_theme.dart`: Material 3 theme definitions (light + dark)

**Home/Discovery:**
- `lib/features/home/home_screen.dart`: Main hub with AI suggestions and trending posts
- `lib/features/discover/discover_screen.dart`: Social feed (all posts, 2-column grid)
- `lib/features/discover/posting_screen.dart`: Create post with tagging

**Wardrobe Management:**
- `lib/features/wardrobe/wardrobe_screen.dart`: Clothing inventory with color/type filtering
- `lib/features/wardrobe/wardrobe_repository.dart`: CRUD for clothes, suggestions, saved outfits
- `lib/features/wardrobe/stylelab.dart`: AI outfit generation UI

**User Profile:**
- `lib/features/profile/profile_screen.dart`: User profile with avatar, stats, posts
- `lib/features/settings/settings_screen.dart`: App settings hub

## Naming Conventions

**Files:**
- PascalCase for screen files: `LoginPage.dart`, `HomeScreen.dart`, `PostingScreen.dart`
- snake_case for non-screen files: `auth_service.dart`, `wardrobe_repository.dart`, `bottom_nav.dart`, `app_theme.dart`, `app_router.dart`
- EXCEPTION: Some screens use PascalCase inconsistently (e.g., `Login_Screen.dart` with underscore)

**Directories:**
- all lowercase, no underscores: `features/`, `wardrobe/`, `discover/`, `auth/`, `home/`, `planner/`, `profile/`, `settings/`, `core/`

**Classes:**
- PascalCase: `HomeScreen`, `WardrobeScreen`, `AuthService`, `WardrobeRepository`, `AppTheme`, `AppRouter`, `AppBottomNav`

**Functions/Methods:**
- camelCase: `login()`, `register()`, `createClothingItem()`, `watchClothes()`, `generateAIOutfit()`, `updateClothingItem()`
- Private methods with underscore prefix: `_onTap()`, `_snack()`, `_loadUsername()`, `_generateSuggestion()`

**Variables:**
- camelCase: `imageUrl`, `selectedColorIndex`, `wardrobeItems`, `isLoading`, `currentUser`
- Private variables with underscore prefix: `_imageFile`, `_descController`, `_selectedWardrobe`, `_uid`
- Constants in UPPER_SNAKE_CASE when applicable (colors, numbers): `Colors.black`, `FieldValue.serverTimestamp()`

**Types/Generics:**
- PascalCase: `QueryDocumentSnapshot<Map<String, dynamic>>`, `StreamBuilder<User?>`, `FutureBuilder<String?>`

## Where to Add New Code

**New Feature (e.g., Reviews, Comments):**
- Primary code: `lib/features/{feature_name}/{feature_name}_screen.dart`
- Repository/service: `lib/features/{feature_name}/{feature_name}_service.dart` (if complex business logic)
- Routes: Add to `lib/routes/app_router.dart` in routes map

**New Component/Widget (reusable across features):**
- Implementation: `lib/core/widgets/{widget_name}.dart` (if truly shared)
- OR: `lib/asset/{widget_name}.dart` (for app-specific components like StyleButton)
- Import: Use `import '../../core/widgets/{widget_name}.dart'` (relative from feature)

**New Screen in Existing Feature (e.g., another settings screen):**
- Implementation: `lib/features/{feature}/{feature}_{screen_name}_screen.dart`
- Route: Add named route in `lib/routes/app_router.dart`
- Navigation: Use `Navigator.pushNamed(context, '/route-name')`

**Utilities/Helpers:**
- General utilities: `lib/core/utils/` (create if needed)
- Feature-specific helpers: In same folder as feature or as static methods in service class

**Theme/Styling Extensions:**
- Add to: `lib/core/theme/app_theme.dart` or create `lib/core/theme/app_extensions.dart`

**Firebase Data Models (Firestore serialization):**
- NOT currently used — Firestore data accessed as Map<String, dynamic> throughout
- If adding typed models: Create `lib/models/{model_name}.dart` with fromJson/toJson methods

## Special Directories

**lib/asset/:**
- Purpose: App-specific assets (not Flutter asset folder)
- Generated: No
- Committed: Yes
- Contains: Custom widgets like StyleButton

**lib/routes/:**
- Purpose: Navigation routing
- Generated: No
- Committed: Yes
- Contains: AppRouter static route map

**pubspec.yaml (root):**
- Purpose: Flutter dependency management
- Generated: Partially (lockfile)
- Committed: Yes
- Key entry: assets section lists image files (logo.png, image.png)

## Import Patterns

**Absolute imports (recommended):**
```dart
import 'package:ootd_app/features/wardrobe/wardrobe_repository.dart';
import 'package:firebase_core/firebase_core.dart';
```

**Relative imports (used in screens):**
```dart
import '../../core/widgets/bottom_nav.dart';
import '../auth/auth_service.dart';
```

**Firebase imports (standard):**
```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
```

**Flutter imports:**
```dart
import 'package:flutter/material.dart';
```

## Code Organization Within Files

**Screen files (Stateless/Stateful):**
1. Imports at top
2. Class declaration
3. Override build() method
4. Helper methods and widgets at bottom (with underscore prefix for private)
5. Example: HomeScreen, WardrobeScreen, PostingScreen

**Service/Repository files:**
1. Imports
2. Class declaration with constructor
3. Private fields (Firebase instances)
4. Getter methods
5. Public methods (alphabetical or logical order)
6. Private helper methods
7. Example: AuthService, WardrobeRepository

**Theme files:**
1. Imports
2. Class with static properties only
3. Example: AppTheme with lightTheme and darkTheme properties

**Router files:**
1. Imports of all screens
2. Class with static routes map
3. Example: AppRouter.routes

## Material 3 Design Implementation

- Uses Material 3 (useMaterial3: true) with seed colors
- Light theme: seed=Colors.black
- Dark theme: seed=Colors.grey with custom surface/onSurface overrides
- ColorScheme used throughout (colorScheme.surface, colorScheme.onSurface, etc.)
- Theme accessed via Theme.of(context) in builds
- GlobalKey references avoided; direct context usage for theming
