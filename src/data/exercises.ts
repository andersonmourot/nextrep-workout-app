import type { Exercise, PlannedExercise } from '../types'

export const EXERCISES: Exercise[] = [
  {
    id: 'barbell-bench-press',
    name: 'Barbell Bench Press',
    primaryMuscle: 'Chest',
    secondaryMuscles: ['Triceps', 'Shoulders'],
    equipment: 'Barbell',
    difficulty: 'Intermediate',
    instructions: [
      'Lie flat with eyes under the bar, feet planted, shoulder blades pinched.',
      'Unrack and lower the bar under control to mid-chest.',
      'Pause briefly, then press the bar back up over the shoulders.',
      'Keep wrists stacked over elbows throughout.',
    ],
    tips: ['Drive your feet into the floor.', 'Keep a slight arch and tucked elbows (~45°).'],
  },
  {
    id: 'incline-dumbbell-press',
    name: 'Incline Dumbbell Press',
    primaryMuscle: 'Chest',
    secondaryMuscles: ['Shoulders', 'Triceps'],
    equipment: 'Dumbbell',
    difficulty: 'Beginner',
    instructions: [
      'Set bench to 30–45°. Press dumbbells to lockout over the upper chest.',
      'Lower slowly until you feel a stretch across the chest.',
      'Press back up, squeezing the upper pecs.',
    ],
    tips: ['Avoid clanging the dumbbells at the top.', 'Control the eccentric for more tension.'],
  },
  {
    id: 'cable-fly',
    name: 'Cable Fly',
    primaryMuscle: 'Chest',
    secondaryMuscles: ['Shoulders'],
    equipment: 'Cable',
    difficulty: 'Beginner',
    instructions: [
      'Set pulleys to chest height and grab both handles.',
      'With a soft elbow bend, bring hands together in front of you.',
      'Squeeze the chest, then return slowly to the stretch.',
    ],
    tips: ['Think of hugging a tree.', 'Keep elbow angle fixed throughout.'],
  },
  {
    id: 'pull-up',
    name: 'Pull-Up',
    primaryMuscle: 'Back',
    secondaryMuscles: ['Biceps', 'Forearms'],
    equipment: 'Bodyweight',
    difficulty: 'Intermediate',
    instructions: [
      'Hang from the bar with an overhand, shoulder-width grip.',
      'Pull your chest toward the bar by driving elbows down.',
      'Lower under control to a full hang.',
    ],
    tips: ['Lead with the chest, not the chin.', 'Add weight once you can do 10+ clean reps.'],
  },
  {
    id: 'weighted-pull-up',
    name: 'Weighted Pull-Up',
    primaryMuscle: 'Back',
    secondaryMuscles: ['Biceps', 'Forearms'],
    equipment: 'Barbell',
    difficulty: 'Intermediate',
    instructions: [
      'Attach weight using a dip belt, weighted vest, or dumbbell between your feet.',
      'Hang from the bar with an overhand, shoulder-width grip.',
      'Pull your chest toward the bar by driving elbows down.',
      'Lower under control to a full hang.',
    ],
    tips: ['Lead with the chest, not the chin.', 'Increase weight in small increments.'],
  },
  {
    id: 'barbell-row',
    name: 'Barbell Row',
    primaryMuscle: 'Back',
    secondaryMuscles: ['Biceps', 'Core'],
    equipment: 'Barbell',
    difficulty: 'Intermediate',
    instructions: [
      'Hinge to ~45°, keep a flat back and braced core.',
      'Row the bar to your lower ribs/upper abdomen.',
      'Lower under control without rounding the spine.',
    ],
    tips: ['Keep the bar close to your body.', 'Avoid using momentum to heave the weight.'],
  },
  {
    id: 'lat-pulldown',
    name: 'Lat Pulldown',
    primaryMuscle: 'Back',
    secondaryMuscles: ['Biceps'],
    equipment: 'Cable',
    difficulty: 'Beginner',
    instructions: [
      'Grip the bar slightly wider than shoulders.',
      'Pull to your upper chest, driving elbows down and back.',
      'Control the bar back to a full stretch.',
    ],
    tips: ['Avoid leaning back excessively.', 'Squeeze the lats at the bottom.'],
  },
  {
    id: 'close-grip-lat-pulldown',
    name: 'Close Grip Lat Pulldown',
    primaryMuscle: 'Back',
    secondaryMuscles: ['Biceps'],
    equipment: 'Cable',
    difficulty: 'Beginner',
    instructions: [
      'Attach a close-grip (V-bar) handle and grip with palms facing each other.',
      'Pull to your upper chest, driving elbows down and back.',
      'Control the bar back to a full stretch.',
    ],
    tips: ['Avoid leaning back excessively.', 'Squeeze the lats at the bottom.'],
  },
  {
    id: 'seated-cable-row',
    name: 'Seated Cable Row',
    primaryMuscle: 'Back',
    secondaryMuscles: ['Biceps', 'Forearms'],
    equipment: 'Cable',
    difficulty: 'Beginner',
    instructions: [
      'Sit tall with a slight knee bend and grab the handle.',
      'Row to your stomach, squeezing the shoulder blades.',
      'Extend the arms forward under control.',
    ],
    tips: ['Keep the torso still.', 'Pause and squeeze at the contraction.'],
  },
  {
    id: 'overhead-press',
    name: 'Standing Overhead Press',
    primaryMuscle: 'Shoulders',
    secondaryMuscles: ['Triceps', 'Core'],
    equipment: 'Barbell',
    difficulty: 'Intermediate',
    instructions: [
      'Start with the bar at shoulder height, elbows under the bar.',
      'Brace and press overhead, moving the head slightly back then forward.',
      'Lock out with the bar over the mid-foot.',
    ],
    tips: ['Squeeze glutes to avoid leaning back.', 'Keep ribs down and core tight.'],
  },
  {
    id: 'lateral-raise',
    name: 'Dumbbell Lateral Raise',
    primaryMuscle: 'Shoulders',
    secondaryMuscles: [],
    equipment: 'Dumbbell',
    difficulty: 'Beginner',
    instructions: [
      'Hold dumbbells at your sides with a slight elbow bend.',
      'Raise the arms out to shoulder height, leading with the elbows.',
      'Lower slowly.',
    ],
    tips: ['Pour the water — pinkies slightly higher.', 'Use a weight you can control.'],
  },
  {
    id: 'face-pull',
    name: 'Cable Face Pull',
    primaryMuscle: 'Shoulders',
    secondaryMuscles: ['Back'],
    equipment: 'Cable',
    difficulty: 'Beginner',
    instructions: [
      'Set a rope at face height.',
      'Pull toward your forehead, separating the rope and flaring the elbows.',
      'Return under control.',
    ],
    tips: ['Great for shoulder health and posture.', 'Pause at peak contraction.'],
  },
  {
    id: 'barbell-curl',
    name: 'Barbell Curl',
    primaryMuscle: 'Biceps',
    secondaryMuscles: ['Forearms'],
    equipment: 'Barbell',
    difficulty: 'Beginner',
    instructions: [
      'Stand tall holding the bar at shoulder width.',
      'Curl the bar up while keeping elbows pinned at your sides.',
      'Lower under control to full extension.',
    ],
    tips: ['Avoid swinging.', 'Squeeze the biceps at the top.'],
  },
  {
    id: 'incline-dumbbell-curl',
    name: 'Incline Dumbbell Curl',
    primaryMuscle: 'Biceps',
    secondaryMuscles: ['Forearms'],
    equipment: 'Dumbbell',
    difficulty: 'Beginner',
    instructions: [
      'Sit back on an incline bench, arms hanging straight down.',
      'Curl the dumbbells, keeping upper arms still.',
      'Lower slowly for a deep stretch.',
    ],
    tips: ['The stretched position is key for growth.', 'Keep shoulders back.'],
  },
  {
    id: 'triceps-pushdown',
    name: 'Triceps Rope Pushdown',
    primaryMuscle: 'Triceps',
    secondaryMuscles: [],
    equipment: 'Cable',
    difficulty: 'Beginner',
    instructions: [
      'Grab the rope with elbows tucked at your sides.',
      'Extend down and spread the rope at the bottom.',
      'Return under control to ~90°.',
    ],
    tips: ['Keep elbows pinned.', 'Squeeze hard at lockout.'],
  },
  {
    id: 'skullcrusher',
    name: 'EZ-Bar Skullcrusher',
    primaryMuscle: 'Triceps',
    secondaryMuscles: [],
    equipment: 'Barbell',
    difficulty: 'Intermediate',
    instructions: [
      'Lie down holding the bar over your forehead.',
      'Lower the bar behind your head by bending the elbows.',
      'Extend back to lockout.',
    ],
    tips: ['Keep upper arms angled back slightly.', 'Control the eccentric.'],
  },
  {
    id: 'dumbbell-skullcrusher',
    name: 'Dumbbell Skullcrusher',
    primaryMuscle: 'Triceps',
    secondaryMuscles: [],
    equipment: 'Dumbbell',
    difficulty: 'Intermediate',
    instructions: [
      'Lie down holding a dumbbell in each hand over your forehead.',
      'Lower the dumbbells behind your head by bending the elbows.',
      'Extend back to lockout.',
    ],
    tips: ['Keep upper arms angled back slightly.', 'Control the eccentric.'],
  },
  {
    id: 'back-squat',
    name: 'Barbell Back Squat',
    primaryMuscle: 'Quads',
    secondaryMuscles: ['Glutes', 'Hamstrings', 'Core'],
    equipment: 'Barbell',
    difficulty: 'Advanced',
    instructions: [
      'Set the bar on your upper traps, brace, and unrack.',
      'Sit down and back until hips are below knees.',
      'Drive up through mid-foot to standing.',
    ],
    tips: ['Keep knees tracking over toes.', 'Maintain a neutral spine.'],
  },
  {
    id: 'leg-press',
    name: 'Leg Press',
    primaryMuscle: 'Quads',
    secondaryMuscles: ['Glutes', 'Hamstrings'],
    equipment: 'Machine',
    difficulty: 'Beginner',
    instructions: [
      'Place feet shoulder-width on the platform.',
      'Lower until knees reach ~90°.',
      'Press back without locking the knees hard.',
    ],
    tips: ['Do not let the lower back round off the pad.', 'Control the descent.'],
  },
  {
    id: 'romanian-deadlift',
    name: 'Romanian Deadlift',
    primaryMuscle: 'Hamstrings',
    secondaryMuscles: ['Glutes', 'Back'],
    equipment: 'Barbell',
    difficulty: 'Intermediate',
    instructions: [
      'Hold the bar at your hips with a flat back.',
      'Push hips back, lowering the bar along your legs.',
      'Drive hips forward to stand tall.',
    ],
    tips: ['Feel the hamstring stretch.', 'Keep the bar close to your legs.'],
  },
  {
    id: 'leg-curl',
    name: 'Seated Leg Curl',
    primaryMuscle: 'Hamstrings',
    secondaryMuscles: ['Calves'],
    equipment: 'Machine',
    difficulty: 'Beginner',
    instructions: [
      'Adjust the pad above your heels.',
      'Curl your legs down and back as far as possible.',
      'Return slowly under control.',
    ],
    tips: ['Squeeze the hamstrings at the bottom.', 'Avoid jerking the weight.'],
  },
  {
    id: 'hip-thrust',
    name: 'Barbell Hip Thrust',
    primaryMuscle: 'Glutes',
    secondaryMuscles: ['Hamstrings'],
    equipment: 'Barbell',
    difficulty: 'Intermediate',
    instructions: [
      'Sit with your upper back on a bench, bar over your hips.',
      'Drive through your heels to full hip extension.',
      'Lower under control.',
    ],
    tips: ['Squeeze glutes hard at the top.', 'Keep ribs down, chin tucked.'],
  },
  {
    id: 'walking-lunge',
    name: 'Walking Lunge',
    primaryMuscle: 'Quads',
    secondaryMuscles: ['Glutes', 'Hamstrings'],
    equipment: 'Dumbbell',
    difficulty: 'Beginner',
    instructions: [
      'Hold dumbbells at your sides.',
      'Step forward and lower until both knees are ~90°.',
      'Drive up and step through to the next rep.',
    ],
    tips: ['Keep your torso tall.', 'Control each step.'],
  },
  {
    id: 'calf-raise',
    name: 'Standing Calf Raise',
    primaryMuscle: 'Calves',
    secondaryMuscles: [],
    equipment: 'Machine',
    difficulty: 'Beginner',
    instructions: [
      'Stand with the balls of your feet on the platform.',
      'Rise onto your toes as high as possible.',
      'Lower slowly for a deep stretch.',
    ],
    tips: ['Pause at the top and bottom.', 'Full range beats heavy half reps.'],
  },
  {
    id: 'plank',
    name: 'Plank',
    primaryMuscle: 'Core',
    secondaryMuscles: ['Shoulders'],
    equipment: 'Bodyweight',
    difficulty: 'Beginner',
    instructions: [
      'Set forearms under shoulders, body in a straight line.',
      'Brace the core and squeeze the glutes.',
      'Hold for the prescribed time.',
    ],
    tips: ['Do not let the hips sag.', 'Breathe steadily.'],
  },
  {
    id: 'hanging-leg-raise',
    name: 'Hanging Leg Raise',
    primaryMuscle: 'Core',
    secondaryMuscles: ['Forearms'],
    equipment: 'Bodyweight',
    difficulty: 'Intermediate',
    instructions: [
      'Hang from a bar with a firm grip.',
      'Raise your legs to hip height (or higher) without swinging.',
      'Lower under control.',
    ],
    tips: ['Tilt the pelvis to engage the abs.', 'Avoid using momentum.'],
  },
  {
    id: 'deadlift',
    name: 'Conventional Deadlift',
    primaryMuscle: 'Back',
    secondaryMuscles: ['Glutes', 'Hamstrings', 'Forearms'],
    equipment: 'Barbell',
    difficulty: 'Advanced',
    instructions: [
      'Set up with the bar over mid-foot, shins close.',
      'Brace, take the slack out, and drive the floor away.',
      'Lock out hips and knees together, then control the descent.',
    ],
    tips: ['Keep the bar against your legs.', 'Maintain a neutral spine throughout.'],
  },
  {
    id: 'goblet-squat',
    name: 'Goblet Squat',
    primaryMuscle: 'Quads',
    secondaryMuscles: ['Glutes', 'Core'],
    equipment: 'Dumbbell',
    difficulty: 'Beginner',
    instructions: [
      'Hold a dumbbell at chest height.',
      'Squat down between your knees, keeping the chest up.',
      'Drive up to standing.',
    ],
    tips: ['Great for learning squat mechanics.', 'Keep elbows inside the knees.'],
  },
  {
    id: 'push-up',
    name: 'Push-Up',
    primaryMuscle: 'Chest',
    secondaryMuscles: ['Triceps', 'Shoulders', 'Core'],
    equipment: 'Bodyweight',
    difficulty: 'Beginner',
    instructions: [
      'Set hands slightly wider than shoulders.',
      'Lower until your chest nears the floor, elbows ~45°.',
      'Press back to lockout, keeping a straight body line.',
    ],
    tips: ['Brace the core the whole set.', 'Elevate hands to scale difficulty.'],
  },
  {
    id: 'burpee',
    name: 'Burpee',
    primaryMuscle: 'Full Body',
    secondaryMuscles: ['Chest', 'Quads', 'Core'],
    equipment: 'Bodyweight',
    difficulty: 'Intermediate',
    instructions: [
      'Drop to a squat and kick your feet back to a plank.',
      'Perform a push-up, then jump the feet back in.',
      'Explode up into a jump.',
    ],
    tips: ['Keep a steady rhythm.', 'Scale by removing the jump or push-up.'],
  },
  {
    id: 'mountain-climber',
    name: 'Mountain Climbers',
    primaryMuscle: 'Core',
    secondaryMuscles: ['Shoulders', 'Quads'],
    equipment: 'Bodyweight',
    difficulty: 'Beginner',
    instructions: [
      'Start in a high plank.',
      'Drive one knee toward your chest, then switch rapidly.',
      'Keep hips low and core braced.',
    ],
    tips: ['Maintain a flat back.', 'Move fast but controlled.'],
  },
  {
    id: 'kettlebell-swing',
    name: 'Kettlebell Swing',
    primaryMuscle: 'Glutes',
    secondaryMuscles: ['Hamstrings', 'Core', 'Back'],
    equipment: 'Kettlebell',
    difficulty: 'Intermediate',
    instructions: [
      'Hinge and hike the bell back between your legs.',
      'Snap the hips forward to swing the bell to chest height.',
      'Let it fall and absorb with another hinge.',
    ],
    tips: ['Power comes from the hips, not the arms.', 'Keep a flat back.'],
  },
  {
    id: 'jump-squat',
    name: 'Jump Squat',
    primaryMuscle: 'Quads',
    secondaryMuscles: ['Glutes', 'Calves'],
    equipment: 'Bodyweight',
    difficulty: 'Intermediate',
    instructions: [
      'Squat down to a quarter/half depth.',
      'Explode upward into a jump.',
      'Land softly and immediately descend into the next rep.',
    ],
    tips: ['Absorb the landing with bent knees.', 'Stay light on your feet.'],
  },
  {
    id: 'one-arm-dumbbell-row',
    name: 'One Arm Dumbbell Row',
    primaryMuscle: 'Back',
    secondaryMuscles: ['Biceps', 'Core'],
    equipment: 'Dumbbell',
    difficulty: 'Beginner',
    instructions: [
      'Place one knee and hand on a bench for support, other foot on the floor.',
      'Row the dumbbell to your hip, driving the elbow straight back.',
      'Lower under control to a full arm extension.',
    ],
    tips: ['Keep your torso square to the floor.', 'Avoid rotating the hips to lift the weight.'],
  },
  {
    id: 'dumbbell-incline-wide-curl',
    name: 'Dumbbell Incline Wide Curl',
    primaryMuscle: 'Biceps',
    secondaryMuscles: ['Forearms'],
    equipment: 'Dumbbell',
    difficulty: 'Intermediate',
    instructions: [
      'Sit on an incline bench (45°) with dumbbells hanging at your sides.',
      'Curl both dumbbells outward in a wide arc toward your shoulders.',
      'Squeeze at the top, then lower slowly to the start.',
    ],
    tips: ['Keep your elbows pinned back behind your torso.', 'Use a controlled tempo — no swinging.'],
  },
  {
    id: 'machine-shoulder-press',
    name: 'Machine Shoulder Press',
    primaryMuscle: 'Shoulders',
    secondaryMuscles: ['Triceps'],
    equipment: 'Machine',
    difficulty: 'Beginner',
    instructions: [
      'Adjust the seat so handles are at shoulder height.',
      'Press the handles overhead until arms are nearly locked out.',
      'Lower under control to the starting position.',
    ],
    tips: ['Keep your back against the pad.', 'Avoid arching excessively at lockout.'],
  },
  {
    id: 'cable-upright-rows',
    name: 'Cable Upright Rows',
    primaryMuscle: 'Shoulders',
    secondaryMuscles: ['Biceps'],
    equipment: 'Cable',
    difficulty: 'Beginner',
    instructions: [
      'Attach a straight or EZ bar to a low cable.',
      'Pull the bar straight up along your body to collarbone height, elbows leading.',
      'Lower under control.',
    ],
    tips: ['Keep the bar close to your body.', 'Stop at collarbone height to protect the shoulder joint.'],
  },
  {
    id: 'reverse-pec-deck',
    name: 'Reverse Pec Deck',
    primaryMuscle: 'Shoulders',
    secondaryMuscles: ['Back'],
    equipment: 'Machine',
    difficulty: 'Beginner',
    instructions: [
      'Sit facing the pad with handles at shoulder height.',
      'Open your arms outward in a wide arc, squeezing the rear delts.',
      'Return slowly to the start.',
    ],
    tips: ['Lead with the elbows, not the hands.', 'Avoid using momentum — keep the motion controlled.'],
  },
  {
    id: 'ab-wheel-rollout',
    name: 'Ab Wheel Rollout',
    primaryMuscle: 'Core',
    secondaryMuscles: ['Shoulders'],
    equipment: 'Bodyweight',
    difficulty: 'Intermediate',
    instructions: [
      'Kneel on the floor and grip the ab wheel with both hands.',
      'Roll forward, extending your body as far as you can while maintaining a flat back.',
      'Contract your abs to pull the wheel back to the starting position.',
    ],
    tips: ['Keep your hips from sagging.', 'Start with short range of motion and progress further over time.'],
  },
  {
    id: 'dumbbell-romanian-deadlift',
    name: 'Dumbbell Romanian Deadlift',
    primaryMuscle: 'Hamstrings',
    secondaryMuscles: ['Glutes', 'Back'],
    equipment: 'Dumbbell',
    difficulty: 'Beginner',
    instructions: [
      'Hold dumbbells in front of your thighs with a slight knee bend.',
      'Hinge at the hips and lower the dumbbells along your legs until you feel a stretch in the hamstrings.',
      'Drive your hips forward to return to standing.',
    ],
    tips: ['Keep the dumbbells close to your legs.', 'Avoid rounding your lower back.'],
  },
  {
    id: 'dumbbell-bulgarian-split-squat',
    name: 'Dumbbell Bulgarian Split Squat',
    primaryMuscle: 'Quads',
    secondaryMuscles: ['Glutes', 'Hamstrings'],
    equipment: 'Dumbbell',
    difficulty: 'Intermediate',
    instructions: [
      'Stand a stride-length in front of a bench and rest one foot on it behind you.',
      'Hold a dumbbell in each hand and lower until the front thigh is parallel to the floor.',
      'Drive through the front heel to return to the top.',
    ],
    tips: ['Keep your torso upright.', 'Make sure the front knee tracks over the toes without caving in.'],
  },
  {
    id: 'single-leg-extensions',
    name: 'Single Leg Extensions',
    primaryMuscle: 'Quads',
    secondaryMuscles: [],
    equipment: 'Machine',
    difficulty: 'Beginner',
    instructions: [
      'Sit in the leg extension machine and hook one foot under the pad.',
      'Extend your leg until the knee is nearly locked out.',
      'Lower under control and repeat before switching legs.',
    ],
    tips: ['Squeeze the quad hard at the top.', 'Use a controlled tempo — don\u2019t swing the weight.'],
  },
  {
    id: 'hammer-preacher-curl',
    name: 'Hammer Preacher Curl',
    primaryMuscle: 'Biceps',
    secondaryMuscles: ['Forearms'],
    equipment: 'Dumbbell',
    difficulty: 'Beginner',
    instructions: [
      'Sit at a preacher bench with a dumbbell in each hand, palms facing each other (neutral grip).',
      'Curl the dumbbells up toward your shoulders without rotating the wrists.',
      'Lower under control to a full arm extension.',
    ],
    tips: ['Keep your upper arms pressed into the pad.', 'Avoid using momentum to lift.'],
  },
  {
    id: 'cable-fly-low-to-high',
    name: 'Cable Fly Low to High',
    primaryMuscle: 'Chest',
    secondaryMuscles: ['Shoulders'],
    equipment: 'Cable',
    difficulty: 'Intermediate',
    instructions: [
      'Set both pulleys to the lowest position and grab a handle in each hand, palms facing forward.',
      'Step forward with a slight forward lean and arms down at your sides.',
      'Sweep your hands up and together in an arc to about eye level, squeezing the upper chest.',
      'Lower under control back to the starting position.',
    ],
    tips: ['Keep a soft bend in the elbows throughout.', 'Lead with the upper chest, not the front delts.'],
  },
]

