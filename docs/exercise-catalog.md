# GymTime — Default Exercise Catalog (v3 proposal)

**You edit this file.** Once it matches what you want shipped, ping me
and I'll generate `SeedLoader` v3 entries from it.

## Format

One row per exercise. Columns:

- **Name** — display name. Will appear in the Library and in workouts.
  Edit freely; case is preserved.
- **Equipment** — must be one of: `Barbell`, `Dumbbell`, `Machine`,
  `Cable`, `Bodyweight`, `Kettlebell`. (These map to the `Equipment` enum.)
- **In Library** — `Yes` (visible in Library list by default) or `No`
  (seeded but dimmed/hidden — toggleable later via the Library checkbox).

To add an exercise: insert a row in the right group.
To remove one: delete its row.
To move between muscle groups: cut the row and paste under the new heading.
The primary muscle group is determined by which heading the row sits under.
Secondary muscles are not seeded here — kept simple for v3. (You can
re-tag them in ExerciseEditView after install.)

---

## Chest (12)

| Name | Equipment | In Library |
|---|---|---|
| Barbell Bench Press | Barbell | Yes |
| Machine Bench Press | Machine | Yes |
| Dumbbell Bench Press | Dumbbell | Yes |
| Incline Barbell Bench Press | Barbell | Yes |
| Incline Machine Bench Press | Machine | Yes |
| Incline Dumbbell Press | Dumbbell | Yes |
| Decline Barbell Bench Press | Barbell | Yes |
| Decline Dumbbell Bench Press | Dumbbell | Yes |
| Decline Machine Bench Press | Machine | Yes |
| Dumbbell Fly | Dumbbell | Yes |
| Cable Fly | Cable | Yes |
| Pec Deck | Machine | Yes |
| Push-up | Bodyweight | Yes |
| Machine Dip (chest) | Machine | Yes |
| Weighted Dip (chest) | Bodyweight | Yes |

## Back (12)

| Name | Equipment | In Library |
|---|---|---|
| Lat Pulldown | Cable | Yes |
| Seated Cable Row | Cable | Yes |
| Machine Lat Pulldown | Machine | Yes |
| Machine Seated Row | Machine | Yes |
| Barbell Row | Barbell | Yes |
| Dumbbell Row | Dumbbell | Yes |
| Pull-up | Bodyweight | Yes |
| Chin-up | Bodyweight | Yes |
| Weighted Pull-up | Bodyweight | Yes |
| Face Pull | Cable | Yes |

## Shoulders (10)

| Name | Equipment | In Library |
|---|---|---|
| Overhead Machine Press | Machine | Yes |
| Overhead Press | Barbell | Yes |
| Seated Dumbbell Press | Dumbbell | Yes |
| Arnold Press | Dumbbell | Yes |
| Lateral Raise | Dumbbell | Yes |
| Cable Lateral Raise | Cable | Yes |
| Front Raise | Dumbbell | Yes |
| Reverse Pec Deck | Machine | Yes |
| Upright Row | Barbell | Yes |

## Triceps (10)

| Name | Equipment | In Library |
|---|---|---|
| Close-Grip Bench Press | Barbell | Yes |
| Seated Cable Triceps Pushdown | Cable | Yes |
| Cable Triceps Pushdown | Cable | Yes |
| Skull Crusher | Barbell | Yes |
| Machine Skull Crusher | Machine | Yes |
| Rope Pushdown | Cable | Yes |
| Overhead Triceps Extension (DB) | Dumbbell | Yes |
| Overhead Cable Extension | Cable | Yes |
| Diamond Push-up | Bodyweight | Yes |
| Weighted Dip (triceps) | Bodyweight | Yes |
| Triceps Kickback | Dumbbell | Yes |
| Bench Dip | Bodyweight | Yes |

## Biceps (10)

| Name | Equipment | In Library |
|---|---|---|
| Barbell Curl | Barbell | Yes |
| EZ-Bar Curl | Barbell | Yes |
| Dumbbell Curl | Dumbbell | Yes |
| Hammer Curl | Dumbbell | Yes |
| Preacher Curl | Barbell | Yes |
| Machine Preacher Curl | Machine | Yes |
| Concentration Curl | Dumbbell | Yes |
| Cable Curl | Cable | Yes |
| Reverse Curl | Barbell | Yes |
| Incline Dumbbell Curl | Dumbbell | Yes |

