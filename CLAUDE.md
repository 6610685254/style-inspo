<!-- GSD:project-start source:PROJECT.md -->
## Project

**OOTD — Outfit Of Today**

A Flutter social fashion app where users build a digital wardrobe, get AI-generated outfit suggestions via Gemini, and share their daily looks with a community feed. Built with Firebase (Auth, Firestore, Storage, Cloud Functions) and Genkit for AI outfit generation. Primary platform is Android, with iOS/Web support.

**Core Value:** Users can get a daily AI outfit suggestion from their own wardrobe and share it with the community.

### Constraints

- **Tech stack:** Flutter + Dart — must stay within existing stack
- **Backend:** Firebase only — no additional backend services
- **Timeline:** A few weeks
- **Scope:** Polish and fix existing features — no major new features this milestone
<!-- GSD:project-end -->

<!-- GSD:stack-start source:codebase/STACK.md -->
## Technology Stack

## Languages
- Dart 3.10.8+ - Flutter application code in `lib/` directory
- TypeScript 5.7.3 - Cloud Functions backend in `functions/src/`
- Kotlin 17 - Android native code in `android/`
- Gradle Kotlin DSL - Android build configuration in `android/build.gradle.kts` and `android/app/build.gradle.kts`
## Runtime
- Flutter SDK (latest) - Mobile and web application framework
- Node.js 24 - Cloud Functions runtime
- `pub` / `pubspec.yaml` - Dart dependencies
- `npm` - Node.js dependencies for Firebase Functions
## Frameworks
- Flutter 3.x - Cross-platform mobile framework for iOS/Android/Web
- Firebase (multi-product) - Backend services suite
- Google AI (Genkit) 1.28.0 - AI model integration for outfit generation
- flutter_test SDK - Built-in Flutter testing framework
- Flutter Gradle Plugin - Android build integration
- TypeScript compiler - Cloud Functions transpilation
- Firebase CLI - Local emulation and deployment (`firebase emulators:start --only functions`)
## Key Dependencies
- `firebase_core` 4.6.0 - Firebase initialization
- `firebase_auth` 6.3.0 - User authentication
- `cloud_firestore` 6.2.0 - NoSQL database (core data store)
- `cloud_functions` 6.1.0 - Firebase Functions integration
- `firebase_storage` 13.2.0 - Image and file storage
- `genkit` 1.28.0 - Google's generative AI framework
- `@genkit-ai/googleai` 1.28.0 - Google AI plugin (Gemini integration)
- `@genkit-ai/ai` 1.28.0 - AI capabilities core
- `@genkit-ai/flow` 0.5.17 - Workflow orchestration
- `firebase-admin` 13.6.1 - Server-side Firebase access in Cloud Functions
- `firebase-functions` 7.0.0 - Firebase Functions SDK
- `image_picker` 1.1.1 - Device camera and gallery access
- `uuid` 4.5.2 - Unique identifier generation
- `zod` 4.3.6 - TypeScript schema validation for AI responses
- `cupertino_icons` 1.0.8 - iOS-style icon font
- `flutter_lints` 6.0.0 - Recommended Flutter lint rules
- `eslint` 8.9.0 - JavaScript/TypeScript linting
- `@typescript-eslint/eslint-plugin` 5.12.0 - TypeScript linting
- `firebase-functions-test` 3.4.1 - Cloud Functions testing utilities
## Configuration
- `firebase.json` - Firebase project configuration (hosted at `cn333-8e548`)
- `lib/firebase_options.dart` - Platform-specific Firebase initialization keys for Android, iOS, macOS, Windows, Web
- Google Services JSON - `android/app/google-services.json` (generated, auto-configured)
- Google AI API Key - Stored as Firebase Function secret `GOOGLE_GENAI_API_KEY`
- No `.env` file in repository - All secrets managed through Firebase secrets and Google Cloud Secret Manager
- `pubspec.yaml` - Main Flutter app manifest (version 1.0.0+1)
- `android/build.gradle.kts` - Root Gradle configuration
- `android/app/build.gradle.kts` - App-level build configuration
- `functions/package.json` - Cloud Functions Node.js configuration
- `functions/tsconfig.json` - TypeScript compilation settings for backend
## Platform Requirements
- Flutter SDK (latest)
- Android Studio / Android SDK (for Android builds)
- Node.js 24+ (for Cloud Functions)
- Firebase CLI (for local testing and deployment)
- Android 5.0+ (API 21+) - via `flutter.minSdkVersion`
- iOS 11.0+ (via Xcode configuration)
- Firebase Cloud (hosted backend)
- Google Cloud Platform (for Cloud Functions and Genkit)
## Multi-Platform Support
- **Android** - Primary platform with `compileSdk = flutter.compileSdkVersion`, Java 17 compatibility
- **iOS** - Supported via Xcode configuration in `ios/` directory
- **Web** - Flutter Web support configured in `firebase.json` with SPA hosting rewrites
- **macOS** - Desktop support available
- **Windows** - Desktop support available
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

