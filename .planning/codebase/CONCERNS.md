# Codebase Concerns

**Analysis Date:** 2026-04-15

## Cloud Functions Deployment Blocker

**generateOutfitSuggestion Cloud Function (AI feature incomplete):**
- Issue: Cloud Function in `functions/src/index.ts` requires `GOOGLE_GENAI_API_KEY` secret that is not set up in Firebase Functions environment
- Files: `functions/src/index.ts` (lines 9, 47), `lib/features/wardrobe/wardrobe_repository.dart` (line 157-190)
- Impact: AI outfit generation feature (`generateAIOutfit()` method) will fail at runtime when called from any client (e.g., style lab). Users see error: "Failed to generate outfit suggestion"
- Fix approach: 
  1. Create Firebase secret: `firebase functions:secrets:set GOOGLE_GENAI_API_KEY`
  2. Deploy Cloud Functions: `firebase deploy --only functions`
  3. This is **blocking** the AI features and must be done before release

## Missing Localization Persistence

**Language selection UI with no i18n backend:**
- Issue: `lib/features/settings/language_screen.dart` provides UI for selecting languages (English, Thai, Japanese, Korean, Chinese) but only saves selected language to local widget state
- Files: `lib/features/settings/language_screen.dart` (lines 10-48)
- Impact: 
  - Language preference is lost on app restart
  - No actual translation/localization happens — app always displays English
  - Other screens do not respond to language selection
- Fix approach:
  1. Persist language selection to Firestore in `users/{uid}/preferences/language` or local SharedPreferences
  2. Integrate flutter_localizations and i18n package (e.g., `intl` or `easy_localization`)
  3. Wire theme mode listener pattern (already used for theme in `main.dart` line 12) to language state
  4. Update all text strings in app to use localized keys

## Notifications UI Without FCM Implementation

**Notification preferences with no backend wiring:**
- Issue: `lib/features/settings/notification_screen.dart` provides toggles for notifications (new posts, likes, suggestions, weekly planner) but does not integrate with Firebase Cloud Messaging (FCM)
- Files: `lib/features/settings/notification_screen.dart` (lines 10-68)
- Impact:
  - Toggling notifications has no effect — toggles are UI-only
  - No FCM registration or token management
  - No notification payload handling configured
  - Users cannot receive any notifications regardless of preferences
- Fix approach:
  1. Add `firebase_messaging` dependency to `pubspec.yaml`
  2. Persist notification preferences to Firestore: `users/{uid}/notificationPrefs`
  3. Request FCM token on login in `lib/main.dart` or `auth_service.dart`
  4. Set up background notification handler
  5. Implement server-side topic subscription logic based on preferences (requires Cloud Functions)

## Previously Exposed Firebase Configuration

**firebase_options.dart gitignore and exposure history:**
- Issue: `lib/firebase_options.dart` is in `.gitignore` (line 52) but was likely committed before this rule was added. Git history may contain project ID, app IDs, and Firebase configuration
- Files: `.gitignore` (line 52), potentially in git history
- Impact: Firebase project credentials (cn333-8e548) are visible in git log — any attacker with repo access can see Firestore project ID, app identifiers, and Firebase API keys
- Recommendations:
  1. Run `git filter-branch` or `BFG Repo-Cleaner` to remove `firebase_options.dart` from all history
  2. Rotate Firebase API keys (if possible) or restrict usage to current app bundle IDs
  3. Review Firebase Console for any unusual activity
  4. Ensure `.gitignore` rule persists in all future commits

## Mixed Image Storage Field Names

**Inconsistent imageUrl vs imageRef in wardrobe items:**
- Issue: Wardrobe/clothing items use two different field names for images:
  - `imageRef` (string reference to Firebase Storage path) in `createClothingItem()` method
  - `imageUrl` (full downloadable URL) in `addClothingItem()` method
- Files: 
  - `lib/features/wardrobe/wardrobe_repository.dart` (line 41 `imageRef`, line 194 `imageUrl`)
  - All display code expects `imageUrl` field (e.g., `lib/features/discover/posting_screen.dart` line 367, `lib/features/home/home_screen.dart` line 89)
- Impact:
  - Some items created via old code path won't display (missing `imageUrl`, have `imageRef` instead)
  - Inconsistent data model across Firestore
  - Code cannot reliably distinguish which field to use when fetching items
  - Breaking change risk if items added via both methods
- Fix approach:
  1. Standardize on `imageUrl` (full download URL) — already used by all display code
  2. Remove `createClothingItem()` method (not called anywhere)
  3. Keep only `addClothingItem()` method with consistent `imageUrl` field
  4. Create Firestore migration script to backfill missing `imageUrl` fields from `imageRef` (requires Cloud Function)

## Missing Test Coverage

**No automated tests — only placeholder widget test:**
- Issue: Project contains zero meaningful test coverage
- Files: `test/widget_test.dart` (lines 14-29) — generic template test that checks for nonexistent counter widget
- Impact:
  - No regression detection when refactoring
  - UI changes break silently (discovered only by manual testing)
  - Firebase integration errors caught only in production
  - Cloud Function behavior not validated
  - Data model changes risk data inconsistency without alerting developers
- Recommended test priorities (high to low impact):
  1. **Cloud Function tests** (`functions/src/index.ts`): Test outfit generation with mock wardrobe data
  2. **Follow/Like operations** (`lib/features/discover/user_profile_screen.dart` lines 53-84): FieldValue.increment() consistency is fragile
  3. **Multi-stream listeners** (e.g., `post_detail_screen.dart` lines 47-82): Multiple live listeners can cause race conditions
  4. **Repository methods** (`lib/features/wardrobe/wardrobe_repository.dart`): Image upload, outfit creation, suggestion generation
  5. **Auth state transitions** (`main.dart` lines 34-45): Login/logout state persistence

