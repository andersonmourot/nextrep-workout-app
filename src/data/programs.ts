import type { Program } from '../types'

export const PROGRAMS: Program[] = [
  {
    id: 'classic-physique',
    name: 'The Classic',
    category: 'Bodybuilding',
    level: 'Advanced',
    goal: 'Build muscle & symmetry',
    coach: 'Coach CBUM',
    durationWeeks: 8,
    daysPerWeek: 5,
    accent: '#355e3b',
    summary: 'A hypertrophy-focused split chasing the golden-era aesthetic — full, balanced, and detailed.',
    description:
      'Train each muscle group with intent across a 5-day split. Controlled tempos and quality reps over ego lifting. Push, Pull, Legs, Upper, then a dedicated Arms & Shoulders day to bring up the details.',
    tags: ['Hypertrophy', 'Split', 'Gym'],
    days: [
      {
        id: 'cp-push',
        name: 'Push',
        focus: 'Chest · Shoulders · Triceps',
        exercises: [
          { exerciseId: 'barbell-bench-press', sets: 4, reps: '6-10', restSec: 150 },
          { exerciseId: 'incline-dumbbell-press', sets: 3, reps: '8-12', restSec: 120 },
          { exerciseId: 'overhead-press', sets: 3, reps: '8-10', restSec: 120 },
          { exerciseId: 'lateral-raise', sets: 4, reps: '12-15', restSec: 60 },
          { exerciseId: 'cable-fly', sets: 3, reps: '12-15', restSec: 60 },
          { exerciseId: 'triceps-pushdown', sets: 3, reps: '10-15', restSec: 60 },
        ],
      },
      {
        id: 'cp-pull',
        name: 'Pull',
        focus: 'Back · Biceps · Rear Delts',
        exercises: [
          { exerciseId: 'pull-up', sets: 4, reps: '6-10', restSec: 120 },
          { exerciseId: 'barbell-row', sets: 4, reps: '8-10', restSec: 120 },
          { exerciseId: 'lat-pulldown', sets: 3, reps: '10-12', restSec: 90 },
          { exerciseId: 'seated-cable-row', sets: 3, reps: '10-12', restSec: 90 },
          { exerciseId: 'face-pull', sets: 3, reps: '15-20', restSec: 60 },
          { exerciseId: 'incline-dumbbell-curl', sets: 3, reps: '10-12', restSec: 60 },
        ],
      },
      {
        id: 'cp-legs',
        name: 'Legs',
        focus: 'Quads · Hamstrings · Calves',
        exercises: [
          { exerciseId: 'back-squat', sets: 4, reps: '6-10', restSec: 180 },
          { exerciseId: 'romanian-deadlift', sets: 3, reps: '8-12', restSec: 120 },
          { exerciseId: 'leg-press', sets: 3, reps: '10-15', restSec: 120 },
          { exerciseId: 'leg-curl', sets: 3, reps: '12-15', restSec: 75 },
          { exerciseId: 'calf-raise', sets: 4, reps: '12-20', restSec: 60 },
        ],
      },
      {
        id: 'cp-upper',
        name: 'Upper',
        focus: 'Chest · Back · Volume',
        exercises: [
          { exerciseId: 'incline-dumbbell-press', sets: 4, reps: '8-12', restSec: 120 },
          { exerciseId: 'seated-cable-row', sets: 4, reps: '10-12', restSec: 90 },
          { exerciseId: 'lat-pulldown', sets: 3, reps: '10-12', restSec: 90 },
          { exerciseId: 'cable-fly', sets: 3, reps: '12-15', restSec: 60 },
          { exerciseId: 'lateral-raise', sets: 4, reps: '12-20', restSec: 60 },
        ],
      },
      {
        id: 'cp-arms',
        name: 'Arms & Shoulders',
        focus: 'Biceps · Triceps · Delts',
        exercises: [
          { exerciseId: 'overhead-press', sets: 4, reps: '8-12', restSec: 120 },
          { exerciseId: 'barbell-curl', sets: 4, reps: '8-12', restSec: 75 },
          { exerciseId: 'skullcrusher', sets: 4, reps: '8-12', restSec: 75 },
          { exerciseId: 'incline-dumbbell-curl', sets: 3, reps: '10-12', restSec: 60 },
          { exerciseId: 'triceps-pushdown', sets: 3, reps: '12-15', restSec: 60 },
          { exerciseId: 'lateral-raise', sets: 4, reps: '15-20', restSec: 45 },
        ],
      },
    ],
  },
  {
    id: 'strength-foundations',
    name: 'Foundation Builder',
    category: 'Strength',
    level: 'Intermediate',
    goal: 'Get stronger on the basics',
    coach: 'Coach CBUM',
    durationWeeks: 6,
    daysPerWeek: 4,
    accent: '#6aa9ff',
    summary: 'An upper/lower strength build centered on heavy compound lifts and smart accessory work.',
    description:
      'Four focused days alternating upper and lower body. Push the main lifts in lower rep ranges and reinforce them with accessories. Built for steady, repeatable progress.',
    tags: ['Compound', 'Upper/Lower', '4-Day'],
    days: [
      {
        id: 'sf-lower-a',
        name: 'Lower A',
        focus: 'Squat focus',
        exercises: [
          { exerciseId: 'back-squat', sets: 5, reps: '5', restSec: 180 },
          { exerciseId: 'romanian-deadlift', sets: 3, reps: '8', restSec: 150 },
          { exerciseId: 'leg-press', sets: 3, reps: '10', restSec: 120 },
          { exerciseId: 'calf-raise', sets: 4, reps: '12', restSec: 60 },
        ],
      },
      {
        id: 'sf-upper-a',
        name: 'Upper A',
        focus: 'Bench focus',
        exercises: [
          { exerciseId: 'barbell-bench-press', sets: 5, reps: '5', restSec: 180 },
          { exerciseId: 'barbell-row', sets: 4, reps: '6-8', restSec: 120 },
          { exerciseId: 'overhead-press', sets: 3, reps: '8', restSec: 120 },
          { exerciseId: 'lat-pulldown', sets: 3, reps: '10', restSec: 90 },
        ],
      },
      {
        id: 'sf-lower-b',
        name: 'Lower B',
        focus: 'Deadlift focus',
        exercises: [
          { exerciseId: 'deadlift', sets: 4, reps: '4', restSec: 210 },
          { exerciseId: 'goblet-squat', sets: 3, reps: '10', restSec: 120 },
          { exerciseId: 'leg-curl', sets: 3, reps: '12', restSec: 75 },
          { exerciseId: 'hanging-leg-raise', sets: 3, reps: '12', restSec: 60 },
        ],
      },
      {
        id: 'sf-upper-b',
        name: 'Upper B',
        focus: 'Press & pull volume',
        exercises: [
          { exerciseId: 'overhead-press', sets: 5, reps: '5', restSec: 150 },
          { exerciseId: 'pull-up', sets: 4, reps: '6-10', restSec: 120 },
          { exerciseId: 'incline-dumbbell-press', sets: 3, reps: '10', restSec: 90 },
          { exerciseId: 'barbell-curl', sets: 3, reps: '10', restSec: 60 },
        ],
      },
    ],
  },
  {
    id: 'hiit-shred',
    name: 'HIIT',
    category: 'HIIT',
    level: 'Intermediate',
    goal: 'Burn fat & build conditioning',
    coach: 'Coach CBUM',
    durationWeeks: 4,
    daysPerWeek: 3,
    accent: '#ff6a6a',
    summary: 'Fast-paced circuits that spike the heart rate and torch calories with minimal equipment.',
    description:
      'Three high-intensity sessions per week. Move quickly through each circuit with short rest. Great as a standalone fat-loss block or a conditioning add-on.',
    tags: ['Conditioning', 'Fat Loss', 'Circuit'],
    days: [
      {
        id: 'hs-full-1',
        name: 'Full Body Blitz',
        focus: 'Total body circuit',
        exercises: [
          { exerciseId: 'burpee', sets: 4, reps: '12', restSec: 45 },
          { exerciseId: 'kettlebell-swing', sets: 4, reps: '15', restSec: 45 },
          { exerciseId: 'jump-squat', sets: 4, reps: '15', restSec: 45 },
          { exerciseId: 'mountain-climber', sets: 4, reps: '30', restSec: 30 },
          { exerciseId: 'push-up', sets: 4, reps: '15', restSec: 45 },
        ],
      },
      {
        id: 'hs-lower-2',
        name: 'Lower Burn',
        focus: 'Legs & core',
        exercises: [
          { exerciseId: 'jump-squat', sets: 5, reps: '15', restSec: 40 },
          { exerciseId: 'walking-lunge', sets: 4, reps: '20', restSec: 45 },
          { exerciseId: 'kettlebell-swing', sets: 4, reps: '20', restSec: 40 },
          { exerciseId: 'mountain-climber', sets: 4, reps: '40', restSec: 30 },
          { exerciseId: 'plank', sets: 3, reps: '45s', restSec: 30 },
        ],
      },
      {
        id: 'hs-upper-3',
        name: 'Upper & Abs',
        focus: 'Push, pull, core',
        exercises: [
          { exerciseId: 'push-up', sets: 5, reps: '15', restSec: 40 },
          { exerciseId: 'pull-up', sets: 4, reps: 'AMRAP', restSec: 60 },
          { exerciseId: 'burpee', sets: 4, reps: '10', restSec: 40 },
          { exerciseId: 'hanging-leg-raise', sets: 4, reps: '12', restSec: 45 },
          { exerciseId: 'plank', sets: 3, reps: '60s', restSec: 30 },
        ],
      },
    ],
  },
  {
    id: 'powerlifting-peak',
    name: 'Powerlifting',
    category: 'Powerlifting',
    level: 'Advanced',
    goal: 'Maximize the big three',
    coach: 'Coach CBUM',
    durationWeeks: 6,
    daysPerWeek: 4,
    accent: '#b48cff',
    summary: 'A squat, bench, and deadlift focused block built to drive up your one-rep maxes.',
    description:
      'Heavy main lifts in low rep ranges with targeted accessories to shore up weak points. Rest fully between top sets and prioritize bar speed and technique.',
    tags: ['Powerlifting', 'Max Strength', 'Big Three'],
    days: [
      {
        id: 'pp-squat',
        name: 'Squat Day',
        focus: 'Squat + posterior chain',
        exercises: [
          { exerciseId: 'back-squat', sets: 5, reps: '3', restSec: 240 },
          { exerciseId: 'romanian-deadlift', sets: 3, reps: '6', restSec: 180 },
          { exerciseId: 'leg-press', sets: 3, reps: '8', restSec: 120 },
          { exerciseId: 'plank', sets: 3, reps: '60s', restSec: 60 },
        ],
      },
      {
        id: 'pp-bench',
        name: 'Bench Day',
        focus: 'Bench + triceps',
        exercises: [
          { exerciseId: 'barbell-bench-press', sets: 5, reps: '3', restSec: 240 },
          { exerciseId: 'overhead-press', sets: 3, reps: '6', restSec: 150 },
          { exerciseId: 'skullcrusher', sets: 3, reps: '8', restSec: 90 },
          { exerciseId: 'barbell-row', sets: 3, reps: '8', restSec: 120 },
        ],
      },
      {
        id: 'pp-deadlift',
        name: 'Deadlift Day',
        focus: 'Deadlift + back',
        exercises: [
          { exerciseId: 'deadlift', sets: 5, reps: '2', restSec: 240 },
          { exerciseId: 'barbell-row', sets: 4, reps: '6', restSec: 150 },
          { exerciseId: 'lat-pulldown', sets: 3, reps: '10', restSec: 90 },
          { exerciseId: 'hanging-leg-raise', sets: 3, reps: '12', restSec: 60 },
        ],
      },
      {
        id: 'pp-accessory',
        name: 'Accessory Day',
        focus: 'Hypertrophy & weak points',
        exercises: [
          { exerciseId: 'incline-dumbbell-press', sets: 4, reps: '10', restSec: 90 },
          { exerciseId: 'leg-press', sets: 4, reps: '12', restSec: 90 },
          { exerciseId: 'seated-cable-row', sets: 4, reps: '12', restSec: 75 },
          { exerciseId: 'barbell-curl', sets: 3, reps: '12', restSec: 60 },
          { exerciseId: 'triceps-pushdown', sets: 3, reps: '12', restSec: 60 },
        ],
      },
    ],
  },
  {
    id: 'home-bodyweight',
    name: 'At Home: Bodyweight',
    category: 'Bodyweight',
    level: 'Beginner',
    goal: 'Train anywhere, no gym',
    coach: 'Coach CBUM',
    durationWeeks: 4,
    daysPerWeek: 4,
    accent: '#5ad19b',
    summary: 'No equipment, no excuses. Build strength and conditioning using just your bodyweight.',
    description:
      'A four-day bodyweight plan you can do at home or while traveling. Focus on clean reps, full range of motion, and progressively adding reps each week.',
    tags: ['No Equipment', 'Home', 'Beginner'],
    days: [
      {
        id: 'hb-push',
        name: 'Push',
        focus: 'Chest · Shoulders · Triceps',
        exercises: [
          { exerciseId: 'push-up', sets: 4, reps: '12-20', restSec: 60 },
          { exerciseId: 'plank', sets: 3, reps: '45s', restSec: 45 },
          { exerciseId: 'mountain-climber', sets: 3, reps: '30', restSec: 45 },
        ],
      },
      {
        id: 'hb-legs',
        name: 'Legs',
        focus: 'Quads · Glutes · Calves',
        exercises: [
          { exerciseId: 'goblet-squat', sets: 4, reps: '15', restSec: 60 },
          { exerciseId: 'walking-lunge', sets: 3, reps: '20', restSec: 60 },
          { exerciseId: 'jump-squat', sets: 3, reps: '15', restSec: 60 },
          { exerciseId: 'calf-raise', sets: 4, reps: '20', restSec: 45 },
        ],
      },
      {
        id: 'hb-pull',
        name: 'Pull & Core',
        focus: 'Back · Biceps · Abs',
        exercises: [
          { exerciseId: 'pull-up', sets: 4, reps: 'AMRAP', restSec: 75 },
          { exerciseId: 'hanging-leg-raise', sets: 3, reps: '12', restSec: 60 },
          { exerciseId: 'plank', sets: 3, reps: '60s', restSec: 45 },
        ],
      },
      {
        id: 'hb-conditioning',
        name: 'Conditioning',
        focus: 'Full body burn',
        exercises: [
          { exerciseId: 'burpee', sets: 5, reps: '10', restSec: 45 },
          { exerciseId: 'jump-squat', sets: 4, reps: '15', restSec: 45 },
          { exerciseId: 'mountain-climber', sets: 4, reps: '40', restSec: 30 },
          { exerciseId: 'push-up', sets: 4, reps: '15', restSec: 45 },
        ],
      },
    ],
  },
  {
    id: 'functional-athlete',
    name: 'Functional Building',
    category: 'Functional',
    level: 'Intermediate',
    goal: 'Move better & build power',
    coach: 'Coach CBUM',
    durationWeeks: 5,
    daysPerWeek: 3,
    accent: '#ffa14d',
    summary: 'Blend strength, power, and conditioning to build a resilient, athletic body.',
    description:
      'Three full-body sessions mixing compound strength, explosive power, and conditioning finishers. Designed to carry over to sport and everyday life.',
    tags: ['Athletic', 'Power', 'Full Body'],
    days: [
      {
        id: 'fa-day1',
        name: 'Power & Pull',
        focus: 'Explosive + back',
        exercises: [
          { exerciseId: 'deadlift', sets: 4, reps: '5', restSec: 180 },
          { exerciseId: 'kettlebell-swing', sets: 4, reps: '15', restSec: 75 },
          { exerciseId: 'pull-up', sets: 4, reps: '8', restSec: 90 },
          { exerciseId: 'plank', sets: 3, reps: '60s', restSec: 45 },
        ],
      },
      {
        id: 'fa-day2',
        name: 'Push & Carry',
        focus: 'Press + conditioning',
        exercises: [
          { exerciseId: 'overhead-press', sets: 4, reps: '6', restSec: 150 },
          { exerciseId: 'incline-dumbbell-press', sets: 3, reps: '10', restSec: 90 },
          { exerciseId: 'walking-lunge', sets: 3, reps: '20', restSec: 75 },
          { exerciseId: 'mountain-climber', sets: 3, reps: '40', restSec: 45 },
        ],
      },
      {
        id: 'fa-day3',
        name: 'Legs & Engine',
        focus: 'Lower power + cardio',
        exercises: [
          { exerciseId: 'back-squat', sets: 4, reps: '6', restSec: 180 },
          { exerciseId: 'jump-squat', sets: 4, reps: '12', restSec: 75 },
          { exerciseId: 'romanian-deadlift', sets: 3, reps: '10', restSec: 90 },
          { exerciseId: 'burpee', sets: 4, reps: '12', restSec: 45 },
        ],
      },
    ],
  },
]

export const PROGRAM_MAP: Record<string, Program> = Object.fromEntries(
  PROGRAMS.map((p) => [p.id, p]),
)

export function getProgram(id: string): Program | undefined {
  return PROGRAM_MAP[id]
}
