# What's New in GymTime

A plain-English summary of everything that's changed today.

## During a workout

- **Smarter set names.** Set labels now adapt to how many sets you're doing
  per exercise:
  - 1 set: `Set 1`
  - 2 sets: `Warmup`, `Load`
  - 3 sets: `Warmup`, `Load 1`, `Load 2`
  - 4 sets (default): `Warmup 1`, `Warmup 2`, `Load 1`, `Load 2`
  - 5+ sets: warmups capped at two; the rest are loads.

- **Set count is yours to choose.** Set a global default in Settings →
  DEFAULTS → "Sets per exercise" (1–7). Want a particular exercise to be
  different? Open it in Library → flip "Use default" off → set a
  per-exercise count.

- **Skip the first warmup on repeat-muscle exercises.** New Settings toggle
  ("Perform Warmup 1 only on first exercise per muscle"). When on, any
  exercise with 4+ sets that comes after another same-muscle exercise drops
  its leading warmup. Bench Press still does Warmup 1 → Warmup 2 → Load 1 →
  Load 2; Incline Bench right after only does Warmup → Load 1 → Load 2.

- **Live Activity on your lock screen.** When you start a workout, your
  lock screen and Dynamic Island show the current exercise, weight × reps,
  set label combined with position (`WARMUP 2 · 3 of 4`), and a live
  countdown for your rest timer. When rest hits zero, a green "REST DONE /
  GO" pulse flashes for a few seconds.

- **Quieter phone alerts.** The rest-complete notification is now silent
  and passive on the iPhone — no banner break-through, no chime. A paired
  watch still receives the mirror and plays its haptic.

- **See your whole workout without leaving it.** New list-icon button in
  the active-set header opens an overview sheet showing every exercise and
  every set in this session — completed, current, upcoming, skipped — with
  the current set highlighted lime.

- **Next-up hint.** Small `NEXT · …` caption under the current exercise
  name tells you what's coming up. Hidden on the last exercise.

- **Swap an exercise mid-workout.** ⋯ menu → "Swap exercise" lets you
  substitute another exercise from the same primary muscle group. Already-
  logged sets from the original exercise stay in your history.

- **Add an exercise on the fly.** ⋯ menu → "Add exercise to workout"
  inserts another exercise after the current one. Or finish your workout
  and tap **ADD EXERCISE** on the completion screen.

- **Smart weight progression.** Loading Set 2 (and beyond) is automatically
  locked to be at least as heavy as Loading Set 1. Bump Load 1 up and Load
  2 follows; you can't accidentally drop Load 2 below Load 1.

- **Auto top-set carryforward.** When you finish a workout, the final
  loading-set weight becomes the new "top working weight" on that exercise.
  Next session's warmups recalculate from the new baseline — no manual
  bookkeeping.

- **Clear exit options.** Tap the chevron-down to leave an active workout
  and you get **Save & Exit** (you can resume from the Home screen),
  **Exit Without Saving** (deletes the session entirely), or **Cancel**.

## Library

- **Two drawers: Routines and Exercises.** Tap a drawer to open it; the
  other closes. The last-opened drawer is remembered the next time you
  visit Library.

- **Build your own routines from scratch.** Routines drawer → **+ NEW
  ROUTINE** → enter a name and optional description → tap exercises in the
  multi-select picker → Done.

- **Clone any routine as a variant.** Long-press a routine row → "Clone as
  variant…" → name the copy. The new routine starts with the same exercises
  in the same order; edit independently.

- **Reorder routines by drag.** Routines drawer → **Reorder** button →
  drag handles appear. Your order persists across the Home screen.

- **Swipe to delete.** Swipe a routine row left → **Delete** → confirm.
  Your past sessions for that routine remain in History. Same for past
  sessions in the History tab.

- **Edit a routine's name or description in place.** Tap a routine, then
  tap its name or description to edit on the spot.

- **Tap-to-type weight on any exercise.** Library → exercise → tap the big
  Top Working Weight number to type a new value with the numpad.

- **Per-exercise progress chart.** Each exercise's detail screen now
  includes a smooth line + area chart of your final loading-set weight
  over your last 12 sessions.

- **Bigger default exercise catalog.** First-launch now seeds **119
  exercises** across all 11 muscle groups: chest, back, shoulders,
  triceps, biceps, quads, hamstrings, glutes, calves, core, forearms.
  All 11 groups now show up in the filter chips at the top of the
  Exercises drawer.

## Home

- **One scrollable list of routine tiles.** No more "primary three" plus
  smaller "alternate" tiles, no more decorative `NEXT UP →` flag, no more
  unused PPL header row. Each tile shows: routine name, muscle groups,
  exercise count, estimated duration, and last-used relative date.

- **Resume banner.** A lime "WORKOUT IN PROGRESS · RESUME →" banner
  appears whenever an unfinished session exists — including ones you
  started on a paired iCloud device. Tap to jump straight back in.

## History

- **Tap any session for a full breakdown.** A session detail view shows
  total volume, exercise count, and duration up top, then every exercise
  with its logged warmup and loading sets, labeled with the same names
  you saw during the workout.

- **Swipe a session left to delete it.** Confirmation dialog before the
  destructive action.

## Behind the scenes

- **iCloud sync** — your routines, exercises, and history sync across
  your devices via your private iCloud container.

- **Auto-heal stale sessions.** If you walked away from a workout
  yesterday and forgot to finish it, GymTime auto-completes anything
  older than 6 hours on the next launch. The Home screen's Resume banner
  always reflects an actually-active session.

- **Library scrolling fixed.** The Routines drawer was hard to scroll
  vertically because of a gesture conflict. Now it uses iOS's native list
  view — smooth scroll, smooth swipe-to-delete, drag-to-reorder all work
  cleanly.

- **Lock-screen Live Activity stays in sync.** Refresh logic was rebuilt
  so the lock-screen widget always reflects your current state — exercise
  changes, weight/reps edits, rest-time adjustments — without staleness
  at exercise boundaries.

- **Set position next to the label.** The Live Activity header now reads
  `WARMUP 2 · 3 of 4` on a single line instead of the position drifting
  to a separate row.
