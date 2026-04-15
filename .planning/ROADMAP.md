# Roadmap: OOTD — Outfit Of Today

**Milestone:** Polish & Filter  
**Created:** 2026-04-15  
**Granularity:** Coarse  
**Coverage:** 8/8 v1 requirements mapped

## Phases

- [x] **Phase 1: Wardrobe Type Filter** - User can tap clothing type chips to filter the wardrobe to matching items (completed 2026-04-15)
- [ ] **Phase 2: Style Lab Polish** - User can save, view, share AI suggestions and sees clear error/empty states

## Phase Details

### Phase 1: Wardrobe Type Filter
**Goal**: Users can interactively filter their wardrobe by clothing type using tappable chips
**Depends on**: Nothing (self-contained UI change on existing WardrobeScreen)
**Requirements**: WARD-01, WARD-02, WARD-03
**Success Criteria** (what must be TRUE):
  1. User can tap a clothing type chip (e.g. "Tops") and the wardrobe list immediately shows only items of that type
  2. User can tap multiple type chips and sees items matching any of the selected types
  3. User can tap an active (selected) chip to deselect it, removing that type from the filter
  4. When no chips are selected the full wardrobe is shown, identical to the current default view
**Plans**: 1 plan

Plans:
- [x] 01-01-PLAN.md — Add type FilterChip row + filter logic to WardrobeScreen

### Phase 2: Style Lab Polish
**Goal**: Users get a reliable, complete Style Lab experience — save suggestions, review past ones, share outfits, and receive clear feedback on failures
**Depends on**: Phase 1
**Requirements**: SLAB-01, SLAB-02, SLAB-03, SLAB-04, SLAB-05
**Success Criteria** (what must be TRUE):
  1. User can save a generated suggestion under a name and it persists across app restarts
  2. User can view a scrollable list of previously saved suggestions inside Style Lab
  3. User sees a descriptive error message (not a raw exception) when AI generation fails for any reason
  4. User sees an empty-state prompt with clear instructions when their wardrobe is empty and they attempt to generate an outfit
  5. User can tap share on a suggestion and the system share sheet opens with the outfit title and clothing item images
**Plans**: TBD
**UI hint**: yes

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Wardrobe Type Filter | 1/1 | Complete    | 2026-04-15 |
| 2. Style Lab Polish | 0/? | Not started | - |
