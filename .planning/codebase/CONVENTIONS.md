# Coding Conventions

**Analysis Date:** 2026-04-15

## Naming Patterns

**Files:**
- PascalCase for screen/page files: `Login_Screen.dart`, `PostDetailScreen.dart`, `RegisterScreen.dart`
- snake_case for service/utility files: `auth_service.dart`, `wardrobe_repository.dart`
- No enforced pattern - mixed usage present

**Classes:**
- PascalCase for all public classes: `LoginPage`, `PostDetailScreen`, `PostingScreen`
- Prefix with underscore for private State classes: `_LoginPageState`, `_PostDetailScreenState`, `_PostingScreenState`
- Prefix with underscore for private widget classes: `_EditPostSheet`, `_ItemGrid`, `_PostsGrid`, `_ThemeOption`

**Functions:**
- camelCase for public methods: `build()`, `handleLogin()`, `toggleLike()`
- Prefix with underscore for private methods: `_handleLogin()`, `_toggleLike()`, `_checkLiked()`, `_streamAuthor()`
- Private async methods use underscore prefix: `_uploadImage()`, `_pickImage()`, `_post()`, `_checkSaved()`
- Single-letter callback parameter abbreviations common: `builder: (_, mode, __) =>` in `ValueListenableBuilder`

**Variables:**
- camelCase for local and member variables: `_isLoading`, `_errorMessage`, `_inputController`, `_selectedWardrobe`
- Prefix with underscore for private fields: `_imageFile`, `_authorData`, `_postData`, `_commentController`
- Boolean flags use `_is` or `_has` prefix: `_isLoading`, `_isPosting`, `_isOwner`, `_liked`, `_saved`
- Getter/setter style: `String? get _uid => FirebaseAuth.instance.currentUser?.uid;`

**Types:**
- PascalCase for custom types and generics: `Future<User?>`, `Map<String, dynamic>`, `List<String>`
- Type casting with `as` pattern: `(userDoc.data()?['username'] as String?) ?? 'User'`

## Code Style

**Formatting:**
- 2-space indentation (Flutter default)
- Line length not explicitly enforced but generally under 100 characters
- Consistent spacing around operators and after keywords
- Constructor parameters use `required` keyword with named parameters

**Linting:**
- Uses `flutter_lints: ^6.0.0` as defined in `pubspec.yaml`
- Includes `package:flutter_lints/flutter.yaml` in `analysis_options.yaml`
- Minimal custom rule overrides (most rules remain at defaults)
- No strict `prefer_single_quotes` or `avoid_print` enforcement visible

## Import Organization

**Order:**
1. Dart imports (`import 'dart:...'`)
2. Flutter framework imports (`import 'package:flutter/...'`)
3. Firebase/external package imports (`import 'package:firebase_...`, `import 'package:cloud_firestore...'`)
4. Local relative imports (`import '../...`, `import './...'`)

**Examples from codebase:**
```dart
// LoginPage pattern (lib/features/auth/Login_Screen.dart)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/auth_service.dart';
import 'Register_Screen.dart';
import '../home/home_screen.dart';

// PostDetailScreen pattern (lib/features/discover/post_detail_screen.dart)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_profile_screen.dart';
```

**Path Aliases:**
- No path aliases configured (using relative imports exclusively)
- Import paths use `../../` and `../` for navigation

## Error Handling

**Patterns:**
- Try-catch blocks with specific exception handling: `on FirebaseAuthException catch (e)`
- Catch-all fallback: `catch (_)` or `catch (e)` for general exceptions
- Empty catch blocks with silent failure: `catch (_) {}` in optimistic update patterns
- Use `mounted` check before `setState()` in async contexts: `if (mounted) setState(...)`
- Use `mounted` check before navigation: `if (mounted) Navigator.pop(context)`

**Examples:**
```dart
// Specific exception handling
try {
  await _authService.login(input, password);
  if (mounted) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }
} on FirebaseAuthException catch (e) {
  setState(() {
    _errorMessage = e.message ?? "Login failed";
  });
} catch (_) {
  setState(() {
    _errorMessage = "Something went wrong. Please try again.";
  });
}

// Optimistic UI with silent catch
try {
  await likeRef.delete();
  await userLikeRef.delete();
  await postRef.update({'likes': _likeCount});
} catch (_) {}  // Silent failure - UI already updated optimistically
```

## Logging

**Framework:** `console` and `ScaffoldMessenger` for user-facing messages

