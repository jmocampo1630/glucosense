# Daily Reminder Feature

## Overview
The daily reminder feature allows users to set up automatic notifications to remind them to scan their glucose levels. This helps maintain consistent monitoring habits.

## Features

### 1. **Reminder Settings Widget**
- Located in the Settings page
- Toggle to enable/disable daily reminders
- Time picker to set when to receive reminders
- Test notification button to verify notifications are working

### 2. **Notification Service**
- Handles scheduling and managing local notifications
- Persists reminder preferences using SharedPreferences
- Supports Android and iOS platforms
- Uses timezone-aware scheduling for accurate delivery

### 3. **Default Behavior**
- **Default Time**: 9:00 AM
- **Frequency**: Daily recurring
- **Status**: Disabled by default (users must opt-in)

## How to Use

### Enabling Reminders
1. Navigate to Settings page
2. Find the "Daily Reminder" card at the top
3. Toggle the switch to enable reminders
4. Set your preferred reminder time using the time picker
5. Optionally test the notification using "Test Notification" button

### Customizing Reminder Time
1. Ensure reminders are enabled
2. Tap on the time display (e.g., "9:00 AM")
3. Select your preferred time in the time picker
4. The reminder will automatically reschedule for the new time

### Testing Notifications
1. With reminders enabled, tap "Test Notification"
2. You should receive an immediate test notification
3. If you don't receive it, check your device's notification permissions

## Technical Implementation

### Files Added/Modified
- `lib/services/notification.services.dart` - Core notification functionality
- `lib/widgets/reminder_settings_widget.dart` - UI component for settings
- `lib/pages/settings_page.dart` - Updated to include reminder settings
- `lib/main.dart` - Initialize notification service on app startup
- `pubspec.yaml` - Added notification dependencies
- `android/app/src/main/AndroidManifest.xml` - Android notification permissions

### Dependencies Added
- `flutter_local_notifications: ^17.2.2` - Local notification support
- `timezone: ^0.9.4` - Timezone handling for accurate scheduling

### Permissions Required
- **Android**: `POST_NOTIFICATIONS`, `VIBRATE`, `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK`
- **iOS**: Alert, Badge, Sound permissions (requested at runtime)

## Notification Content
- **Title**: "Time for Glucose Check"
- **Body**: "Don't forget to scan your glucose level today!"
- **Color**: Teal (#37B5B6) - matches app branding
- **Icon**: App launcher icon
- **Channel**: "Glucose Reminders" (Android)

## Troubleshooting

### Notifications Not Working
1. Check device notification permissions for the app
2. Ensure "Do Not Disturb" mode is not blocking notifications
3. Verify the reminder is enabled in app settings
4. Try the "Test Notification" feature
5. On Android, check if battery optimization is disabled for the app

### Time Not Accurate
1. Ensure device time zone is correct
2. Check if the app has been updated recently
3. Try disabling and re-enabling the reminder

### Reminder Stops Working
1. Device restarts may require re-enabling reminders
2. App updates might reset notification permissions
3. Check if the app was force-closed or restricted by the system

## Future Enhancements
- Multiple reminder times per day
- Custom reminder messages
- Smart reminders based on usage patterns
- Integration with meal times or specific events
- Reminder statistics and compliance tracking
