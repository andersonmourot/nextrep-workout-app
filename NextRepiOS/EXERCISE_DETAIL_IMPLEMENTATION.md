# Exercise Detail View Implementation (§8)

## Summary

I've updated the ExerciseDetailView to match the §8 specification.

## Changes Made

### ExerciseDetailView.swift (Updated)

**New Features:**
1. **Exercise Resolution**: Resolves exercise as custom → local override → built-in from catalog; shows "not found" + back link if missing
2. **Top Bar**: 
   - Back (arrow) on left
   - Edit button on right (opens §7a Exercise form sheet)
   - Delete button with two-tap confirm (Delete → Confirm/Cancel; deleting returns to library)
3. **Title Block**:
   - Eyebrow {primaryMuscle} in accent color
   - Title name in Oswald 3xl
   - Chip row {equipment} · {difficulty} · each secondary muscle
4. **Notes Section**:
   - Multiline text field bound to shared private exerciseNotes[id]
   - Same note surfaced by §5 pencil everywhere this exercise appears
   - Editing here updates those and vice versa
   - Placeholder: "Add notes for this exercise — form cues, weights to try, reminders…"
5. **Muscle Visual Card**:
   - Soft accent radial-gradient circle
   - Shows primary muscle name in center
6. **How to Perform**:
   - Numbered list from instructions
   - Accent number badges (white text on accent background)
7. **Coaching Cues**:
   - List from tips
   - Each tip is a card with lightbulb icon
8. **Photos**:
   - Placeholder for 2-column grid when photos exist (would need photo storage)

**Technical Implementation:**
- Changed from taking `Exercise` to taking `exerciseId: String`
- Resolves exercise in `resolvedExercise` computed property
- Loads data asynchronously with loading state
- Notes section uses `store.updateExerciseNote()` to persist changes
- Delete removes from `customExercises` array
- Edit opens `ExerciseFormView` sheet

### ExercisesView.swift (Minor Update)

- Updated navigation destination to pass `exerciseId` instead of `exercise` object

## Theme Integration

All UI elements use the shared Theme:
- Theme.display(36) for exercise name (Oswald 3xl)
- Theme.body() for body text
- Theme.accent for primary muscle, number badges, lightbulb icon
- Theme.text, Theme.textDim, Theme.placeholder for text colors
- Theme.surface for card backgrounds
- Theme.surface2 for cue cards
- Theme.bg for background
- Radial gradient for muscle visual card

## Build Status

✅ Build succeeded

## Instructions to Test

**You need to add ExercisesView.swift to the Xcode project first:**

1. Open Xcode
2. Right-click on the `Views` folder in the project navigator
3. Select "Add Files to NextRepiOS..."
4. Navigate to `NextRepiOS/Views/ExercisesView.swift`
5. Make sure "Copy items if needed" is unchecked
6. Make sure "Add to target: NextRepiOS" is checked
7. Click "Add"

8. Uncomment the tab bar code in `MainTabView.swift`:
   - Replace `SearchView()` with `ExercisesView()`
   - Change icon to `dumbbell`
   - Change label to `"Exercises"`

9. Build and run in the iOS Simulator
10. Navigate to the Exercises tab
11. Tap an exercise card to view details
12. Test the Notes section (should sync with exerciseNotes)
13. Test the Edit button (opens form sheet)
14. Test the Delete button (two-tap confirm)
15. Test the muscle visual card
16. Test the instructions and cues sections

## Notes

- Photos section is a placeholder - would need photo storage implementation
- Delete only works for custom exercises (built-ins cannot be deleted)
- Notes are shared across all instances of this exercise (as per §5)