## Naming Patterns
- PascalCase for screen/page files: `Login_Screen.dart`, `PostDetailScreen.dart`, `RegisterScreen.dart`
- snake_case for service/utility files: `auth_service.dart`, `wardrobe_repository.dart`
- No enforced pattern - mixed usage present
- PascalCase for all public classes: `LoginPage`, `PostDetailScreen`, `PostingScreen`
- Prefix with underscore for private State classes: `_LoginPageState`, `_PostDetailScreenState`, `_PostingScreenState`
- Prefix with underscore for private widget classes: `_EditPostSheet`, `_ItemGrid`, `_PostsGrid`, `_ThemeOption`
- camelCase for public methods: `build()`, `handleLogin()`, `toggleLike()`
- Prefix with underscore for private methods: `_handleLogin()`, `_toggleLike()`, `_checkLiked()`, `_streamAuthor()`
- Private async methods use underscore prefix: `_uploadImage()`, `_pickImage()`, `_post()`, `_checkSaved()`
- Single-letter callback parameter abbreviations common: `builder: (_, mode, __) =>` in `ValueListenableBuilder`
- camelCase for local and member variables: `_isLoading`, `_errorMessage`, `_inputController`, `_selectedWardrobe`
- Prefix with underscore for private fields: `_imageFile`, `_authorData`, `_postData`, `_commentController`
- Boolean flags use `_is` or `_has` prefix: `_isLoading`, `_isPosting`, `_isOwner`, `_liked`, `_saved`
- Getter/setter style: `String? get _uid => FirebaseAuth.instance.currentUser?.uid;`
- PascalCase for custom types and generics: `Future<User?>`, `Map<String, dynamic>`, `List<String>`
- Type casting with `as` pattern: `(userDoc.data()?['username'] as String?) ?? 'User'`
## Code Style
- 2-space indentation (Flutter default)
- Line length not explicitly enforced but generally under 100 characters
- Consistent spacing around operators and after keywords
- Constructor parameters use `required` keyword with named parameters
- Uses `flutter_lints: ^6.0.0` as defined in `pubspec.yaml`
- Includes `package:flutter_lints/flutter.yaml` in `analysis_options.yaml`
- Minimal custom rule overrides (most rules remain at defaults)
- No strict `prefer_single_quotes` or `avoid_print` enforcement visible
## Import Organization
- No path aliases configured (using relative imports exclusively)
- Import paths use `../../` and `../` for navigation
## Error Handling
- Try-catch blocks with specific exception handling: `on FirebaseAuthException catch (e)`
- Catch-all fallback: `catch (_)` or `catch (e)` for general exceptions
- Empty catch blocks with silent failure: `catch (_) {}` in optimistic update patterns
- Use `mounted` check before `setState()` in async contexts: `if (mounted) setState(...)`
- Use `mounted` check before navigation: `if (mounted) Navigator.pop(context)`
## Logging
- User-facing errors via `ScaffoldMessenger.of(context).showSnackBar()`
- Helper method `_snack()` used in some screens for repeated snack bar display
- Error messages concatenated directly into UI text: `'Error: $e'`
## Comments
- Section dividers for major code blocks (common in large screens)
- Clarifying non-obvious field purposes: `// Multi-select wardrobe items: doc id -> label`
- Marking data structure migrations: `// Store as lists now`, `// Support both old (single string) and new (list) format`
- Implementation examples in widget/utility files
- Minimal use of doc comments (`///`)
- Found mainly in main.dart for global state: `/// Global theme notifier — write to this from ThemeScreen to change theme.`
- No systematic documentation of public APIs
## Function Design
- Named parameters with `required` keyword: `required this.postId`
- Consistent use of `{super.key}` in constructors
- Widget state classes pass data via constructor parameters
- Explicit type declarations: `Future<void>`, `Future<String?>`, `Future<User?>`
- Null-coalescing for optional values: `(userDoc.data()?['username'] as String?) ?? 'User'`
- Inline type casts with null safety: `as String?` patterns
- Empty lists/maps as defaults: `widget.data?['items'] ?? []`
## Module Design
- No barrel files (index.dart) used
- Direct imports of individual classes/services
- Not used in this codebase
- Each file imports the specific class it needs
- Direct `setState()` for local state in StatefulWidget screens
- `FirebaseAuth.instance` accessed directly throughout app
- `FirebaseFirestore.instance` accessed directly for queries
- Global `ValueNotifier<ThemeMode>` for theme state: `final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);`
- `StreamBuilder` for Firebase real-time data: `StreamBuilder<QuerySnapshot<Map<String, dynamic>>>`
## Theme-Aware Colors
- Heavy use of `Theme.of(context)` to access theme colors
- Direct color references for specific branding: `Colors.black`, `Colors.red`
- Theme-aware approach: `theme.colorScheme.onSurface`, `theme.colorScheme.surface`
- Fallback colors for error states: `Colors.grey.shade300` for missing images
## Stream and Async Patterns
- Commonly used for real-time Firebase data
- Pattern: `StreamBuilder<QuerySnapshot<Map<String, dynamic>>>`
- Listener streams attached in `initState()` for state updates
- Manual stream listeners with `FirebaseFirestore.instance.collection(...).snapshots().listen()`
- State changed immediately via `setState()` before async operation completes
- Async operation runs in background
- On error, state may be silently rolled back with `catch (_) {}`
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