## Follow Count Operations Using FieldValue.increment

**Fragile distributed counter pattern:**
- Issue: Follow/unfollow operations use `FieldValue.increment()` to update user follow counts but are vulnerable to race conditions
- Files: `lib/features/discover/user_profile_screen.dart` (lines 71-78)
- Problem: 
  - Multiple simultaneous follow/unfollow requests can cause counter misalignment
  - If client disconnects during increment, counts become stale
  - No validation that increment succeeded before updating UI
  - Unfollow happens before deleting follow documents (lines 67-72) — if delete fails, count decremented but follow relation still exists
- Safe modification:
  1. Always increment/decrement **after** successful collection operations
  2. Wrap entire transaction in Firestore transaction (requires Dart SDK update)
  3. Add error recovery: re-read counts from Firestore on failure instead of client-side reversal
  4. Consider distributed counter shards for high-traffic users (future optimization)

## Real-Time Streams Without Lifecycle Management

**Multiple Firestore snapshot listeners without guaranteed cleanup:**
- Issue: Post detail screen and profile screens attach multiple Firestore listeners without consistent disposal
- Files:
  - `lib/features/discover/post_detail_screen.dart` (lines 47-82): Three listeners attached in `initState()` without cleanup in `dispose()`
  - `lib/features/profile/profile_screen.dart` (lines 45-73): Two listeners without disposal
  - Similar pattern in other detail screens
- Impact:
  - Memory leaks: listeners continue running after screens close
  - Duplicate updates: if user returns to screen, old listener fires alongside new one
  - Battery drain: continuous Firestore polling in background
  - Quota overuse: unnecessary Firestore read operations accumulate
- Fix approach:
  1. Store listener subscriptions: `StreamSubscription<DocumentSnapshot> _userSubscription;`
  2. Cancel in dispose: `_userSubscription.cancel()` (line 87 of `post_detail_screen.dart` needs this)
  3. Use `autoDispose` pattern if adopting Riverpod/Provider state management
  4. Audit all `StreamBuilder` and `.listen()` calls for proper cleanup

## No Firebase Security Rules Enforcement

**Missing or unenforced Firestore/Storage access rules:**
- Issue: No `.rules` files found in codebase (`firestore.rules`, `storage.rules`). Firebase likely uses default permissive rules
- Files: Not present in repo (should be in `.firebase/` or at project root)
- Impact:
  - **Critical**: Any authenticated user can read/write any other user's data (profiles, posts, wardrobe, saved outfits)
  - Any user can delete other users' posts or follow relationships
  - Wardrobe items visible to all users
  - Likes/comments can be forged
  - Storage files can be accessed without authorization
- Recommendations (must deploy ASAP):
  1. Create `firestore.rules` enforcing:
     - Users can only read/write own user doc and own subcollections
     - Posts readable by all, writable only by owner, deletable only by owner
     - Likes/comments writable only by authenticated user
  2. Create `storage.rules` restricting:
     - Users can only upload to `users/{auth.uid}/**`
     - Download URLs in posts must be signed or restricted to posting user
  3. Deploy rules: `firebase deploy --only firestore:rules,storage`
  4. Test with anonymous user to verify restrictions

## Performance Concerns

**N+1 Query Pattern in Home Screen:**
- Issue: Home screen fetches latest suggestion, then for each clothing ID makes individual document reads
- Files: `lib/features/home/home_screen.dart` (lines 49-70)
- Problem: If suggestion contains 4 clothing items, makes 1 query for suggestion + 4 queries for clothes = 5 Firestore reads per home screen load
- Impact: High Firestore costs at scale, slow UI on slow networks
- Fix: Fetch suggestion and batch-read all clothing items in single query using `collection(list-contains)` or embed summary data in suggestion doc

**Unindexed Firestore Query:**
- Issue: Profile screen sorts posts by `createdAt` client-side (line 353-358 in `profile_screen.dart`) instead of server-side
- Files: `lib/features/profile/profile_screen.dart` (lines 351-358)
- Impact: Fetches all user's posts then sorts — inefficient for users with 100+ posts
- Fix: Use Firestore query: `.orderBy('createdAt', descending: true).limit(100)`

## Error Handling Gaps

**Silent failures in critical operations:**
- Issue: Several user-impacting operations catch errors but log insufficiently:
  - Post creation fails silently if Firestore write fails (line 109 in `posting_screen.dart`)
  - Image upload errors show generic message (line 119 in `add_wardrobe_screen.dart`)
  - Cloud Function errors print to console only (line 187 in `wardrobe_repository.dart`)
- Impact: Users don't know why actions failed, can't retry intelligently
- Fix: 
  1. Show specific error messages for recoverable errors (network, quota, auth)
  2. Log to error tracking service (Sentry, Crashlytics) for debugging
  3. Provide retry buttons for failed operations

## Dependencies at Risk

**Outdated or Pinned Package Versions:**
- `cloud_firestore: ^6.2.0` and other Firebase packages are recent but dependency chaining is unclear
- `image_picker: ^1.1.1` — check for permissions issues on Android 13+
- `uuid: ^4.5.2` — used for file naming but could have hash collisions at scale
- No dependency version lock enforcement documented (security risk for CI/CD)

## Unhandled Loading States

**Some screens missing loading indicators during async operations:**
- Issue: Post detail screen streams live data but initial load has no loading indicator
- Files: `lib/features/discover/post_detail_screen.dart` (initState doesn't show loading UI)
- Impact: User sees stale UI until first Firestore response arrives
- Fix: Show loading spinner or skeleton screen until `_postData` first updates

---

*Concerns audit: 2026-04-15*
