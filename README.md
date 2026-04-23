# GymTime

A strength-training iOS app for one. Big numbers. Quiet timer. No feed.

Built from the Claude Design handoff at `~/Downloads/GymTime-handoff.zip` —
pixel-perfect port of the prototype into native SwiftUI with real state,
persistence, a Live Activity on the lock screen, and rest-timer haptics.

## Running it

```bash
# Generate the Xcode project (re-run any time you edit project.yml)
xcodegen generate

# Open in Xcode
open GymTime.xcodeproj

# ⌘R on an iPhone 17 (or later) simulator — make sure the scheme is
# "GymTime" (not "GymTimeWidgetExtension"), destination is your phone.
```

Targets:

- **GymTime** (iOS 17+) — the main app.
- **GymTimeWidgetExtension** (iOS 17+) — widget/Live Activity extension,
  embedded in the app bundle. Renders the lock-screen banner + Dynamic Island.

CLI smoke build:

```bash
xcodebuild -project GymTime.xcodeproj -scheme GymTime \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## Features

### Home (Train tab)
- PPL routine cards sorted by `WorkoutTemplate.order`, streak / this-week /
  volume stats, alternate-template row for anything past the first 3.
- Lime **"WORKOUT IN PROGRESS · RESUME →"** banner whenever an unfinished
  session exists; tapping resumes straight into the active set.

### Active Set
- Huge 168pt weight × 56pt lime reps. Tap either number for a numpad
  sheet; ± chips for one-weight-step / one-rep bumps.
- Rest timer in blue with ±30s chips and a wall-clock source so short
  backgrounding doesn't desync.
- **Loading-set progression invariant** — loading set 2 is always ≥ loading
  set 1 (enforced on every ± or numpad edit). If you bump set 1 up, set 2
  follows.
- **Swap exercise mid-workout** — ⋯ menu → "Swap exercise" opens a picker
  filtered to the same primary muscle group (excluding exercises already
  in this session). If no sets were logged on the current exercise, it's
  an in-place replace. If anything's logged, a new ExerciseLog is inserted
  so the original's history stays intact.
- **Exit confirm** — ⌄ chevron → **Save & Exit** / **Exit Without Saving**
  (destructive, cascades delete of logs + sets) / **Cancel**.
- **Auto-carryforward** — finishing a workout sets each
  `Exercise.topWorkingWeight` to its last logged loading set, so next
  session's warmup math flows from the new top.

### Live Activity
- Starts when the Active Set screen opens, ends when it closes / the
  workout is finished or abandoned.
- Lock screen: exercise name, set label, weight × reps, live-ticking rest
  countdown (uses `Text(timerInterval:)` so the widget ticks without the
  app pushing an update every second).
- Dynamic Island: compact (weight or rest time) / expanded (full details)
  / minimal (dumbbell vs. timer icon) variants.
- Updates reflect weight/reps edits, cursor advances after LOG/SKIP, and
  mid-workout swaps.

### Library (two-drawer layout)
- Top-level Library screen with two expandable drawers — **Routines** and
  **Exercises**. Only one is open at a time; the last-opened drawer is
  remembered across launches via `@AppStorage`.
- **Routines drawer:**
  - Tap a row → opens the routine detail (rename, add/remove/reorder
    exercises, start workout).
  - Swipe a row left → red Delete with a confirmation dialog. Past
    sessions that reference the deleted routine stay intact since
    `Session.templateName` is a snapshot string.
  - Long-press → **Clone as variant…** with a prompted name (default:
    `{original} Copy`). Clones the TemplateExercise links in order.
  - **+ NEW ROUTINE** → name + optional description form → save → multi-
    select exercise picker → Done.
  - **Reorder** toggle → drag-to-reorder; `order` persists and drives
    Home's primary-vs-alternate split.
- **Exercises drawer** — the classic library: search, muscle-group filter
  chips, `+` to add, tap a row to edit. Checkbox to toggle `isInLibrary`
  (visual dim flag only; templates still reference the exercise).

### Exercise edit
- Tap Top Working Weight to type a new value; ± steps too.
- Per-exercise warmup weight overrides, reps overrides, muscle-group chips.
- **PROGRESS · LOADING SET** — Charts-based line/area graph of the final
  loading-set weight across the last 12 finished sessions.
- Notes, template membership, delete.

### Workout detail
- Tap the routine name or subtitle to rename (keyboard Done or focus-loss
  commits). Works for user-created routines and seeded ones alike.
- Exercise list with drag-to-reorder, context-menu for edit/reorder/remove,
  "+ Add exercise" opens the library picker.

### History
- 14-day consistency heatmap, streak count, recent PRs, session list.
- Swipe a session left → red Delete with confirmation. Cascade removes
  the session's logs + sets; stats recompute.
- Tap a session → **SessionDetailView** with summary tiles (volume /
  exercises / duration) and per-exercise loading + warmup sets, skipped
  count, and top-weight callout.

### Settings
- Defaults (units, weight step, rep step), rest-timer durations per set
  kind, active-set toggles, data management.

## Data + sync

- **SwiftData** on-device persistence.
- **CloudKit** private mirror via `iCloud.com.jsamitt.GymTime` so the
  app's store is backed up and shareable across your own devices.
- **Stale session cleanup** — on launch, any unfinished session older than
  6 hours is finished; if multiple unfinished sessions exist, only the most
  recent stays active. Starting a new workout from the phone also finishes
  any still-active session first so only one session is ever "in progress."
- **Rest timer haptic** — fires a local `UNNotificationRequest` scheduled
  at rest end, so the vibration happens even if the screen is off or the
  app is backgrounded. iOS mirrors the notification to a paired Apple Watch
  automatically — no watch target required.

## Out of scope

- Push from iPhone → Watch on workout start (not possible without a
  watch companion, and iOS's notification mirroring already covers the
  haptic case).
- Supersets, bodyweight tracking, plate calculator.
- CSV export, Strong import (Settings rows are present but stubbed).
- kg unit switching (Settings row present; swap is a later change).

## Layout

```
GymTime/
  GymTimeApp.swift           @main, ModelContainer + CloudKit, seed + cleanup on launch
  RootView.swift             4-tab shell
  Models/                    SwiftData: Exercise, WorkoutTemplate, TemplateExercise,
                             Session, ExerciseLog, SetLog, AppSettings
  Logic/
    Math.swift               Epley 1RM, weight rounding, warmup percentages
    RestTimerModel.swift     Wall-clock rest timer + UN notification fallback
    SessionController.swift  Set building, cursor, log/skip, finish (auto-carryforward),
                             abandon, swap-current-exercise
    SessionCleanup.swift     Launch-time stale session healing
    SeedLoader.swift         First-launch seed data
    GymTimeActivityAttributes.swift  Shared with widget extension
    LiveActivityController.swift     Single in-flight Live Activity lifecycle
  DesignSystem/
    GT.swift                 Tokens: colors, fonts, radii
    Components/              Stepper, Spark, Pill, StatTile, NumberTypeSheet,
                             SwipeToDeleteRow
  Screens/
    HomeView.swift           Train tab + Resume banner
    WorkoutDetailView.swift  Routine detail + rename inline
    ActiveSetView.swift      Live set UI + Live Activity bridge + swap + exit-confirm
    ExerciseEditView.swift   Exercise editor + Charts trend graph
    ExerciseSwapPicker.swift Mid-workout swap picker
    HistoryView.swift        Heatmap + sessions (swipe-to-delete)
    SessionDetailView.swift  Drill-down for a past session
    LibraryView.swift        Drawer container + ExercisesPane
    RoutinesPane.swift       Routines drawer (reorder / swipe-delete / clone)
    RoutineCreateSheet.swift Name+subtitle form + multi-select exercise picker
    ExercisePickerView.swift Legacy single-exercise picker (add to template)
    SettingsView.swift
  Resources/                 Inter Tight, Inter, JetBrains Mono .ttf files
  GymTime.entitlements       iCloud + CloudKit + push

GymTimeWidget/
  GymTimeWidgetBundle.swift  @main for the widget extension
  GymTimeLiveActivity.swift  ActivityConfiguration: lock screen + Dynamic Island
  Info.plist                 NSExtension / WidgetKit marker
```

Tokens live in [GT.swift](GymTime/DesignSystem/GT.swift) and mirror the JS
`GT` object from the prototype's `lib/tokens.jsx`. Colors, type helpers
(`.gtDisplay(size)`, `.gtMono(size)`), and the radii scale (`rSm/rMd/rLg/rXl`)
are the building blocks for every screen.
