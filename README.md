# GymTime

A strength-training iOS app for one. Big numbers. Quiet timer. No feed.

Built from the Claude Design handoff at `~/Downloads/GymTime-handoff.zip` —
pixel-perfect port of the prototype into native SwiftUI with real state,
persistence, and rest-timer haptics.

## Running it

```bash
# Generate the Xcode project (re-run any time you edit project.yml)
xcodegen generate

# Open in Xcode
open GymTime.xcodeproj

# ⌘R on an iPhone 17 (or later) simulator
```

CLI build (used by CI / quick smoke):

```bash
xcodebuild -project GymTime.xcodeproj -scheme GymTime \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## What's in v1

- **Home** — PPL routine cards, streak / week / volume stats, alternate templates.
- **Workout detail** — exercise list with per-set math + sparklines, START WORKOUT.
- **Active Set (Variant A · Scoreboard)** — huge weight (168pt) × reps (56pt lime),
  rest timer in blue with ±30s chips, LOG SET / SKIP bar, auto-advance through sets.
- **Exercise edit** — top-working-weight stepper, auto-computed set table
  (cold 50% / continuing 75% / loading sets), Epley e1RM, notes.
- **History** — 14-day heatmap, recent PRs, session list with volume totals.
- **Settings** — defaults, rest timers, active-set toggles, data management.
- **Library** — 24 seeded exercises grouped by muscle, search + filter chips,
  `+` to add new, toggleable "in my library" state.

Data is stored with **SwiftData**. Rest timer uses wall-clock `Date()` so it
survives view re-renders and short backgrounding; a local `UNNotificationRequest`
fires the haptic if the screen locks before rest ends. Notification permission
is requested on the first LOG SET tap.

## Out of scope (deferred to v2)

- Supersets, bodyweight tracking, plate calculator
- Variants B (Ring Timer) and C (Set Stack) of the Active Set screen
- CSV export, Strong import (Settings rows are present but stubbed)
- kg unit switching (Settings row present; swap is a later change)

## Layout

```
GymTime/
  GymTimeApp.swift       @main, ModelContainer, seed on first launch
  RootView.swift         4-tab shell
  Models/                SwiftData: Exercise, WorkoutTemplate, Session, SetLog, AppSettings
  Logic/                 Math (Epley, warmup), RestTimerModel, SessionController, SeedLoader
  DesignSystem/          GT tokens (colors, fonts, radii) + components (Stepper, Spark, Pill, StatTile)
  Screens/               Home, WorkoutDetail, ActiveSet, ExerciseEdit, History, Settings, Library
  Resources/             Inter Tight, Inter, JetBrains Mono .ttf files
```

Tokens live in [GT.swift](GymTime/DesignSystem/GT.swift) and mirror the JS
`GT` object from the prototype's `lib/tokens.jsx`. Colors, type helpers
(`.gtDisplay(size)`, `.gtMono(size)`), and the radii scale (`rSm/rMd/rLg/rXl`)
are the building blocks for every screen.
