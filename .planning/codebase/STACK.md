# Technology Stack

**Analysis Date:** 2026-04-15

## Languages

**Primary:**
- Dart 3.10.8+ - Flutter application code in `lib/` directory
- TypeScript 5.7.3 - Cloud Functions backend in `functions/src/`
- Kotlin 17 - Android native code in `android/`

**Secondary:**
- Gradle Kotlin DSL - Android build configuration in `android/build.gradle.kts` and `android/app/build.gradle.kts`

## Runtime

**Environment:**
- Flutter SDK (latest) - Mobile and web application framework
- Node.js 24 - Cloud Functions runtime

**Package Managers:**
- `pub` / `pubspec.yaml` - Dart dependencies
- `npm` - Node.js dependencies for Firebase Functions

## Frameworks

**Core:**
- Flutter 3.x - Cross-platform mobile framework for iOS/Android/Web
- Firebase (multi-product) - Backend services suite
- Google AI (Genkit) 1.28.0 - AI model integration for outfit generation

**Testing:**
- flutter_test SDK - Built-in Flutter testing framework

**Build/Dev:**
- Flutter Gradle Plugin - Android build integration
- TypeScript compiler - Cloud Functions transpilation
- Firebase CLI - Local emulation and deployment (`firebase emulators:start --only functions`)

## Key Dependencies

**Critical:**
- `firebase_core` 4.6.0 - Firebase initialization
- `firebase_auth` 6.3.0 - User authentication
- `cloud_firestore` 6.2.0 - NoSQL database (core data store)
- `cloud_functions` 6.1.0 - Firebase Functions integration
- `firebase_storage` 13.2.0 - Image and file storage

**AI/Styling:**
- `genkit` 1.28.0 - Google's generative AI framework
- `@genkit-ai/googleai` 1.28.0 - Google AI plugin (Gemini integration)
- `@genkit-ai/ai` 1.28.0 - AI capabilities core
- `@genkit-ai/flow` 0.5.17 - Workflow orchestration

**Utilities:**
- `firebase-admin` 13.6.1 - Server-side Firebase access in Cloud Functions
- `firebase-functions` 7.0.0 - Firebase Functions SDK
- `image_picker` 1.1.1 - Device camera and gallery access
- `uuid` 4.5.2 - Unique identifier generation
- `zod` 4.3.6 - TypeScript schema validation for AI responses

**UI:**
- `cupertino_icons` 1.0.8 - iOS-style icon font

**Dev Tools:**
- `flutter_lints` 6.0.0 - Recommended Flutter lint rules
- `eslint` 8.9.0 - JavaScript/TypeScript linting
- `@typescript-eslint/eslint-plugin` 5.12.0 - TypeScript linting
- `firebase-functions-test` 3.4.1 - Cloud Functions testing utilities

## Configuration

**Firebase Configuration:**
- `firebase.json` - Firebase project configuration (hosted at `cn333-8e548`)
- `lib/firebase_options.dart` - Platform-specific Firebase initialization keys for Android, iOS, macOS, Windows, Web
- Google Services JSON - `android/app/google-services.json` (generated, auto-configured)

**Environment:**
- Google AI API Key - Stored as Firebase Function secret `GOOGLE_GENAI_API_KEY`
- No `.env` file in repository - All secrets managed through Firebase secrets and Google Cloud Secret Manager

**Build Configuration:**
- `pubspec.yaml` - Main Flutter app manifest (version 1.0.0+1)
- `android/build.gradle.kts` - Root Gradle configuration
- `android/app/build.gradle.kts` - App-level build configuration
- `functions/package.json` - Cloud Functions Node.js configuration
- `functions/tsconfig.json` - TypeScript compilation settings for backend

## Platform Requirements

**Development:**
- Flutter SDK (latest)
- Android Studio / Android SDK (for Android builds)
- Node.js 24+ (for Cloud Functions)
- Firebase CLI (for local testing and deployment)

**Production:**
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

---

*Stack analysis: 2026-04-15*
