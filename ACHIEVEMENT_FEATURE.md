# Achievement Feature Implementation

## Overview
The Achievement feature gamifies the glucose tracking experience by rewarding users for consistent logging, healthy targets, and feature usage. It includes 11 different achievements across 4 categories.

## Features

### Achievement Categories
1. **Milestone** 🏆 - Total logs achievements
2. **Streak** 🔥 - Consecutive logging achievements  
3. **Health** ❤️ - Target range achievements
4. **Feature** ⭐ - App feature usage achievements

### Available Achievements

#### Milestone Achievements
- **Getting Started**: Log your first glucose reading (1 log)
- **First Steps**: Log 10 glucose readings
- **On Track**: Log 50 glucose readings

#### Streak Achievements  
- **Beginner Tracker**: Log glucose 3 days in a row
- **Committed Tracker**: Log glucose 7 days in a row
- **Glucose Master**: Log glucose 30 days in a row

#### Health Achievements
- **In Control**: Stay within target range for 3 consecutive readings
- **Balanced Week**: Stay within target range for 10 readings in a week

#### Feature Achievements
- **Thoughtful Logger**: Add your first note to a glucose reading
- **Smart Tracker**: Tag your first glucose reading
- **Data Sharer**: Export your glucose data for the first time

## Implementation Details

### Model Classes

#### `Achievement` Model
```dart
class Achievement {
  final String id;
  final String name;
  final String description;
  final String category;
  final AchievementCondition condition;
  final bool isUnlocked;
  final DateTime? unlockedAt;
}
```

#### `AchievementStats` Model
Tracks user progress across different metrics:
- `totalLogs`: Total number of glucose readings
- `logStreakDays`: Current consecutive logging streak
- `withinTargetConsecutive`: Maximum consecutive readings within target range
- `withinTargetWeek`: Readings within target in the last week
- `notesAdded`: Number of readings with notes
- `tagsUsed`: Number of readings with tags
- `exportsDone`: Number of PDF exports

### Service Layer

#### `AchievementService`
Main service for achievement management:
- `getAchievements(patientId)`: Get all achievements for patient
- `updateStatsAndCheckAchievements(patientId, patient)`: Update stats and check for new unlocks
- `incrementExportCount(patientId)`: Track PDF exports
- `getAchievementProgress(achievement, stats)`: Calculate progress percentage

### UI Components

#### `AchievementsPage`
Full-screen achievement browser with:
- Progress header showing unlocked count
- Category filtering (All, Milestones, Streaks, Health, Features)
- Achievement cards with progress bars
- Visual indicators for unlocked achievements

#### `AchievementUnlockedDialog`
Celebratory dialog shown when achievements are unlocked:
- Animated presentation
- Category-specific colors and icons
- Achievement details

#### `AchievementNotificationWidget`
Slide-in notification for new achievements:
- Auto-dismissing notification
- Support for multiple achievements
- Smooth animations

### Integration Points

#### Patient Record Updates
When glucose records are added, the system:
1. Updates achievement statistics
2. Checks for newly unlocked achievements
3. Shows notifications for new achievements

#### PDF Export Tracking
PDF exports automatically increment the export counter for the "Data Sharer" achievement.

#### Navigation Integration
Achievement page is accessible via the bottom navigation bar in the main app.

## Usage

### For Users
1. **View Achievements**: Navigate to the Achievements tab in the main navigation
2. **Filter by Category**: Use category chips to filter achievements
3. **Track Progress**: Each achievement shows current progress vs. target
4. **Celebration**: Get notified immediately when unlocking new achievements

### For Developers

#### Adding New Achievements
1. Add achievement definition to `AchievementService._defaultAchievementsJson`
2. If new stats are needed, update `AchievementStats` model
3. Update stats calculation in `AchievementService._calculateStats()`

#### Integrating Achievement Checks
When adding new features that should trigger achievements:
```dart
// Example: After adding a new glucose record
final newAchievements = await patientService.checkForNewAchievements(patientId);
if (newAchievements.isNotEmpty) {
  // Show notification or dialog
  AchievementUnlockedDialog.show(context, newAchievements.first);
}
```

## Database Structure

### Firebase Realtime Database
```
patients/
  {patientId}/
    achievements/
      {achievementId}:
        id: string
        name: string
        description: string
        category: string
        condition: object
        isUnlocked: boolean
        unlockedAt: timestamp
    achievement_stats/
      totalLogs: number
      logStreakDays: number
      withinTargetConsecutive: number
      withinTargetWeek: number
      notesAdded: number
      tagsUsed: number
      exportsDone: number
      lastLogDate: timestamp
      logDates: array
```

## Target Range Definition
The system uses a default target range of 70-180 mg/dL for health-related achievements. This can be customized in the `AchievementService` if needed.

## Future Enhancements
- Custom achievement creation
- Social sharing of achievements
- Achievement badges in profile
- Monthly/yearly achievement challenges
- Progress charts and analytics
- Push notifications for achievement reminders

## Files Created/Modified

### New Files
- `lib/models/achievement.model.dart`
- `lib/models/achievement_stats.model.dart`
- `lib/services/achievement.service.dart`
- `lib/pages/achievements_page.dart`
- `lib/widgets/achievement_widgets.dart`

### Modified Files
- `lib/services/patient.services.dart` - Added achievement tracking
- `lib/pages/patient_record_page.dart` - Added export tracking
- `lib/pages/main_nav_page.dart` - Added achievements tab
