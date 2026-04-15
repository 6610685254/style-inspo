# Requirements: OOTD — Outfit Of Today

**Defined:** 2026-04-15
**Core Value:** Users can get a daily AI outfit suggestion from their own wardrobe and share it with the community.

## v1 Requirements

Requirements for this milestone. All build on the existing working app.

### Wardrobe

- [x] **WARD-01**: User can tap one or more clothing type chips to filter the wardrobe — only items of selected types are shown
- [x] **WARD-02**: User can tap a selected type chip again to deselect it (clear that filter)
- [x] **WARD-03**: When no type is selected, all wardrobe items are shown (default state, same as current behavior)

### Style Lab

- [ ] **SLAB-01**: User can save an AI-generated suggestion as a named outfit (persisted to Firestore)
- [ ] **SLAB-02**: User sees a clear error message when AI generation fails (e.g. network error, function error)
- [ ] **SLAB-03**: User sees a clear empty state with instruction when wardrobe has no items and they try to generate
- [ ] **SLAB-04**: User can view a list of previously generated / saved suggestions in Style Lab
- [ ] **SLAB-05**: User can share an outfit suggestion (title + clothing item images) via the system share sheet

## v2 Requirements

Deferred to a future milestone.

### Notifications

- **NOTF-01**: Real push notifications via FCM for likes, comments, new followers
- **NOTF-02**: Notification preference toggles persisted to backend (currently local-only)

### Internationalization

- **I18N-01**: Actual locale switching when user selects a language
- **I18N-02**: App UI strings extracted to ARB/l10n files

## Out of Scope

| Feature | Reason |
|---------|--------|
| OAuth login | Email/username sufficient for current scope |
| Video posts | Storage/bandwidth cost, defer |
| Real-time chat | High complexity, not core |
| Notifications (FCM) | Standalone effort, not priority this milestone |
| Language / i18n | Significant effort, deferred |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| WARD-01 | Phase 1 | Complete |
| WARD-02 | Phase 1 | Complete |
| WARD-03 | Phase 1 | Complete |
| SLAB-01 | Phase 2 | Pending |
| SLAB-02 | Phase 2 | Pending |
| SLAB-03 | Phase 2 | Pending |
| SLAB-04 | Phase 2 | Pending |
| SLAB-05 | Phase 2 | Pending |

**Coverage:**
- v1 requirements: 8 total
- Mapped to phases: 8
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-15*
*Last updated: 2026-04-15 after initial definition*
