---
phase: 01-wardrobe-type-filter
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/wardrobe/wardrobe_screen.dart
autonomous: true
requirements:
  - WARD-01
  - WARD-02
  - WARD-03

must_haves:
  truths:
    - "Tapping a type chip immediately shows only wardrobe items of that type"
    - "Tapping multiple type chips shows items matching any selected type (OR logic)"
    - "Tapping an already-selected chip deselects it and removes that type from the filter"
    - "When no chips are selected, all wardrobe items are shown — identical to current behavior"
  artifacts:
    - path: "lib/features/wardrobe/wardrobe_screen.dart"
      provides: "Type filter chip row + filter logic + updated empty state"
      contains: "_selectedTypes"
  key_links:
    - from: "_selectedTypes (Set<String>)"
      to: "docs filter in StreamBuilder"
      via: "where clause checking _capitalize(data['type']) membership"
      pattern: "_selectedTypes.contains"
---

<objective>
Add a horizontal scrolling row of FilterChip widgets below the existing color filter dots in WardrobeScreen. Tapping chips toggles clothing type filters (multi-select). When any types are selected only items of those types are shown; when none selected all items are shown. This is a pure UI-side change — no backend work required.

Purpose: Users can zero in on specific clothing categories without leaving the wardrobe screen.
Output: wardrobe_screen.dart with type chip filter row, filter logic, and updated empty state message.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md

<interfaces>
<!-- Key patterns from wardrobe_screen.dart the executor must follow exactly. -->

Existing state variable (single-select color filter — mirror this pattern for types):
```dart
int? _selectedColorIndex;   // null = show all
```

Type filter must use:
```dart
Set<String> _selectedTypes = {};   // empty = show all
```

Canonical type labels (capitalized, matching _capitalize() output and _showEditSheet list):
```dart
const List<String> _typeFilterLabels = [
  'Top', 'Bottom', 'Shoes', 'Outerwear', 'Dress', 'Accessory',
];
```

Color filter row (existing, height 52 — the chip row should follow the same Column order):
```dart
SizedBox(
  height: 52,
  child: ListView.separated(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    ...
  ),
),
```

Existing filter application (inside StreamBuilder, after allDocs):
```dart
final docs = _selectedColorIndex == null
    ? allDocs
    : allDocs.where((doc) {
        final color = (doc.data()['color'] ?? '').toString().toLowerCase();
        return color.contains(_filterColorNames[_selectedColorIndex!]);
      }).toList();
```

Existing empty state message logic:
```dart
_selectedColorIndex == null
    ? 'No clothes yet.\nTap + to add your first item.'
    : 'No items with that color.',
```

Existing _capitalize helper (already in file — do not duplicate):
```dart
String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
```
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add _selectedTypes state and type chip filter row</name>
  <files>lib/features/wardrobe/wardrobe_screen.dart</files>

  <read_first>
    - lib/features/wardrobe/wardrobe_screen.dart — read the FULL file before editing. Understand the Column structure in build(), the location of the color filter SizedBox, and the existing state variables at the top of _WardrobeScreenState.
  </read_first>

  <action>
Make two additions to wardrobe_screen.dart:

**1. Add state variable** — insert directly after `int? _selectedColorIndex;` (line ~44):

```dart
Set<String> _selectedTypes = {};
```

**2. Add type chip filter row** — insert a new `SizedBox` widget in the `Column` children list, immediately AFTER the existing color filter `SizedBox` (which ends around line 125) and BEFORE the `Expanded` StreamBuilder. The new widget:

```dart
// Type filter chips
SizedBox(
  height: 48,
  child: ListView.separated(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    itemCount: _typeFilterLabels.length,
    separatorBuilder: (_, __) => const SizedBox(width: 8),
    itemBuilder: (context, index) {
      final label = _typeFilterLabels[index];
      final selected = _selectedTypes.contains(label);
      return FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() {
          if (selected) {
            _selectedTypes.remove(label);
          } else {
            _selectedTypes.add(label);
          }
        }),
      );
    },
  ),
),
```

**3. Add the constant list** — insert as a static constant inside `_WardrobeScreenState` (alongside `_filterColors` and `_filterColorNames`), or as a top-level private constant just above the class. Either position is fine:

```dart
static const List<String> _typeFilterLabels = [
  'Top', 'Bottom', 'Shoes', 'Outerwear', 'Dress', 'Accessory',
];
```

No other changes in this task.
  </action>

  <verify>
    <automated>grep -n "_selectedTypes" lib/features/wardrobe/wardrobe_screen.dart</automated>
  </verify>

  <acceptance_criteria>
    - `grep "_selectedTypes" lib/features/wardrobe/wardrobe_screen.dart` returns at least 3 lines (declaration, .contains, .remove/.add)
    - `grep "_typeFilterLabels" lib/features/wardrobe/wardrobe_screen.dart` returns at least 2 lines (declaration + use in itemCount/itemBuilder)
    - `grep "FilterChip" lib/features/wardrobe/wardrobe_screen.dart` returns at least 1 line
    - File compiles: `flutter analyze lib/features/wardrobe/wardrobe_screen.dart` exits with no errors (warnings OK)
  </acceptance_criteria>

  <done>State variable declared, constant label list present, FilterChip row renders in the Column between the color dots and the item list.</done>
