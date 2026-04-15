# OOTD — Outfit Of Today

## What This Is

A Flutter social fashion app where users build a digital wardrobe, get AI-generated outfit suggestions via Gemini, and share their daily looks with a community feed. Built with Firebase (Auth, Firestore, Storage, Cloud Functions) and Genkit for AI outfit generation. Primary platform is Android, with iOS/Web support.

## Core Value

Users can get a daily AI outfit suggestion from their own wardrobe and share it with the community.

## Requirements

### Validated

- ✓ Register and login with email or username — existing
- ✓ Logout and delete account (with reauth) — existing
- ✓ Add, edit, delete wardrobe items with photo — existing
- ✓ Wardrobe items grouped by clothing type — existing
- ✓ Filter wardrobe by color — existing
- ✓ Create posts with image and description — existing
- ✓ Like and bookmark posts — existing
- ✓ Comment on posts — existing
- ✓ Follow / unfollow other users — existing
- ✓ Home screen: AI suggestion grid + trending posts feed — existing
- ✓ Style Lab: generate AI outfit suggestion via Genkit + Gemini Cloud Function — existing
- ✓ Profile: posts, liked, bookmarks tabs + edit name and avatar — existing
- ✓ Weekly outfit planner — existing
- ✓ Discover feed of community posts — existing
- ✓ Dark/light theme toggle — existing
- ✓ Help and About screens — existing
- ✓ Wardrobe type filter — multi-select FilterChip row; tapping chips filters by type, deselect clears filter — Phase 1

### Active

(None — all v1 requirements shipped)

### Validated (Phase 2)

- ✓ Style Lab save dialog — named save with AlertDialog, persists to Firestore — Phase 2
- ✓ Style Lab error messages — friendly mapped errors, no raw exceptions — Phase 2
- ✓ Style Lab empty state — wardrobe empty prompt with "Go to Wardrobe" CTA — Phase 2
- ✓ Style Lab suggestion history — scrollable past suggestions list with save/share per item — Phase 2
- ✓ Style Lab share — share_plus text share of outfit title + clothing descriptions — Phase 2

### Out of Scope

- Push notifications (FCM) — not a priority for this milestone; UI stub exists but won't be wired up
- Language / i18n — UI language picker exists but locale switching not implemented; deferred
- OAuth (Google/GitHub login) — email/username sufficient
- Video posts — deferred, storage cost concern
- Real-time chat — high complexity, not core

## Context

- **Codebase:** Mapped at `.planning/codebase/` — feature-based Clean Architecture, Firebase direct integration throughout, StreamBuilder-based reactive UI
- **AI:** Cloud Function `generateOutfitSuggestion` at `functions/src/index.ts` using Genkit + Gemini 1.5 Flash; client calls via `cloud_functions` package in `stylelab.dart`
- **Wardrobe:** Items stored in `users/{uid}/clothes/`, suggestions in `users/{uid}/suggestions/`
- **Posts:** Global `posts/` collection with likes subcollection, savedPosts and likedPosts in user subcollections
- **Known issues from codebase audit:** No structured logging, print() statements throughout; notification toggles are local-only bool state with no backend; language screen only shows SnackBar

## Constraints

- **Tech stack:** Flutter + Dart — must stay within existing stack
- **Backend:** Firebase only — no additional backend services
- **Timeline:** A few weeks
- **Scope:** Polish and fix existing features — no major new features this milestone

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Skip notifications for this milestone | Not a priority; FCM integration is a standalone effort | — Pending |
| Skip language/i18n for this milestone | Significant effort for low immediate value | — Pending |
| Wardrobe filter as tap-to-filter, not new screen | Consistent with existing color filter UX pattern | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-15 after Phase 2 complete (Style Lab Polish) — all v1 requirements shipped*
