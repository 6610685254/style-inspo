# Architecture

**Analysis Date:** 2026-04-15

## Pattern Overview

**Overall:** Feature-based Clean Architecture with Firebase backend integration

**Key Characteristics:**
- Feature-driven modular structure (auth, discover, wardrobe, planner, profile, home, settings)
- Direct Firebase service integration throughout features (no repository abstraction layer in most screens)
- StreamBuilder-based reactive UI with Firestore real-time listeners
- Single entry point routing through named routes (AppRouter)
- Centralized theme management via ValueNotifier pattern

## Layers

**Presentation (UI/Screens):**
- Purpose: Flutter widgets and screens for user interaction
- Location: `lib/features/*/`
- Contains: Stateless/Stateful widgets, screens, UI components
- Depends on: Firebase Auth, Firestore, Cloud Functions, Cloud Storage
- Used by: Main app entry point, app router

**Business Logic/Service:**
- Purpose: Handle data operations and API interactions
- Location: `lib/features/auth/auth_service.dart`, `lib/features/wardrobe/wardrobe_repository.dart`
- Contains: AuthService (auth), WardrobeRepository (wardrobe operations)
- Depends on: Firebase Admin SDKs (Auth, Firestore, Storage, Cloud Functions)
- Used by: Auth screens (Login, Register), Wardrobe features, StyleLab

**Core/Shared:**
- Purpose: Reusable widgets, theme configuration, global utilities
- Location: `lib/core/`
- Contains: Bottom navigation, app theme, shared widgets
- Depends on: Flutter Material
- Used by: All screens via imports

**Routing:**
- Purpose: Named route navigation configuration
- Location: `lib/routes/app_router.dart`
- Contains: Static route map definition
- Depends on: All feature screens
- Used by: Navigation in main.dart and screens via Navigator.pushNamed()

## Data Flow

**Authentication Flow:**

1. User enters credentials on LoginPage (`lib/features/auth/Login_Screen.dart`)
2. AuthService.login() called — checks username/email, signs in with Firebase Auth
3. Firebase Auth state emits new User object
4. main.dart StreamBuilder<User?> detects authStateChanges()
5. If authenticated: HomeScreen displayed; if not: LoginPage displayed
6. User data (username, photoUrl, stats) cached in Firestore users/{uid} document

**Wardrobe/Clothing Management Flow:**

1. User taps FAB on WardrobeScreen (`lib/features/wardrobe/wardrobe_screen.dart`)
2. Navigates to AddWardrobeScreen → TakePhotoScreen (camera) or gallery picker
3. Image uploaded to Firebase Storage at `posts/{uid}/{filename}`
4. WardrobeRepository.addClothingItem() creates doc in `users/{uid}/clothes/{docId}`
5. WardrobeScreen watches `_repository.watchClothes()` (Firestore stream)
6. Items grouped by type and filtered by color in UI
7. Edit/delete operations update/remove documents in same collection

**AI Outfit Generation Flow:**

1. User taps "Suggest new" on HomeScreen or StyleLab (StyleLabScreen)
2. StyleLabScreen._generateSuggestion() calls Cloud Function: `generateOutfitSuggestion`
3. Cloud Function uses Genkit + Gemini to analyze wardrobe and suggest outfit
4. Returns: title, clothingIds, reasoning (in Map<String, dynamic>)
5. WardrobeRepository.createSuggestion() saves suggestion to `users/{uid}/suggestions/{docId}`
6. Suggestion data includes: title, clothingIds, generatedBy, confidence, status
7. HomeScreen displays latest suggestion with images fetched from `users/{uid}/clothes/{id}`

**Post Creation Flow:**

1. User taps FAB on DiscoverScreen → navigates to PostingScreen
2. User picks image, writes description, multi-selects wardrobe items and saved outfits
3. PostingScreen._pickImage() uses image_picker to get gallery image
4. PostingScreen._uploadImage() uploads to Firebase Storage at `posts/{uid}/{timestamp}.jpg`
5. PostingScreen._post() creates doc in global `posts/{docId}` collection with:
   - uid, username, photoUrl, imageUrl, description
   - wardrobeItemIds, wardrobeItems (selected items)
   - savedOutfitIds, savedOutfits (selected outfits)
   - createdAt timestamp, likes counter
6. DiscoverScreen/HomeScreen watch `posts` collection and render as grids
7. PostDetailScreen shows full post details

**State Management:**