**Patterns:**
- User-facing errors via `ScaffoldMessenger.of(context).showSnackBar()`
- Helper method `_snack()` used in some screens for repeated snack bar display
- Error messages concatenated directly into UI text: `'Error: $e'`

**Examples:**
```dart
// From posting_screen.dart
void _snack(String msg) {
  if (!mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));
}

// Usage
_snack('Posted!');
_snack('Upload failed: ${e.code}');
```

## Comments

**When to Comment:**
- Section dividers for major code blocks (common in large screens)
- Clarifying non-obvious field purposes: `// Multi-select wardrobe items: doc id -> label`
- Marking data structure migrations: `// Store as lists now`, `// Support both old (single string) and new (list) format`
- Implementation examples in widget/utility files

**Divider Pattern:**
ASCII-style dividers with descriptive labels:
```dart
// ── Edit post ─────────────────────────────────────────────────────────────

// ─── Edit post bottom sheet ───────────────────────────────────────────────────
```

**JSDoc/TSDoc:**
- Minimal use of doc comments (`///`)
- Found mainly in main.dart for global state: `/// Global theme notifier — write to this from ThemeScreen to change theme.`
- No systematic documentation of public APIs

## Function Design

**Size:** Functions vary from compact single-expressions to ~100+ lines for complex screens

**Parameters:**
- Named parameters with `required` keyword: `required this.postId`
- Consistent use of `{super.key}` in constructors
- Widget state classes pass data via constructor parameters

**Return Values:**
- Explicit type declarations: `Future<void>`, `Future<String?>`, `Future<User?>`
- Null-coalescing for optional values: `(userDoc.data()?['username'] as String?) ?? 'User'`
- Inline type casts with null safety: `as String?` patterns
- Empty lists/maps as defaults: `widget.data?['items'] ?? []`

## Module Design

**Exports:**
- No barrel files (index.dart) used
- Direct imports of individual classes/services

**Barrel Files:**
- Not used in this codebase
- Each file imports the specific class it needs

**State Management Patterns:**
- Direct `setState()` for local state in StatefulWidget screens
- `FirebaseAuth.instance` accessed directly throughout app
- `FirebaseFirestore.instance` accessed directly for queries
- Global `ValueNotifier<ThemeMode>` for theme state: `final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);`
- `StreamBuilder` for Firebase real-time data: `StreamBuilder<QuerySnapshot<Map<String, dynamic>>>`

**StatefulWidget Pattern:**
```dart
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Private fields with underscore
  final TextEditingController _inputController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  // Private async method with underscore
  Future<void> _handleLogin() async {
    // Method body
  }

  @override
  Widget build(BuildContext context) {
    // Build implementation
  }
}
```

## Theme-Aware Colors

**Pattern:**
- Heavy use of `Theme.of(context)` to access theme colors
- Direct color references for specific branding: `Colors.black`, `Colors.red`
- Theme-aware approach: `theme.colorScheme.onSurface`, `theme.colorScheme.surface`
- Fallback colors for error states: `Colors.grey.shade300` for missing images

**Examples:**
```dart
// From post_detail_screen.dart
final theme = Theme.of(context);

Icon(
  _liked ? Icons.favorite : Icons.favorite_border,
  color: _liked ? Colors.red : theme.colorScheme.onSurface,
  size: 26,
),

// Color scheme usage
Container(
  color: theme.colorScheme.surface,
  border: Border(top: BorderSide(color: Colors.grey.shade300)),
),
```

## Stream and Async Patterns

**StreamBuilder Usage:**
- Commonly used for real-time Firebase data
- Pattern: `StreamBuilder<QuerySnapshot<Map<String, dynamic>>>`
- Listener streams attached in `initState()` for state updates
- Manual stream listeners with `FirebaseFirestore.instance.collection(...).snapshots().listen()`

**Optimistic UI Updates:**
- State changed immediately via `setState()` before async operation completes
- Async operation runs in background
- On error, state may be silently rolled back with `catch (_) {}`

**Example:**
```dart
// Optimistic like toggle
if (_liked) {
  setState(() {
    _liked = false;
    _likeCount = (_likeCount - 1).clamp(0, 99999);
  });
  try {
    await likeRef.delete();
    await userLikeRef.delete();
    await postRef.update({'likes': _likeCount});
  } catch (_) {}  // Silent failure - UI already updated
}
```

---

*Convention analysis: 2026-04-15*