export const EXERCISE_MAP: Record<string, Exercise> = Object.fromEntries(
  EXERCISES.map((e) => [e.id, e]),
)

// User-created exercises, mirrored here from the store so the synchronous
// lookups below (used app-wide) can resolve them without prop-drilling.
let CUSTOM_EXERCISES: Exercise[] = []

// Per-user edits to built-in exercises, keyed by exercise id. An override
// fully replaces the built-in definition while the original stays intact.
let OVERRIDES: Record<string, Exercise> = {}

export function setCustomExercises(list: Exercise[]): void {
  CUSTOM_EXERCISES = Array.isArray(list) ? list : []
}

export function setExerciseOverrides(map: Record<string, Exercise>): void {
  OVERRIDES = map && typeof map === 'object' ? map : {}
}

/** Built-in library with any per-user overrides applied. */
function builtinsWithOverrides(): Exercise[] {
  return EXERCISES.map((e) => OVERRIDES[e.id] ?? e)
}

/** All exercises available to the current user: custom first, then built-ins. */
export function allExercises(): Exercise[] {
  return [...CUSTOM_EXERCISES, ...builtinsWithOverrides()]
}

export function getExercise(id: string): Exercise | undefined {
  return CUSTOM_EXERCISES.find((e) => e.id === id) ?? OVERRIDES[id] ?? EXERCISE_MAP[id]
}