- **Theme State:** Global ValueNotifier<ThemeMode> in main.dart — updated from SettingsScreen
- **Authentication State:** Firebase Auth state stream in main.dart
- **Feature State:** Local widget state via setState() in Stateful widgets
- **Data State:** Firestore streams via StreamBuilder (reactive, real-time updates)
- **Temporary State:** TextEditingControllers, Map<String, String> selections in stateful widgets

## Key Abstractions

**AuthService:**
- Purpose: Handle user login, registration, logout operations
- Examples: `lib/features/auth/auth_service.dart`
- Pattern: Singleton-like service with Firebase Auth and Firestore integration
- Methods: login(email/username), register(username/email/password), logout(), authState property

**WardrobeRepository:**
- Purpose: Manage wardrobe items, suggestions, and saved outfits CRUD operations
- Examples: `lib/features/wardrobe/wardrobe_repository.dart`
- Pattern: Repository pattern with dependency injection (accepts optional Firestore/Auth instances for testing)
- Methods: 
  - watchClothes() — returns Stream of clothing items
  - createClothingItem() — add new item
  - updateClothingItem() — edit existing item
  - deleteClothingItem() — remove item
  - watchSuggestions() — stream of AI suggestions
  - generateAIOutfit() — call Cloud Function for outfit generation
  - saveSuggestedOutfit() — persist suggestion as saved outfit

**Firebase Integration Points:**
- FirebaseAuth.instance — Direct access throughout for current user UID
- FirebaseFirestore.instance — Direct collection queries in screens
- FirebaseStorage.instance — Image uploads in PostingScreen, ProfileScreen
- FirebaseFunctions.instance — Cloud Function calls for AI outfit generation

## Entry Points

**Application Entry:**
- Location: `lib/main.dart`
- Triggers: App launch
- Responsibilities: 
  - Initialize Firebase with DefaultFirebaseOptions
  - Create MyApp MaterialApp with theme management
  - Set up authentication gate via StreamBuilder<User?>
  - Show LoginPage if not authenticated, HomeScreen if authenticated

**Bottom Navigation:**
- Location: `lib/core/widgets/bottom_nav.dart`
- Triggers: Tab taps on AppBottomNav
- Responsibilities:
  - Track current tab index (Home=0, Wardrobe=1, Discover=2, Profile=3)
  - Navigate via Navigator.pushReplacement to prevent stacking
  - Highlight active tab indicator

**Feature Screens:**
- HomeScreen (`lib/features/home/home_screen.dart`) — Entry after auth, displays OOTD suggestions and trending posts
- WardrobeScreen (`lib/features/wardrobe/wardrobe_screen.dart`) — Wardrobe management and browsing
- DiscoverScreen (`lib/features/discover/discover_screen.dart`) — Social feed of community posts
- ProfileScreen (`lib/features/profile/profile_screen.dart`) — User profile and stats
- SettingsScreen (`lib/features/settings/settings_screen.dart`) — App preferences

## Error Handling

**Strategy:** Try-catch with SnackBar notifications, exception propagation in services

**Patterns:**
- FirebaseAuthException handling in AuthService — thrown with custom messages (user-not-found, username-taken)
- FirebaseFunctionsException handling in StyleLabScreen — caught and displayed via SnackBar
- Image upload errors in PostingScreen, ProfileScreen — caught and shown via SnackBar
- Stream errors: Handled implicitly by StreamBuilder connectionState checks
- Firestore access errors: Null-coalescing in UI (show placeholders if no data)

## Cross-Cutting Concerns

**Logging:** print() statements scattered throughout (e.g., "Genkit Error: $e" in wardrobe_repository.dart) — no structured logging framework

**Validation:**
- Auth fields: Email/username format checked in AuthService before Firebase call
- Image selection: Null checks in PostingScreen, ProfileScreen
- Wardrobe filters: Color name to Color mapping via _nameToColor() in wardrobe_screen.dart
- Firestore data: Null-coalescing and type casting with default values (data['field'] as Type? ?? defaultValue)

**Authentication:**
- Guarded via FirebaseAuth.instance.currentUser?.uid null checks throughout
- Auth state monitored in main.dart StreamBuilder
- Logout handled in OotdMenu with full navigation reset
- Session managed entirely by Firebase Auth

**Image Handling:**
- image_picker for gallery/camera selection
- Firebase Storage for uploads with user-scoped paths (`users/{uid}/avatar.jpg`, `posts/{uid}/{filename}`)
- Network error handling via Image.network errorBuilder
- Placeholder widgets shown for missing/failed images
