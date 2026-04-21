# GymTime

A strength-training app for one. iPhone + Apple Watch. Big numbers. Quiet timer.
No feed.

Built from the Claude Design handoff at `~/Downloads/GymTime-handoff.zip` —
pixel-perfect port of the prototype into native SwiftUI with real state,
persistence, CloudKit sync, and rest-timer haptics.

## Running it

```bash
# Generate the Xcode project (re-run any time you edit project.yml)
xcodegen generate

# Open in Xcode
open GymTime.xcodeproj

# ⌘R on an iPhone 17 (or later) simulator
```

Targets:

- **GymTime** (iOS 17+) — the iPhone app, embeds the watch companion.
- **GymTimeWatch** (watchOS 10+) — the Apple Watch companion, synced via a
  shared private CloudKit container (`iCloud.com.jsamitt.GymTime`).

CLI build (iOS only):

```bash
xcodebuild -project GymTime.xcodeproj -scheme GymTime \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## iPhone features

- **Home** — PPL routine cards, streak / week / volume stats, alternate templates.
  A lime **"WORKOUT IN PROGRESS · RESUME →"** banner appears when any
  unfinished session exists (including one started from the watch).
- **Workout detail** — exercise list with per-set math + sparklines, drag-to-reorder,
  START WORKOUT.
- **Active Set** — huge weight (168pt) × reps (56pt lime), rest timer with ±30s
  chips, LOG SET / SKIP bar, auto-advance through sets. Tap the weight or reps
  number to open a numpad sheet; ± chips for small bumps.
- **Exit confirm** — ⌄ from the active workout shows **Save & Exit** / **Exit
  Without Saving** (destructive; cascades delete to logs + sets) / **Cancel**.
- **Exercise edit** — tap the Top Working Weight to type a new value, or use ±.
  Auto-computed set table (cold 50% / continuing 75% / loading sets), Epley
  e1RM, per-exercise weight + reps overrides, notes.
- **History** — 14-day heatmap, recent PRs, session list with volume totals.
- **Settings** — defaults, rest timers, active-set toggles, data management.
- **Library** — seeded exercises grouped by muscle, search + filter chips,
  `+` to add new, toggleable "in my library" state (visual dim only — templates
  still reference the exercise).

## Apple Watch features

- **Waiting screen** — "Ready" + a big START WORKOUT button that opens the
  template picker.
- **Template picker** — scrollable list; tap to create a session on the watch.
  Starting any new workout auto-finishes any in-progress session so only one
  active session exists at a time.
- **Active set** — exercise name, weight with − / + circle buttons on either
  side, × reps with − / +, rest timer as a ring around the whole face with
  remaining time in the middle, SKIP / LOG buttons. Haptic fires on your wrist
  when rest ends, even with the screen off (local notification fallback).
- **Congrats** — after the last set, a lime checkmark + total volume + two
  buttons: **NEW WORKOUT** (finishes current, reopens picker) and **EXIT**
  (finishes current, back to the waiting screen).

## Data + sync

- **SwiftData** is the persistence layer on both devices.
- **CloudKit** mirrors the store across the user's iPhone and Apple Watch
  via a shared private container. Requires:
  - iCloud signed in on both devices with the same Apple ID
  - Container `iCloud.com.jsamitt.GymTime` exists in the Apple Developer
    portal and is assigned to both App IDs
- **Rest timer** uses wall-clock `Date()` so it survives view re-renders and
  short backgrounding. A local `UNNotificationRequest` fires the haptic if
  the screen locks before rest ends. Notification permission is requested on
  the first LOG SET tap.
- **Stale session cleanup** — on launch (phone + watch), any unfinished
  session older than 6 hours is marked finished. If multiple unfinished
  sessions exist, only the most recent stays active. Starting a new workout
  from either device also finishes any still-active session first — so only
  one session is ever "in progress."

## What's currently out of scope

- Push notification from iPhone → watch on workout start (watchOS doesn't
  allow force-launch of the companion; CloudKit sync + the Resume banner +
  an optional watch face complication cover the same need).
- Supersets, bodyweight tracking, plate calculator.
- CSV export, Strong import (Settings rows are present but stubbed).
- kg unit switching (Settings row present; swap is a later change).

## Layout

```
GymTime/
  GymTimeApp.swift       @main, ModelContainer + CloudKit, seed + cleanup on launch
  RootView.swift         4-tab shell + sync-status debug badge
  Models/                SwiftData: Exercise, WorkoutTemplate, Session, SetLog, AppSettings
  Logic/                 Math, RestTimerModel, SessionController, SessionCleanup, SeedLoader
  DesignSystem/          GT tokens + components (Stepper, Spark, Pill, StatTile, NumberTypeSheet)
  Screens/               Home, WorkoutDetail, ActiveSet, ExerciseEdit, History, Settings, Library
  Resources/             Inter Tight, Inter, JetBrains Mono .ttf files
  GymTime.entitlements   iCloud + CloudKit

GymTimeWatch/
  GymTimeWatchApp.swift      @main, shared CloudKit container
  WatchRootView.swift        Waiting screen / active session router
  WatchActiveSetView.swift   Active set UI with ± buttons + rest ring
  WatchTemplatePicker.swift  Template list for starting a workout
  Assets.xcassets            App icon
  GymTimeWatch.entitlements  iCloud + CloudKit
```

Tokens live in [GT.swift](GymTime/DesignSystem/GT.swift) and mirror the JS
`GT` object from the prototype's `lib/tokens.jsx`. Colors, type helpers
(`.gtDisplay(size)`, `.gtMono(size)`), and the radii scale (`rSm/rMd/rLg/rXl`)
are the building blocks for every screen. The watch target reuses these via
the `GymTime/DesignSystem/GT.swift` source include in `project.yml`.