</task>

<task type="auto">
  <name>Task 2: Apply type filter to item list and update empty state message</name>
  <files>lib/features/wardrobe/wardrobe_screen.dart</files>

  <read_first>
    - lib/features/wardrobe/wardrobe_screen.dart — re-read the full file (it was modified in Task 1). Focus on the StreamBuilder builder body: the color-filter `docs` variable, the `if (docs.isEmpty)` block, and the `grouped` map construction.
  </read_first>

  <action>
Make two changes inside the StreamBuilder `builder:` callback, after the existing color filter produces `docs`:

**1. Chain type filter after color filter** — The existing code produces a `docs` list after the color filter. Add a second filter step immediately after. Replace:

```dart
// Apply color filter
final docs = _selectedColorIndex == null
    ? allDocs
    : allDocs.where((doc) {
        final color =
            (doc.data()['color'] ?? '').toString().toLowerCase();
        return color
            .contains(_filterColorNames[_selectedColorIndex!]);
      }).toList();
```

With:

```dart
// Apply color filter
final colorFiltered = _selectedColorIndex == null
    ? allDocs
    : allDocs.where((doc) {
        final color =
            (doc.data()['color'] ?? '').toString().toLowerCase();
        return color
            .contains(_filterColorNames[_selectedColorIndex!]);
      }).toList();

// Apply type filter
final docs = _selectedTypes.isEmpty
    ? colorFiltered
    : colorFiltered.where((doc) {
        final type = _capitalize(
            (doc.data()['type'] ?? '').toString());
        return _selectedTypes.contains(type);
      }).toList();
```

**2. Update the empty state message** — The existing empty state ternary checks only `_selectedColorIndex`. Extend it to also handle type-filter-only and combined filter cases. Replace:

```dart
_selectedColorIndex == null
    ? 'No clothes yet.\nTap + to add your first item.'
    : 'No items with that color.',
```

With:

```dart
(_selectedColorIndex == null && _selectedTypes.isEmpty)
    ? 'No clothes yet.\nTap + to add your first item.'
    : 'No items match the selected filters.',
```

No other changes.
  </action>

  <verify>
    <automated>grep -n "_selectedTypes.isEmpty\|colorFiltered\|No items match" lib/features/wardrobe/wardrobe_screen.dart</automated>
  </verify>

  <acceptance_criteria>
    - `grep "colorFiltered" lib/features/wardrobe/wardrobe_screen.dart` returns at least 2 lines (assignment + use as input to type filter)
    - `grep "_selectedTypes.isEmpty" lib/features/wardrobe/wardrobe_screen.dart` returns at least 2 lines (type filter condition + empty state condition)
    - `grep "No items match the selected filters" lib/features/wardrobe/wardrobe_screen.dart` returns 1 line
    - `grep "_selectedColorIndex == null && _selectedTypes.isEmpty" lib/features/wardrobe/wardrobe_screen.dart` returns 1 line
    - `flutter analyze lib/features/wardrobe/wardrobe_screen.dart` exits with no errors
  </acceptance_criteria>

  <done>Type filter is applied after color filter. Empty state message covers all filter combinations. Full wardrobe shown when both filters are clear.</done>
</task>

</tasks>

<verification>
After both tasks complete, verify the full file is healthy:

```
flutter analyze lib/features/wardrobe/wardrobe_screen.dart
```

Expected: no errors. Warnings about print() or similar are acceptable.

Manual smoke-check (checkpoint not required — logic is straightforward state manipulation):
- Hot-reload the app on device/emulator
- Navigate to Wardrobe tab
- Tap "Top" chip → only Top items visible, chip appears selected
- Tap "Bottom" chip → Top AND Bottom items visible
- Tap "Top" again → only Bottom items visible, Top chip deselected
- Tap "Bottom" → all items visible (no chips selected)
- With color filter active AND type chip active → correct intersection shown
- Empty wardrobe OR filter returns no items → "No items match the selected filters." message shown
</verification>

<success_criteria>
1. WARD-01: Tapping one or more type chips filters wardrobe to only items of the selected types
2. WARD-02: Tapping a selected chip again removes it from the active filter
3. WARD-03: When no chips are selected, all items are shown (same as original behavior)
4. No regressions: color filter still works independently, grouping by type still renders, edit/delete still work
5. `flutter analyze` reports no new errors on wardrobe_screen.dart
</success_criteria>

<output>
After completion, create `.planning/phases/01-wardrobe-type-filter/01-01-SUMMARY.md` using the summary template at `@$HOME/.claude/get-shit-done/templates/summary.md`.
</output>