## Quads (10)

| Name | Equipment | In Library |
|---|---|---|
| Back Squat | Barbell | Yes |
| Front Squat | Barbell | Yes |
| Goblet Squat | Dumbbell | Yes |
| Hack Squat | Machine | Yes |
| Leg Press | Machine | Yes |
| Leg Extension | Machine | Yes |
| Walking Lunge | Dumbbell | Yes |
| Bulgarian Split Squat | Dumbbell | Yes |
| Step-up | Dumbbell | Yes |
| Sissy Squat | Bodyweight | No |

## Hamstrings (10)

| Name | Equipment | In Library |
|---|---|---|
| Romanian Deadlift | Barbell | Yes |
| Stiff-Leg Deadlift | Barbell | Yes |
| Conventional Deadlift | Barbell | Yes |
| Lying Leg Curl | Machine | Yes |
| Seated Leg Curl | Machine | Yes |
| Good Morning | Barbell | Yes |
| Single-Leg Romanian Deadlift | Dumbbell | Yes |
| Glute-Ham Raise | Bodyweight | Yes |
| Cable Pull-Through | Cable | Yes |
| Nordic Curl | Bodyweight | No |

## Glutes (10)

| Name | Equipment | In Library |
|---|---|---|
| Hip Thrust | Barbell | Yes |
| Glute Bridge | Barbell | Yes |
| Cable Kickback | Cable | Yes |
| Sumo Deadlift | Barbell | Yes |
| Single-Leg Hip Thrust | Bodyweight | Yes |
| Curtsy Lunge | Dumbbell | Yes |
| Step-up (glute focus) | Dumbbell | No |
| Reverse Hyperextension | Machine | Yes |
| Banded Clamshell | Bodyweight | No |
| Frog Pump | Bodyweight | No |

## Calves (10)

| Name | Equipment | In Library |
|---|---|---|
| Standing Calf Raise (Barbell) | Barbell | Yes |
| Standing Calf Raise (Machine) | Machine | Yes |
| Seated Calf Raise | Machine | Yes |
| Donkey Calf Raise | Bodyweight | No |
| Single-Leg Calf Raise | Bodyweight | Yes |
| Smith Machine Calf Raise | Machine | Yes |
| Leg Press Calf Raise | Machine | Yes |
| Calf Raise on Step | Bodyweight | Yes |
| Tibialis Raise | Bodyweight | No |
| Jump Rope | Bodyweight | No |

## Core (10)

| Name | Equipment | In Library |
|---|---|---|
| Plank | Bodyweight | Yes |
| Hanging Leg Raise | Bodyweight | Yes |
| Cable Crunch | Cable | Yes |
| Machine Crunch | Machine | Yes |
| Machine Twist | Machine | Yes |
| Seated Back Extension | Machine | Yes |
| Ab Wheel Rollout | Bodyweight | Yes |
| Russian Twist | Dumbbell | Yes |
| Bicycle Crunch | Bodyweight | Yes |
| Side Plank | Bodyweight | Yes |
| Hollow Hold | Bodyweight | Yes |
| Dead Bug | Bodyweight | Yes |
| Mountain Climber | Bodyweight | No |

## Forearms (10)

| Name | Equipment | In Library |
|---|---|---|
| Wrist Curl | Barbell | Yes |
| Reverse Wrist Curl | Barbell | Yes |
| Farmer's Carry | Dumbbell | Yes |
| Plate Pinch | Bodyweight | No |
| Dead Hang | Bodyweight | Yes |
| Towel Pull-up | Bodyweight | No |
| Wrist Roller | Bodyweight | No |
| Behind-the-Back Wrist Curl | Barbell | No |
| Finger Curl | Barbell | No |
| Gripper Squeeze | Bodyweight | No |

---

**Total: 114 exercises** across 11 muscle groups. After your edits, I'll
turn this into `SeedLoader` v3.
