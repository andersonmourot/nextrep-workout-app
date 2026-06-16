# Progress/Profile Tab Implementation (§11)

## Summary

I've implemented the Progress/Profile tab per §11 of the specification.

## Files Created/Modified

### Files Created
- **ProfileView.swift** - Complete Progress/Profile tab implementation

### Files Modified
- **Models.swift** - Added `BodyWeightEntry` struct and added `bodyWeightEntries` to `AppData`
- **Utils.swift** - Added `totalVolume(logs:)` helper function
- **AppStore.swift** - Added `addBodyWeight(weight:)` and `deleteBodyWeight(id:)` methods

## Features Implemented

### 3-Stat Row
- **Workouts**: Logs count
- **Day streak**: Uses existing `computeStreak(logs:)` function
- **Volume**: `totalVolume/1000` as '{x.x}k Volume ({unit})'

### Tracker Nav Rows
- **Nutrition**: Button with leaf icon (placeholder for future implementation)
- **Max Tracker**: Button with chart icon (placeholder for future implementation)

### Body Weight Card
- **All-entries line+area trend sparkline**: Custom implementation using Path with line and area fill
- **Latest value big**: Displayed in large font
- **Delta since start**: Green down / accent up (calculated from first entry)
- **Dashed empty state**: Shows when under 2 entries
- **Decimal add-weight input + Log button**: Appends BodyWeightEntry via `addBodyWeight`
- **Last-5 recent list**: Shows date/time + weight + delete button
- **'Show More' link**: Opens BodyWeightHistoryView sheet when >5 entries

### Workout History Section
- **5 most recent logs as cards**:
  - Day name
  - Program · date
  - Duration / set count / ↗ volume in accent
  - Tap → program (placeholder)
  - Delete trash button
- **'Show More' link**: Opens WorkoutHistoryView sheet when >5 logs
- **Empty state**: "No workouts yet" message when no logs

### History Views
- **BodyWeightHistoryView**: Full list of all body weight entries with delete
- **WorkoutHistoryView**: Full list of all workout logs with delete

### Helper Functions
- **totalVolume(logs:)**: Computes total volume across all workout logs

## Theme Integration

All UI elements use the shared Theme:
- Theme.display() for stats and weight values
- Theme.body() for body text
- Theme.accent for volume arrows, sparkline line, tracker icons
- Theme.text, Theme.textDim, Theme.placeholder for text colors
- Theme.surface for card backgrounds
- Theme.bg for background
- Green color for weight loss (down delta)

## Build Status

✅ Build succeeded (without ProfileView.swift added to project)

## Instructions to Add to Xcode Project

**You need to add ProfileView.swift to the Xcode project manually:**

1. Open Xcode
2. Right-click on the `Views` folder in the project navigator
3. Select "Add Files to NextRepiOS..."
4. Navigate to `NextRepiOS/Views/ProfileView.swift`
5. Make sure "Copy items if needed" is unchecked
6. Make sure "Add to target: NextRepiOS" is checked
7. Click "Add"

## Instructions to Test

After adding the file to the project:
1. Build and run in the iOS Simulator
2. Navigate to the Profile tab
3. Test the 3-stat row (should show current stats)
4. Test the tracker nav rows (placeholder buttons)
5. Test the Body Weight card:
   - Log a weight entry
   - See the sparkline appear after 2+ entries
   - See the delta since start
   - Test the delete button on recent entries
   - Test "Show More" when >5 entries
6. Test the Workout History section:
   - See recent workout logs
   - Test the delete button on workout logs
   - Test "Show More" when >5 logs
   - See empty state when no logs

## Notes

- Body weight entries are persisted in AppData.bodyWeightEntries
- Workout logs are persisted in AppData.logs
- Both history views use NavigationView with List for clean presentation
- Sparkline is a custom implementation using SwiftUI Path