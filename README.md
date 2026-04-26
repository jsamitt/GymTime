# GymTime Pro

Private commercial fork of [GymTime](https://github.com/jsamitt/GymTime).
A strength-training iOS app. Big numbers. Quiet timer. No feed. Lock-screen
Live Activity for the active workout.

## Running it

```bash
# Generate the Xcode project (re-run any time you edit project.yml)
xcodegen generate

# Open in Xcode
open GymTime.xcodeproj

# In Xcode: scheme = GymTime (not GymTimeWidgetExtension), destination =
# your iPhone or iPhone 17 simulator, then ⌘R.
```

CLI smoke build:

```bash
xcodebuild -project GymTime.xcodeproj -scheme GymTime \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Targets:

- **GymTime** (iOS 17+) — the main app.
- **GymTimeWidgetExtension** (iOS 17+) — widget/Live Activity bundle,
  embedded in the app. Renders the lock-screen banner + Dynamic Island.

## Repo layout — public vs. private

This is the **private** repo. The public companion at
[github.com/jsamitt/GymTime](https://github.com/jsamitt/GymTime) is licensed
[PolyForm Noncommercial 1.0.0](LICENSE) and frozen at the
mid-development snapshot (commit `55ed538`). Active commercial work happens
here. Do not push commits to the public repo without explicit cherry-pick.

`git remote -v` should show:

- `origin` → `git@github.com:jsamitt/GymTime-Pro.git` (this repo)
- (optional) `public` → `git@github.com:jsamitt/GymTime.git` (frozen mirror)

## Features

### Home (Train tab)

- Streak / week / volume stats.
- **WORKOUT IN PROGRESS · RESUME →** banner whenever an unfinished session
  exists (started from this app on any of your devices that share the
  iCloud account).
- Single scrollable list of routine tiles, ordered by
  `WorkoutTemplate.order` (set in Library → Routines → Reorder). Each tile:
  routine name, muscle groups, exercise count, dynamic estimated duration,
  last-used relative date.

### Active set

- Huge 168pt weight × 56pt lime reps. Tap either number for a numpad sheet;
  ± chips for one-step bumps.
- **Set names track the count** via `SetLabeler`:
  - 1 set → `Set 1`
  - 2 sets → `Warmup`, `Load`
  - 3 sets → `Warmup`, `Load 1`, `Load 2`
  - 4 sets → `Warmup 1`, `Warmup 2`, `Load 1`, `Load 2` (default)
  - 5+ → warmups capped at 2; remainder are loads.
- **NEXT · …** caption under the current exercise name shows the next
  upcoming exercise; hidden on the last.
- **Loading-set progression invariant** — load `N` weight is always ≥ load
  `N-1`. Enforced on every ± or numpad edit.
- **⋯ menu** — *Swap exercise* (same primary muscle group), *Add exercise
  to workout* (any library exercise), or *Exit* (Save & Exit / Exit
  Without Saving / Cancel).
- **VIEW button** — opens a read-only sheet showing every exercise in the
  session, every planned + logged set, with the current cursor highlighted
  lime.
- **Auto-carryforward** — finishing a workout sets each
  `Exercise.topWorkingWeight` to its last logged loading set, so next
  session's warmup math flows from the new top.
- **Extend workout** — when all sets are logged, the finished overlay
  offers ADD EXERCISE (any unused library exercise) alongside DONE.

### Live Activity

- Starts when the Active Set screen opens, ends when it closes / is
  finished or abandoned.
- Lock screen: exercise name, set label combined with position
  (`WARMUP 2 · 3 of 5`), weight × reps, rest countdown via
  `Text(timerInterval:)` so the widget ticks without app pushes.
- Dynamic Island compact / expanded / minimal variants.
- **Flash on rest end** — when the in-process timer fires the app pushes
  `restEndedAt = Date()`. The widget renders a lime "REST DONE / GO"
  pulse for ~4 seconds.
- **Rest notification** — `interruptionLevel = .passive` and
  `sound = nil` to keep the iPhone quiet; the watch still receives the
  mirror and plays its haptic.
- **Reactive refresh** — `pushLiveActivityState` is now wired via
  `.onChange` modifiers on `currentSet?.id`, weight, reps, planned rest,
  timer running, and timer fired. Single source of truth — the LA can't
  go stale at exercise boundaries or after rest-time edits.

### Library (two-drawer layout)

- Top-level Library tab with two expandable drawers — **Routines** and
  **Exercises**. Only one open at a time; last-opened drawer remembered
  across launches via `@AppStorage`.
- **Routines drawer** — native `List` with `.swipeActions` for delete
  (with confirmation) and `.onMove` for drag-to-reorder. Tap a row to open
  WorkoutDetailView. Long-press for context menu (Clone as variant…,
  Delete). **+ NEW ROUTINE** opens a name+description form, then a
  multi-select exercise picker.
- **Exercises drawer** — search bar, horizontally scrollable filter chips
  for all 11 muscle groups, grouped exercise list. Tap any exercise to
  open ExerciseEditView. Checkbox toggles `isInLibrary` (visual dim only).

### Exercise editor

- Tap Top Working Weight to type a new value via a numpad sheet; ± steps
  too.
- **Sets** row: per-exercise `Use default` toggle. When on, the exercise
  uses `AppSettings.defaultTotalSets`. When off, a stepper (1–7) sets the
  per-exercise override.
- Per-set warmup-weight overrides (`Warmup 1` / `Warmup 2`).
- Per-set reps overrides for `Warmup 1`, `Warmup 2`, `Load 1`, `Load 2+`.
- Muscle-group chips, equipment chips, template membership chips.
- **PROGRESS · LOADING SET** — Charts-based line/area graph of the final
  loading-set weight across the last 12 finished sessions.
- Sets preview that reflects what this exercise will produce when used in
  a workout, using the current `Use default` / total-sets state.
- Notes, delete.

### Workout detail

- Tap the routine name or subtitle to rename inline.
- Exercise list with drag-to-reorder, context-menu for edit / reorder /
  remove, and **+ Add exercise** to open the library picker.

### Settings

- **DEFAULTS** — units, warmup percentages (cold / continuing), weight
  step, rep step, **Sets per exercise** (1–7), and a toggle:
  *Perform Warmup 1 only on first exercise per muscle*. When on, any
  exercise with 4+ sets that follows another same-muscle exercise this
  session drops the leading warmup. Total goes 4→3, 5→4, 6→5, etc.; the
  kept warmup uses Warmup-2 settings (75% / 90s rest / 8 reps).
- **REPS PER SET** — Warmup 1 / Warmup 2 / Load 1 / Load 2+ defaults.
- **REST TIMERS** — same four kinds.
- **ACTIVE SET** — haptic toggle, auto-advance toggle, keep-screen-awake
  toggle.
- **DATA** — export / import / reset (stubbed).

### History

- 14-day consistency heatmap, streak count, recent PRs, session list.
- Swipe a session left → red Delete with confirmation.
- Tap a session → SessionDetailView with summary tiles (volume,
  exercises, duration) and per-exercise loading + warmup logs labeled by
  the current SetLabeler scheme.

## Data + sync

- **SwiftData** is the on-device persistence layer.
- **CloudKit** mirrors the private store across the user's iCloud devices
  via `iCloud.com.jsamitt.GymTime`. (Same container the public repo used;
  separate commercial bundle ID will get its own container before launch.)
- **Stale session cleanup** on launch — any unfinished session older than
  6 hours is finished automatically; if multiple unfinished sessions
  exist, only the most recent stays active. Starting a new workout from
  any device finishes any other still-active session first, so only one
  session is ever "in progress."
- **Rest haptic** — the rest timer uses wall-clock `Date()`, surviving
  short backgrounding. A passive `UNNotificationRequest` is scheduled
  silently on the iPhone primarily so a paired Apple Watch can mirror the
  notification and fire its haptic when the screen is off.

## Default exercise catalog (v3)

`SeedLoader` ships ~119 exercises across 11 muscle groups (chest, back,
shoulders, triceps, biceps, quads, hamstrings, glutes, calves, core,
forearms) plus 5 starter templates (Push, Pull, Legs, Upper, Lower).
Source of truth: [`docs/exercise-catalog.md`](docs/exercise-catalog.md) —
edit there, then regenerate `Logic/SeedLoader.swift` accordingly.

The catalog is additive (find-or-create by case-insensitive name), so
existing installs gain new entries without losing user-edited fields like
`topWorkingWeight`. Brand new installs skip legacy v1/v2 entirely and use
v3 only.

## Out of scope (today)

- Apple Watch companion. The original public repo had one but it was
  removed before the v3 work; iOS notification mirroring covers the
  rest-timer haptic case for now. Bringing it back means re-adding a
  watch target + the WatchActiveSet UI. Not currently planned for v1
  commercial release.
- Push from iPhone → Watch on workout start. Apple doesn't allow
  force-launch of a watch companion; CloudKit sync + Resume banner +
  optional complications cover the same need.
- Supersets, bodyweight tracking, plate calculator.
- CSV export, Strong import (Settings rows present but stubbed).
- kg unit switching (Settings row present; swap is a later change).

## Source layout

```
GymTime/
  GymTimeApp.swift           @main, ModelContainer + CloudKit, seed + cleanup on launch
  RootView.swift             4-tab shell
  Models/                    SwiftData: Exercise, WorkoutTemplate, TemplateExercise,
                             Session, ExerciseLog, SetLog, AppSettings
  Logic/
    Math.swift               Epley 1RM, weight rounding, warmup percentages
    RestTimerModel.swift     Wall-clock rest timer + UN notification fallback (passive)
    SessionController.swift  Set building, cursor, log/skip, finish (auto-carryforward),
                             abandon, swap, append-to-active-session
    SessionCleanup.swift     Launch-time stale session healing
    SeedLoader.swift         v3 catalog + templates (additive on existing installs)
    SetLabeler.swift         Set labels (Warmup/Load by count + kind-aware variant)
    GymTimeActivityAttributes.swift  Shared with widget extension
    LiveActivityController.swift     Single in-flight Live Activity lifecycle
  DesignSystem/
    GT.swift                 Tokens: colors, fonts, radii
    Components/              Stepper, Spark, Pill, StatTile, NumberTypeSheet,
                             SwipeToDeleteRow (used by HistoryView; replaced by
                             native List in Routines drawer)
  Screens/
    HomeView.swift           Train tab + Resume banner + uniform routine list
    WorkoutDetailView.swift  Routine detail, inline rename, drag-to-reorder
    ActiveSetView.swift      Live set UI + Live Activity bridge + swap + extend +
                             view-overview + exit-confirm
    ExerciseEditView.swift   Exercise editor + Charts trend graph + Use-default
                             sets toggle
    ExerciseSwapPicker.swift Mid-workout swap picker (same primary muscle)
    HistoryView.swift        Heatmap + sessions (swipe-to-delete)
    SessionDetailView.swift  Drill-down for a past session
    LibraryView.swift        Drawer container + ExercisesPane (full muscle filter)
    RoutinesPane.swift       Routines drawer (native List + swipeActions + onMove)
    RoutineCreateSheet.swift Name+subtitle form + multi-select exercise picker
    SessionExercisePickerSheet.swift  Add-to-active-session picker
    WorkoutOverviewSheet.swift        Read-only "view full workout" sheet
    ExercisePickerView.swift Legacy single-exercise picker (add to template)
    SettingsView.swift
  Resources/                 Inter Tight, Inter, JetBrains Mono .ttf files
  GymTime.entitlements       iCloud + CloudKit + push

GymTimeWidget/
  GymTimeWidgetBundle.swift  @main for the widget extension
  GymTimeLiveActivity.swift  ActivityConfiguration: lock screen + Dynamic Island
  Info.plist                 NSExtension / WidgetKit marker

docs/
  exercise-catalog.md        Editable source-of-truth for SeedLoader v3
```

## License

Proprietary. Copyright © 2026 Jeff Samitt. All rights reserved.

The public mirror at
[github.com/jsamitt/GymTime](https://github.com/jsamitt/GymTime) is
licensed [PolyForm Noncommercial 1.0.0](LICENSE). This repo is the
commercial branch; do not redistribute.
