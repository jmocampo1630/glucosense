import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:glucolook/models/achievement.model.dart';
import 'package:glucolook/models/achievement_stats.model.dart';
import 'package:glucolook/models/glucose_record.model.dart';
import 'package:glucolook/models/patient.model.dart';

class AchievementService {
  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();

  // Default achievements data
  static const String _defaultAchievementsJson = '''
  [
    {
      "id": "first_log",
      "name": "Getting Started",
      "description": "Log your first glucose reading.",
      "category": "milestone",
      "condition": {
        "field": "total_logs",
        "operator": ">=",
        "value": 1
      }
    },
    {
      "id": "log_10",
      "name": "First Steps",
      "description": "Log 10 glucose readings.",
      "category": "milestone",
      "condition": {
        "field": "total_logs",
        "operator": ">=",
        "value": 10
      }
    },
    {
      "id": "log_50",
      "name": "On Track",
      "description": "Log 50 glucose readings.",
      "category": "milestone",
      "condition": {
        "field": "total_logs",
        "operator": ">=",
        "value": 50
      }
    },
    {
      "id": "streak_3",
      "name": "Beginner Tracker",
      "description": "Log glucose 3 days in a row.",
      "category": "streak",
      "condition": {
        "field": "log_streak_days",
        "operator": ">=",
        "value": 3
      }
    },
    {
      "id": "streak_7",
      "name": "Committed Tracker",
      "description": "Log glucose 7 days in a row.",
      "category": "streak",
      "condition": {
        "field": "log_streak_days",
        "operator": ">=",
        "value": 7
      }
    },
    {
      "id": "streak_30",
      "name": "Glucose Master",
      "description": "Log glucose 30 days in a row.",
      "category": "streak",
      "condition": {
        "field": "log_streak_days",
        "operator": ">=",
        "value": 30
      }
    },
    {
      "id": "target_3",
      "name": "In Control",
      "description": "Stay within target range for 3 consecutive readings.",
      "category": "health",
      "condition": {
        "field": "within_target_consecutive",
        "operator": ">=",
        "value": 3
      }
    },
    {
      "id": "target_week",
      "name": "Balanced Week",
      "description": "Stay within target range for 10 readings in a week.",
      "category": "health",
      "condition": {
        "field": "within_target_week",
        "operator": ">=",
        "value": 10
      }
    },
    {
      "id": "first_note",
      "name": "Thoughtful Logger",
      "description": "Add your first note to a glucose reading.",
      "category": "feature",
      "condition": {
        "field": "notes_added",
        "operator": ">=",
        "value": 1
      }
    },
    {
      "id": "first_tag",
      "name": "Smart Tracker",
      "description": "Tag your first glucose reading.",
      "category": "feature",
      "condition": {
        "field": "tags_used",
        "operator": ">=",
        "value": 1
      }
    },
    {
      "id": "first_export",
      "name": "Data Sharer",
      "description": "Export your glucose data for the first time.",
      "category": "feature",
      "condition": {
        "field": "exports_done",
        "operator": ">=",
        "value": 1
      }
    }
  ]
  ''';