/** Find an exercise (custom or built-in) by its display name (case-insensitive). */
export function findExerciseByName(name: string): Exercise | undefined {
  const q = name.trim().toLowerCase()
  if (!q) return undefined
  return (
    CUSTOM_EXERCISES.find((e) => e.name.toLowerCase() === q) ??
    builtinsWithOverrides().find((e) => e.name.toLowerCase() === q)
  )
}

/**
 * Resolve a planned exercise to a library entry. Prefer the stored id; if that
 * doesn't resolve (e.g. a typed-only "custom-…" placeholder that predates the
 * exercise card), fall back to matching the saved name. This makes a program
 * entry connect to a card automatically as soon as the card exists — no need
 * to retype it.
 */
export function resolvePlannedExercise(
  pe: Pick<PlannedExercise, 'exerciseId' | 'name'>,
): Exercise | undefined {
  return getExercise(pe.exerciseId) ?? (pe.name ? findExerciseByName(pe.name) : undefined)
}

/** Display label for a planned exercise: custom name, else the built-in name, else the id. */
export function exerciseLabel(pe: Pick<PlannedExercise, 'exerciseId' | 'name'>): string {
  const custom = pe.name?.trim()
  if (custom) return custom
  return getExercise(pe.exerciseId)?.name ?? pe.exerciseId
}
