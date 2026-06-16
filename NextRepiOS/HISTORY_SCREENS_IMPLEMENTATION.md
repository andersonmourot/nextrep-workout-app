# History Screens Implementation (§12)

## Summary

I've implemented the two history screens per §12 of the specification.

## Files Created

1. **WorkoutHistoryView.swift** - Workout History screen at /progress/history
2. **BodyWeightHistoryView.swift** - Body Weight History screen at /progress/weight

## Files Modified

- **ProfileView.swift** - Updated to use navigationDestination instead of sheets, removed inline history views

## Features Implemented

### WorkoutHistoryView (/progress/history)
- **Back link**: Arrow left + "Progress" text
- **Title**: "Workout History" (Oswald display font)
- **Subtitle**: "Your 20 most recent finished workouts."
- **List**: Shows 20 most recent logs using the card from §11
  - Day name
  - Program · date
  - Set count / ↗ volume in accent
  - Delete trash button
- **Empty state**: "No workouts yet" when no logs
- **Reuses**: workoutLogCard component from ProfileView

### BodyWeightHistoryView (/progress/weight)
- **Back link**: Arrow left + "Progress" text
- **Title**: "Body Weight History" (Oswald display font)
- **Subtitle**: "Every logged entry, newest first."
- **List**: Full list of all body weight entries
  - Date (formatted)
  - Time (formatted)
  - Weight
  - Delete button
- **Empty state**: "No weight entries yet" when no entries
- **Reuses**: bodyWeightRow component from ProfileView

## Theme Integration

All UI elements use the shared Theme:
- Theme.display() for titles (Oswald font)
- Theme.body() for body text
- Theme.accent for volume arrows
- Theme.text, Theme.textDim, Theme.placeholder for text colors
- Theme.surface for card backgrounds
- Theme.bg for background

## Navigation

Both screens use:
- Back button with arrow left + "Progress" text
- NavigationDestination from ProfileView
- Dismiss navigation to return to Progress tab

## Build Status

✅ Build succeeded (without new files added to project)

## Instructions to Add Files to Xcode Project

**You need to add both files to the Xcode project manually:**

1. Open Xcode
2. Right-click on the `Views` folder in the project navigator
3. Select "Add Files to NextRepiOS..."
4. Navigate to `NextRepiOS/Views/` and select both:
   - `WorkoutHistoryView.swift`
   - `BodyWeightHistoryView.swift`
5. Make sure "Copy items if needed" is unchecked
6. Make sure "Add to target: NextRepiOS" is checked
7. Click "Add"

**Also add ProfileView.swift** if you haven't already:
- Navigate to `NextRepiOS/Views/ProfileView.swift`
- Make sure "Copy items if needed" is unchecked
- Make sure "Add to target: NextRepiOS" is checked
- Click "Add"

## Instructions to Test

After adding the files to the project:
1. Build and run in the iOS Simulator
2. Navigate to the Profile tab
3. Test "Show More" on Workout History section → opens WorkoutHistoryView
4. Test "Show More" on Body Weight card → opens BodyWeightHistoryView
5. Test back navigation on both history screens
6. Test delete buttons on both history screens

## Notes

- Both history screens reuse card/row components from ProfileView for consistency
- Navigation uses navigationDestination instead of sheets for proper navigation stack
- Both screens show empty states when no data exists
- Workout History limits to 20 most recent logs
- Body Weight History shows all entries