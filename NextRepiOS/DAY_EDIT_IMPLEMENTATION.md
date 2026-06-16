# Day Edit View Implementation

## Summary

I've implemented the Day review + Day edit screen per §6 of the specification, but the file needs to be added to the Xcode project manually. Here's what was implemented:

## Files Created/Modified

### 1. DayEditView.swift (needs to be added to Xcode project)
A comprehensive Day Edit View with two modes:

**Logging View (default):**
- Icon-only Back button
- Header with eyebrow "Week {weekNum} · Day {dayLocalIdx+1}" in program accent
- Day name (Oswald) and focus
- Edit button (only when program is editable: isCustom && (isOwner || collaborative))
- Local SetLog[][] state pre-filled from existing log or day template
- Exercise cards with:
  - Eyebrow "Exercise {i+1} of {n}"
  - Title exerciseLabel
  - Subtitle "{sets} sets × {reps} reps"
  - Trailing cue+notes+info controls (from §5)
  - Cue subheader (green left-bar line)
  - Set | Weight ({unit}) | Reps | Done table with Stepper controls (weight step 5, reps step 1)
  - Done toggle and completed-row tint
- Full-width primary Save button (shown only when at least one set is completed)
  - Label: "Save Workout" or "Update Workout" when log exists
  - "Saved" + disabled right after saving
- On save: builds WorkoutLog keeping only completed sets, calculates totalVolume, binds to week+day slot via addLog

**Edit Mode (custom programs only):**
- Card titled "Edit this day" with scope note (Week 1 edits whole program; Week N>1 edits "from Week N onward")
- Week selector (segmented control)
- For each exercise in draft:
  - Name text field (type-ahead to library; free text = custom)
  - Caption: "{primaryMuscle} · {equipment}" or "Custom exercise"
  - Up/down reorder buttons (disabled at ends)
  - Cue button
  - Trash button (disabled when one exercise remains)
  - 3-up row: Sets (numeric) / Reps (text) / Rest (numeric seconds) fields
- Add-exercise dashed outline button
- Footer: Cancel (ghost) + Save (primary)
- Validation: at least one exercise, every exercise must have a name
- On save: applies per-week override via withDayOverride, updates program (and apiUpsertProgram when shared/owned), rebuilds local set state, exits edit mode

### 2. AppStore.swift
Added methods:
- `updateProgram(_:)` - Updates custom programs in local state
- `apiUpsertProgram(_:)` - Calls API to upsert program to backend

### 3. APIClient.swift
Added method:
- `upsertProgram(_:)` - POST to /api/programs endpoint

### 4. ProgramDetailView.swift
Added:
- `selectedDayIndex` state variable
- Navigation destination for DayEditView
- Day card button action to navigate to DayEditView

### 5. Helper Functions
Added:
- `programLogSlots(program:logs:)` - Returns array of WorkoutLog? indexed by global day index
- `withDayOverride(program:dayId:weekNum:exercises:)` - Applies week-specific override to program

### 6. ExercisePickerView
A type-ahead exercise picker for the edit mode that:
- Shows search bar
- Lists exercises from catalog
- Displays primaryMuscle and equipment for each
- Calls onSelect callback when exercise is selected

## Instructions to Add to Xcode Project

1. Open Xcode
2. Right-click on the `Views` folder in the project navigator
3. Select "Add Files to NextRepiOS..."
4. Navigate to `NextRepiOS/Views/DayEditView.swift`
5. Make sure "Copy items if needed" is unchecked
6. Make sure "Add to target: NextRepiOS" is checked
7. Click "Add"

The file is ready to compile and will integrate with the existing navigation flow in ProgramDetailView.

## Theme Integration

All UI elements use the shared Theme:
- Theme.accent for program accent color
- Theme.text, Theme.textDim, Theme.placeholder for text colors
- Theme.surface for card backgrounds
- Theme.inputBg for input fields
- Theme.body() and Theme.display() for fonts
- Oswald font for day name

## Next Steps

After adding the file to the project:
1. Build the project
2. Navigate to a Program Detail View
3. Tap a day card to open Day Edit View
4. Test both logging mode (Stepper controls, Save button)
5. Test edit mode (for custom programs only)