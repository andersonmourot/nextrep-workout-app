# Exercises Library Implementation

## Summary

I've implemented the Exercises library screen per §7 of the specification.

## Files Created/Modified

### 1. ExercisesView.swift
Complete implementation with:
- **Header**: Title "Exercises" (Oswald), manage toggle (gear → "Done"), primary "+" button that opens Exercise form sheet
- **When managing**: Shows "Hidden (n)" and trash count button (UI placeholders, actions deferred)
- **Search field**: Leading icon, placeholder "Search"
- **Filter chips**: Horizontal scroll with All, Custom, and 12 muscles (Chest, Back, Shoulders, Biceps, Triceps, Quads, Hamstrings, Glutes, Calves, Core, Forearms, Full Body)
  - Selected chip = accent fill + white text
  - "Custom" filters to user-created exercises
- **Count line**: "{n} exercises"
- **Exercise list**: Custom exercises + built-ins (with local overrides), minus hidden, minus trashed
- **Exercise card**: Name (semibold) + "Custom" pill when applicable, chip row {primaryMuscle} (accent) · {equipment} · {difficulty}
- **ExerciseDetailView**: Shows exercise details (name, primary muscle, equipment, difficulty, secondary muscles, instructions, tips)
- **ExerciseFormView**: Form sheet with Name, Primary muscle (picker), Equipment (picker), Difficulty (picker), Secondary muscles (multi-select chips), Instructions (multiline), Coaching cues/tips (multiline), optional Photos (up to two)
- **Save**: Creates/updates custom exercise or local override of built-in

### 2. MainTabView.swift
- Replaced SearchView with ExercisesView in tab bar
- Changed icon to dumbbell
- Changed label to "Exercises"

## Instructions to Add to Xcode Project

**You need to add ExercisesView.swift to the Xcode project manually:**

1. Open Xcode
2. Right-click on the `Views` folder in the project navigator
3. Select "Add Files to NextRepiOS..."
4. Navigate to `NextRepiOS/Views/ExercisesView.swift`
5. Make sure "Copy items if needed" is unchecked
6. Make sure "Add to target: NextRepiOS" is checked
7. Click "Add"

## Theme Integration

All UI elements use the shared Theme:
- Theme.display() for title (Oswald font)
- Theme.body() for body text
- Theme.accent for selected filters and Custom pill
- Theme.text, Theme.textDim, Theme.placeholder for text colors
- Theme.surface for card backgrounds
- Theme.surface2 for search field and unselected chips
- Theme.bg for background

## Features Implemented

- **Filtering**: By muscle group, custom exercises only, or all
- **Search**: Real-time filtering by exercise name
- **Exercise Cards**: Tap to view details, manage mode (UI only)
- **Exercise Form**: Create or edit exercises with all required fields
- **Secondary Muscles**: Multi-select chips excluding primary muscle
- **Instructions & Tips**: Multi-line text editors
- **Photos**: Placeholder for up to two photos (UI only)

## Next Steps

After adding the file to the project:
1. Build the project
2. Navigate to the Exercises tab
3. Test search functionality
4. Test muscle group filters
5. Tap an exercise card to view details
6. Tap "+" to create a new exercise
7. Test the exercise form