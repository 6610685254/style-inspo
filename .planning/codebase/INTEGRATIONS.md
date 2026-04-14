# External Integrations

**Analysis Date:** 2026-04-15

## APIs & External Services

**Google Generative AI (Genkit):**
- Gemini 1.5 Flash model - AI-powered outfit suggestion generation
  - SDK: `@genkit-ai/googleai` 1.28.0
  - Auth: `GOOGLE_GENAI_API_KEY` (Firebase Function secret via `defineSecret("GOOGLE_GENAI_API_KEY")`)
  - Implementation: `functions/src/index.ts` - `generateOutfitSuggestion` Cloud Function
  - Schema validation: Zod schema `OutfitSuggestionSchema` validates AI responses with `title`, `clothingIds`, `reasoning` fields

## Data Storage

**Primary Database:**
- Firestore (Cloud Firestore)
  - Project ID: `cn333-8e548`
  - Collections:
    - `users` - User account data (username, email, timestamp)
    - `users/{uid}/clothes` - Wardrobe items (type, color, season, tags, vision attributes, images)
    - `users/{uid}/suggestions` - AI-generated outfit suggestions (title, clothingIds, reasoning, status)
    - `users/{uid}/savedOutfits` - User-saved outfit combinations
    - Accessed via: `cloud_firestore` 6.2.0 package
  - Location: `lib/features/auth/auth_service.dart`, `lib/features/wardrobe/wardrobe_repository.dart`

**File Storage:**
- Firebase Cloud Storage
  - Bucket: `cn333-8e548.firebasestorage.app`
  - Storage paths:
    - `posts/{userId}/{fileName}` - User-posted outfit images (from `lib/features/discover/posting_screen.dart`)
    - `users/{userId}/avatar.jpg` - User profile avatars (from `lib/features/profile/profile_screen.dart`)
    - `wardrobe/{userId}/{clothingId}/` - Wardrobe clothing item images (from `lib/features/wardrobe/add_wardrobe_screen.dart`)
  - SDK: `firebase_storage` 13.2.0
  - Image upload workflow: Pick image via `image_picker` → Compress to max 1080x1080, 85% quality → Upload to Firebase Storage

**Caching:**
- In-memory cache only (Flutter app state)
  - Wardrobe items cached in `StyleLabScreen._wardrobeCache` (Map<String, Map<String, dynamic>>)
  - Real-time sync via Firestore snapshots (`.snapshots()` streams)

## Authentication & Identity

**Auth Provider:**
- Firebase Authentication
  - Supported methods: Email/Password
  - Project: `cn333-8e548`
  - SDK: `firebase_auth` 6.3.0
  - Implementation: `lib/features/auth/auth_service.dart`
  - Features:
    - User registration with unique username validation against Firestore `users` collection
    - Login via email OR username (username lookup from Firestore)
    - Auth state streaming via `FirebaseAuth.instance.authStateChanges()`
    - Logout with `FirebaseAuth.signOut()`
  - Auto-redirect: App redirects to `HomeScreen` if authenticated, `LoginPage` if not (via StreamBuilder in `lib/main.dart`)

## Monitoring & Observability

**Error Tracking:**
- Firebase console error logging (implicit)
- Console-based debugging: `print()` statements in code (e.g., `functions/src/index.ts` logs Genkit errors)

**Logs:**
- Cloud Functions logs via Firebase CLI: `firebase functions:log`
- Console logging in Cloud Functions error paths

## CI/CD & Deployment

**Hosting:**
- Firebase Hosting (Web)
  - Deploy directory: `build/web`
  - SPA rewrites configured: All routes redirect to `/index.html`
  - Deployment: `firebase deploy` command

**Backend Deployment:**
- Firebase Cloud Functions
  - Region: Default (us-central1)
  - Deployment: `firebase deploy --only functions`
  - Pre-deploy build: `npm run build` (TypeScript compilation)
  - Source: `functions/src/index.ts`

**Local Development:**
- Firebase Emulator Suite
  - Run functions locally: `firebase emulators:start --only functions`
  - Emulator shell: `firebase functions:shell`

## Environment Configuration

**Required env vars (Cloud Functions):**
- `GOOGLE_GENAI_API_KEY` - Google AI API key for Gemini (stored as Firebase secret, injected at runtime)
- Firebase credentials auto-configured via `google-services.json` (Android) and Firebase configuration

**Firebase Configuration Files:**
- `firebase.json` - Firebase project settings and hosting configuration
- `lib/firebase_options.dart` - Platform-specific Firebase SDK configuration (Web, Android, iOS, macOS, Windows)
- `android/app/google-services.json` - Auto-generated Android Firebase configuration (from firebase.json)

**Secrets Location:**
- Cloud Functions secrets: Firebase Cloud Secret Manager (referenced via `defineSecret("GOOGLE_GENAI_API_KEY")` in `functions/src/index.ts`)
- Client credentials: Embedded in `lib/firebase_options.dart` (public Firebase keys, not sensitive)
- No `.env` file - All configuration via Firebase console

## Webhooks & Callbacks

**Incoming:**
- Cloud Functions HTTP endpoints:
  - `generateOutfitSuggestion` - Callable HTTPS endpoint for AI outfit generation
  - Triggered by Flutter app via `FirebaseFunctions.instance.httpsCallable('generateOutfitSuggestion')`
  - Location: `functions/src/index.ts` (exports `generateOutfitSuggestion` as `onCall`)

**Outgoing:**
- No external webhook endpoints detected
- Firestore write operations trigger Cloud Function (implicit, via Firestore triggers if configured)
- Data flows: App → Firestore, App → Cloud Functions → Genkit API → App

## Data Flow Architecture

**Outfit Generation Pipeline:**
1. User initiates outfit suggestion via `StyleLabScreen.generateSuggestion()` in `lib/features/wardrobe/stylelab.dart`
2. App calls `FirebaseFunctions.instance.httpsCallable('generateOutfitSuggestion')`
3. Cloud Function (`functions/src/index.ts`):
   - Authenticates user via `request.auth`
   - Fetches user's wardrobe from `users/{uid}/clothes` Firestore collection
   - Constructs fashion prompt with wardrobe items
   - Calls Genkit SDK with Google AI plugin (Gemini 1.5 Flash)
   - Returns validated response (Zod schema enforced)
4. App saves suggestion to `users/{uid}/suggestions` Firestore collection
5. UI displays suggestion with AI-generated reasoning

**Image Upload Pipeline:**
1. User picks image via `image_picker` (camera or gallery)
2. Image compressed to 1080x1080, 85% quality
3. Upload to Firebase Storage (`posts/{uid}/{fileName}` or `wardrobe/{uid}/{clothingId}/`)
4. Store image URL in Firestore document
5. Real-time UI update via Firestore snapshot listener

---

*Integration audit: 2026-04-15*
