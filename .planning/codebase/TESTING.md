# Testing Patterns

**Analysis Date:** 2026-04-15

## Test Framework

**Runner:**
- `flutter_test` (built-in Flutter testing framework) - SDK dependency
- Located in: `pubspec.yaml` under dev_dependencies
- Config file: None (uses Flutter defaults)

**Assertion Library:**
- Flutter's built-in expect() API from flutter_test
- Example: `expect(find.text('0'), findsOneWidget)`

**Run Commands:**
```bash
flutter test                  # Run all tests
flutter test --watch         # Watch mode (re-run on file changes)
flutter test --coverage       # Generate coverage report
flutter test test/widget_test.dart  # Run specific test file
```

## Test File Organization

**Location:**
- Separate from source code in `test/` directory
- Single test file found: `test/widget_test.dart`

**Naming:**
- `_test.dart` suffix convention (one instance: `widget_test.dart`)
- Test functions use `testWidgets()` for widget tests

**Structure:**
```
test/
├── widget_test.dart          # Only existing test file
```

**Critical Gap:** Only one placeholder widget test exists for the entire codebase.

## Test Structure

**Suite Organization:**
```dart
void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Test body
  });
}
```

**Patterns:**
```dart
// Typical widget test pattern from widget_test.dart
testWidgets('Counter increments smoke test', (WidgetTester tester) async {
  // 1. Build the widget tree
  await tester.pumpWidget(const MyApp());
  
  // 2. Verify initial state
  expect(find.text('0'), findsOneWidget);
  expect(find.text('1'), findsNothing);
  
  // 3. Perform interaction
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();
  
  // 4. Verify result state
  expect(find.text('0'), findsNothing);
  expect(find.text('1'), findsOneWidget);
});
```

**Setup Pattern:**
- No explicit setup/teardown visible in existing test
- Could use `setUp()` and `tearDown()` callbacks at `main()` level if needed

**Teardown Pattern:**
- Not used in existing test
- Relevant for Firebase cleanup if integration tests added

**Assertion Pattern:**
- `expect(find.MATCHER, findsONE/findsNothing/findsWidgets)` pattern
- `find.text()` for text matching
- `find.byIcon()` for icon matching
- `find.byWidget()` for direct widget matching

## Mocking

**Framework:** Not detected - no mockito or similar package in pubspec.yaml

**Patterns:**
- No mocking infrastructure present
- Would need to add `mockito` or `mocktail` if mocking Firebase services required

**What to Mock (if testing added):**
- Firebase Authentication: `FirebaseAuth.instance`
- Cloud Firestore: `FirebaseFirestore.instance`
- Firebase Storage: `FirebaseStorage.instance`
- Image Picker: `ImagePicker()`

**What NOT to Mock:**
- Flutter/Material widgets (test against real widgets)
- Theme system (test theme colors directly)
- Navigation (use WidgetTester navigation methods)

## Fixtures and Factories

**Test Data:**
- No test fixtures or factories detected
- No test data builders

**Location:**
- Not applicable - no dedicated test utilities directory

**Needed for future tests:**
```dart
// Example pattern to follow if added:
final mockPost = {
  'postId': 'test-post-1',
  'uid': 'test-user-1',
  'username': 'testuser',
  'description': 'Test post',
  'imageUrl': 'https://example.com/image.jpg',
  'likes': 0,
  'createdAt': Timestamp.now(),
};
```

## Coverage

**Requirements:** No coverage target enforced (not configured in analysis_options.yaml)

**View Coverage:**
```bash
flutter test --coverage
# Generates coverage/lcov.info
```

**Current State:** 
- Coverage data NOT collected (no --coverage runs evident)
- Codebase has ~30+ Dart files with minimal test coverage
- Only 1 test file exists for entire app

## Test Types

**Unit Tests:**
- Not detected
- Recommended for: `auth_service.dart` (login/register logic), data validation

**Integration Tests:**
- Not detected
- Would test Firebase interactions without mocking
- Candidate files: authentication flows, post creation, like/save operations

**E2E Tests:**
- Not detected
- Framework: Would require `integration_test` package
- Candidates: Full user journeys (login → post → like → view profile)

**Widget Tests:**
- Single placeholder test in `test/widget_test.dart`
- Tests basic counter increment (not related to actual app)
- All screen widgets untested

## Common Patterns

**Async Testing:**
```dart
// Pattern used in existing test
testWidgets('description', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();  // Single frame rebuild
  // Or: await tester.pumpAndSettle(); // Wait for all animations
});
```

**Error Testing:**
- Not present in existing tests
- Pattern to follow for FirebaseAuthException:
```dart
testWidgets('login shows error on invalid credentials', 
    (WidgetTester tester) async {
  // Requires mocking FirebaseAuth to throw exception
  await tester.pumpWidget(const MyApp());
  // ... test error handling
});
```

## Critical Testing Gaps

The codebase has significant testing gaps across multiple layers:

**Missing Unit Tests:**
- `lib/features/auth/auth_service.dart` - No tests for login(), register(), logout()
- No validation logic tests

**Missing Widget Tests:**
- `lib/features/auth/Login_Screen.dart` - UI interactions, form validation display
- `lib/features/auth/Register_Screen.dart` - Registration flow
- `lib/features/discover/post_detail_screen.dart` - Like/save toggles, comment submission
- `lib/features/discover/posting_screen.dart` - Image selection, post creation
- `lib/core/theme/app_theme.dart` - Theme application (light/dark modes)
- `lib/features/settings/theme_screen.dart` - Theme switching
- All profile, wardrobe, and planner screens

**Missing Integration Tests:**
- Firebase Auth flows (login, register, logout)
- Firestore post creation and retrieval
- Image upload to Firebase Storage
- Real-time updates via StreamBuilder

**Missing E2E Tests:**
- Complete user journeys
- Cross-feature interactions

**Recommended Priority for Adding Tests:**
1. **High**: `auth_service.dart` and `Login_Screen.dart` (critical authentication)
2. **High**: `post_detail_screen.dart` (core social features)
3. **Medium**: `posting_screen.dart` (user-generated content)
4. **Medium**: `theme_screen.dart` (theme persistence)
5. **Low**: Navigation and routing

## Test Execution Notes

**Setup Required for Real Testing:**
- Firebase emulator or test credentials for authentication tests
- Mocking layer setup if not hitting real Firebase
- Test data fixtures for Firestore tests
- No CI/CD pipeline detected for automated test runs

---

*Testing analysis: 2026-04-15*