## Pattern Overview
- Feature-driven modular structure (auth, discover, wardrobe, planner, profile, home, settings)
- Direct Firebase service integration throughout features (no repository abstraction layer in most screens)
- StreamBuilder-based reactive UI with Firestore real-time listeners
- Single entry point routing through named routes (AppRouter)
- Centralized theme management via ValueNotifier pattern
## Layers
- Purpose: Flutter widgets and screens for user interaction
- Location: `lib/features/*/`
- Contains: Stateless/Stateful widgets, screens, UI components
- Depends on: Firebase Auth, Firestore, Cloud Functions, Cloud Storage
- Used by: Main app entry point, app router
- Purpose: Handle data operations and API interactions
- Location: `lib/features/auth/auth_service.dart`, `lib/features/wardrobe/wardrobe_repository.dart`
- Contains: AuthService (auth), WardrobeRepository (wardrobe operations)
- Depends on: Firebase Admin SDKs (Auth, Firestore, Storage, Cloud Functions)
- Used by: Auth screens (Login, Register), Wardrobe features, StyleLab
- Purpose: Reusable widgets, theme configuration, global utilities
- Location: `lib/core/`
- Contains: Bottom navigation, app theme, shared widgets
- Depends on: Flutter Material
- Used by: All screens via imports
- Purpose: Named route navigation configuration
- Location: `lib/routes/app_router.dart`
- Contains: Static route map definition
- Depends on: All feature screens
- Used by: Navigation in main.dart and screens via Navigator.pushNamed()
## Data Flow
- **Theme State:** Global ValueNotifier<ThemeMode> in main.dart — updated from SettingsScreen
- **Authentication State:** Firebase Auth state stream in main.dart
- **Feature State:** Local widget state via setState() in Stateful widgets
- **Data State:** Firestore streams via StreamBuilder (reactive, real-time updates)
- **Temporary State:** TextEditingControllers, Map<String, String> selections in stateful widgets
## Key Abstractions
- Purpose: Handle user login, registration, logout operations
- Examples: `lib/features/auth/auth_service.dart`
- Pattern: Singleton-like service with Firebase Auth and Firestore integration
- Methods: login(email/username), register(username/email/password), logout(), authState property
- Purpose: Manage wardrobe items, suggestions, and saved outfits CRUD operations
- Examples: `lib/features/wardrobe/wardrobe_repository.dart`
- Pattern: Repository pattern with dependency injection (accepts optional Firestore/Auth instances for testing)
- Methods: 
- FirebaseAuth.instance — Direct access throughout for current user UID
- FirebaseFirestore.instance — Direct collection queries in screens
- FirebaseStorage.instance — Image uploads in PostingScreen, ProfileScreen
- FirebaseFunctions.instance — Cloud Function calls for AI outfit generation
## Entry Points
- Location: `lib/main.dart`
- Triggers: App launch
- Responsibilities: 
- Location: `lib/core/widgets/bottom_nav.dart`
- Triggers: Tab taps on AppBottomNav
- Responsibilities:
- HomeScreen (`lib/features/home/home_screen.dart`) — Entry after auth, displays OOTD suggestions and trending posts
- WardrobeScreen (`lib/features/wardrobe/wardrobe_screen.dart`) — Wardrobe management and browsing
- DiscoverScreen (`lib/features/discover/discover_screen.dart`) — Social feed of community posts
- ProfileScreen (`lib/features/profile/profile_screen.dart`) — User profile and stats
- SettingsScreen (`lib/features/settings/settings_screen.dart`) — App preferences
## Error Handling
- FirebaseAuthException handling in AuthService — thrown with custom messages (user-not-found, username-taken)
- FirebaseFunctionsException handling in StyleLabScreen — caught and displayed via SnackBar
- Image upload errors in PostingScreen, ProfileScreen — caught and shown via SnackBar
- Stream errors: Handled implicitly by StreamBuilder connectionState checks
- Firestore access errors: Null-coalescing in UI (show placeholders if no data)
## Cross-Cutting Concerns
- Auth fields: Email/username format checked in AuthService before Firebase call
- Image selection: Null checks in PostingScreen, ProfileScreen
- Wardrobe filters: Color name to Color mapping via _nameToColor() in wardrobe_screen.dart
- Firestore data: Null-coalescing and type casting with default values (data['field'] as Type? ?? defaultValue)
- Guarded via FirebaseAuth.instance.currentUser?.uid null checks throughout
- Auth state monitored in main.dart StreamBuilder
- Logout handled in OotdMenu with full navigation reset
- Session managed entirely by Firebase Auth
- image_picker for gallery/camera selection
- Firebase Storage for uploads with user-scoped paths (`users/{uid}/avatar.jpg`, `posts/{uid}/{filename}`)
- Network error handling via Image.network errorBuilder
- Placeholder widgets shown for missing/failed images
<!-- GSD:architecture-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd:quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd:debug` for investigation and bug fixing
- `/gsd:execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd:profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