  // Get all achievements for a patient
  Future<List<Achievement>> getAchievements(String patientId) async {
    try {
      final snapshot = await databaseReference
          .child('patients/$patientId/achievements')
          .get();

      List<Achievement> achievements = [];

      if (snapshot.exists) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          achievements.add(Achievement.fromJson(value));
        });
      } else {
        // Initialize with default achievements if none exist
        achievements = await _initializeDefaultAchievements(patientId);
      }

      return achievements;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting achievements: $e');
      }
      return [];
    }
  }

  // Initialize default achievements for a new patient
  Future<List<Achievement>> _initializeDefaultAchievements(
      String patientId) async {
    try {
      List<dynamic> defaultData = jsonDecode(_defaultAchievementsJson);
      List<Achievement> achievements = [];

      for (var achievementData in defaultData) {
        Achievement achievement = Achievement.fromJson(achievementData);
        achievements.add(achievement);

        // Save to Firebase
        await databaseReference
            .child('patients/$patientId/achievements/${achievement.id}')
            .set(achievement.toJson());
      }

      return achievements;
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing default achievements: $e');
      }
      return [];
    }
  }

  // Get achievement stats for a patient
  Future<AchievementStats> getAchievementStats(String patientId) async {
    try {
      final snapshot = await databaseReference
          .child('patients/$patientId/achievement_stats')
          .get();

      if (snapshot.exists) {
        return AchievementStats.fromJson(
            snapshot.value as Map<dynamic, dynamic>);
      } else {
        return AchievementStats();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting achievement stats: $e');
      }
      return AchievementStats();
    }
  }

  // Update achievement stats and check for new achievements
  Future<List<Achievement>> updateStatsAndCheckAchievements(
      String patientId, Patient patient) async {
    try {
      AchievementStats currentStats = await getAchievementStats(patientId);
      AchievementStats updatedStats = _calculateStats(patient, currentStats);

      // Save updated stats
      await databaseReference
          .child('patients/$patientId/achievement_stats')
          .set(updatedStats.toJson());

      // Check for newly unlocked achievements
      List<Achievement> newlyUnlocked =
          await _checkAndUnlockAchievements(patientId, updatedStats);

      return newlyUnlocked;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating stats and checking achievements: $e');
      }
      return [];
    }
  }

  // Calculate stats based on patient data
  AchievementStats _calculateStats(
      Patient patient, AchievementStats currentStats) {
    List<GlucoseRecord> records = patient.glucoseRecords;
    records.sort((a, b) => a.date.compareTo(b.date));

    // Calculate total logs
    int totalLogs = records.length;

    // Calculate log dates
    List<DateTime> logDates = records
        .map((r) => DateTime(r.date.year, r.date.month, r.date.day))
        .toSet()
        .toList();
    logDates.sort();

    // Calculate streak days
    int logStreakDays = _calculateLogStreak(logDates);

    // Calculate consecutive target hits (assuming target range 70-180 mg/dL)
    int withinTargetConsecutive = _calculateConsecutiveTargetHits(records);

    // Calculate target hits in last week
    int withinTargetWeek = _calculateTargetHitsInWeek(records);

    // Calculate notes added
    int notesAdded = records.where((r) => r.description.isNotEmpty).length;

    // Calculate tags used
    int tagsUsed = records.where((r) => r.tags.isNotEmpty).length;

    return currentStats.copyWith(
      totalLogs: totalLogs,
      logStreakDays: logStreakDays,
      withinTargetConsecutive: withinTargetConsecutive,
      withinTargetWeek: withinTargetWeek,
      notesAdded: notesAdded,
      tagsUsed: tagsUsed,
      logDates: logDates,
      lastLogDate: records.isNotEmpty ? records.last.date : DateTime.now(),
    );
  }

  // Calculate log streak
  int _calculateLogStreak(List<DateTime> logDates) {
    if (logDates.isEmpty) return 0;

    int streak = 1;
    DateTime today = DateTime.now();
    DateTime currentDate = DateTime(today.year, today.month, today.day);

    // Check if logged today or yesterday
    DateTime lastLogDate = logDates.last;
    int daysDifference = currentDate.difference(lastLogDate).inDays;

    if (daysDifference > 1) return 0; // Streak broken

    // Count consecutive days backwards
    for (int i = logDates.length - 2; i >= 0; i--) {
      DateTime prevDate = logDates[i];
      DateTime nextDate = logDates[i + 1];

      if (nextDate.difference(prevDate).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  // Calculate consecutive target hits
  int _calculateConsecutiveTargetHits(List<GlucoseRecord> records) {
    if (records.isEmpty) return 0;

    int consecutive = 0;
    int maxConsecutive = 0;
    const double targetMin = 70.0;
    const double targetMax = 180.0;

    for (var record in records.reversed) {
      if (record.value >= targetMin && record.value <= targetMax) {
        consecutive++;
        maxConsecutive =
            consecutive > maxConsecutive ? consecutive : maxConsecutive;
      } else {
        consecutive = 0;
      }
    }

    return maxConsecutive;
  }

  // Calculate target hits in last week
  int _calculateTargetHitsInWeek(List<GlucoseRecord> records) {
    DateTime weekAgo = DateTime.now().subtract(const Duration(days: 7));
    const double targetMin = 70.0;
    const double targetMax = 180.0;

    return records
        .where((record) =>
            record.date.isAfter(weekAgo) &&
            record.value >= targetMin &&
            record.value <= targetMax)
        .length;
  }

  // Check and unlock achievements
  Future<List<Achievement>> _checkAndUnlockAchievements(
      String patientId, AchievementStats stats) async {
    List<Achievement> achievements = await getAchievements(patientId);
    List<Achievement> newlyUnlocked = [];

    for (var achievement in achievements) {
      if (!achievement.isUnlocked) {
        dynamic currentValue =
            stats.getValueByField(achievement.condition.field);

        if (achievement.condition.isMet(currentValue)) {
          // Unlock achievement
          Achievement unlockedAchievement = achievement.copyWith(
            isUnlocked: true,
            unlockedAt: DateTime.now(),
          );

          await databaseReference
              .child('patients/$patientId/achievements/${achievement.id}')
              .set(unlockedAchievement.toJson());

          newlyUnlocked.add(unlockedAchievement);
        }
      }
    }

    return newlyUnlocked;
  }

  // Increment export count
  Future<void> incrementExportCount(String patientId) async {
    try {
      AchievementStats currentStats = await getAchievementStats(patientId);
      AchievementStats updatedStats = currentStats.copyWith(
        exportsDone: currentStats.exportsDone + 1,
      );

      await databaseReference
          .child('patients/$patientId/achievement_stats')
          .set(updatedStats.toJson());

      // Check for newly unlocked achievements
      await _checkAndUnlockAchievements(patientId, updatedStats);
    } catch (e) {
      if (kDebugMode) {
        print('Error incrementing export count: $e');
      }
    }
  }

  // Get achievement progress percentage
  double getAchievementProgress(
      Achievement achievement, AchievementStats stats) {
    dynamic currentValue = stats.getValueByField(achievement.condition.field);
    dynamic targetValue = achievement.condition.value;

    if (achievement.isUnlocked) return 1.0;
    if (targetValue == 0) return 0.0;

    double progress = currentValue / targetValue;
    return progress > 1.0 ? 1.0 : progress;
  }
}
