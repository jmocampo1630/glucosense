import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:glucolook/models/badge.model.dart';

class BadgeService {
  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();

  // Default badges data matching achievements
  static const String _defaultBadgesJson = '''
  [
    {
      "id": "first_log_badge",
      "name": "First Step Badge",
      "description": "Awarded for logging your first glucose reading",
      "category": "milestone",
      "iconPath": "🥉",
      "rarity": "common",
      "backgroundColor": 4284513675,
      "borderColor": 4282462219,
      "achievementId": "first_log"
    },
    {
      "id": "log_10_badge",
      "name": "Dedicated Tracker Badge",
      "description": "Awarded for logging 10 glucose readings",
      "category": "milestone",
      "iconPath": "🥈",
      "rarity": "common",
      "backgroundColor": 4284513675,
      "borderColor": 4282462219,
      "achievementId": "log_10"
    },
    {
      "id": "log_50_badge",
      "name": "Committed Logger Badge",
      "description": "Awarded for logging 50 glucose readings",
      "category": "milestone",
      "iconPath": "🥇",
      "rarity": "rare",
      "backgroundColor": 4286578688,
      "borderColor": 4284831295,
      "achievementId": "log_50"
    },
    {
      "id": "streak_3_badge",
      "name": "Consistency Badge",
      "description": "Awarded for a 3-day logging streak",
      "category": "streak",
      "iconPath": "🔥",
      "rarity": "common",
      "backgroundColor": 4294940928,
      "borderColor": 4294924066,
      "achievementId": "streak_3"
    },
    {
      "id": "streak_7_badge",
      "name": "Weekly Warrior Badge",
      "description": "Awarded for a 7-day logging streak",
      "category": "streak",
      "iconPath": "🚀",
      "rarity": "rare",
      "backgroundColor": 4294940928,
      "borderColor": 4294924066,
      "achievementId": "streak_7"
    },
    {
      "id": "streak_30_badge",
      "name": "Streak Master Badge",
      "description": "Awarded for a 30-day logging streak",
      "category": "streak",
      "iconPath": "👑",
      "rarity": "legendary",
      "backgroundColor": 4294940928,
      "borderColor": 4294924066,
      "achievementId": "streak_30"
    },
    {
      "id": "target_3_badge",
      "name": "Control Badge",
      "description": "Awarded for staying in target range 3 times consecutively",
      "category": "health",
      "iconPath": "💚",
      "rarity": "common",
      "backgroundColor": 4286578688,
      "borderColor": 4284831295,
      "achievementId": "target_3"
    },
    {
      "id": "target_week_badge",
      "name": "Health Champion Badge",
      "description": "Awarded for staying in target range 10 times in a week",
      "category": "health",
      "iconPath": "❤️",
      "rarity": "epic",
      "backgroundColor": 4286578688,
      "borderColor": 4284831295,
      "achievementId": "target_week"
    },
    {
      "id": "first_note_badge",
      "name": "Thoughtful Badge",
      "description": "Awarded for adding your first note",
      "category": "feature",
      "iconPath": "📝",
      "rarity": "common",
      "backgroundColor": 4293467747,
      "borderColor": 4291611852,
      "achievementId": "first_note"
    },
    {
      "id": "first_tag_badge",
      "name": "Organizer Badge",
      "description": "Awarded for using your first tag",
      "category": "feature",
      "iconPath": "🏷️",
      "rarity": "common",
      "backgroundColor": 4293467747,
      "borderColor": 4291611852,
      "achievementId": "first_tag"
    },
    {
      "id": "first_export_badge",
      "name": "Data Master Badge",
      "description": "Awarded for your first data export",
      "category": "feature",
      "iconPath": "📊",
      "rarity": "rare",
      "backgroundColor": 4293467747,
      "borderColor": 4291611852,
      "achievementId": "first_export"
    }
  ]
  ''';

  // Get all badges for a patient
  Future<List<Badge>> getBadges(String patientId) async {
    try {
      final snapshot =
          await databaseReference.child('patients/$patientId/badges').get();

      List<Badge> badges = [];

      if (snapshot.exists) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          badges.add(Badge.fromJson(value));
        });
      } else {
        // Initialize with default badges if none exist
        badges = await _initializeDefaultBadges(patientId);
      }

      return badges;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting badges: $e');
      }
      return [];
    }
  }

  // Initialize default badges for a new patient
  Future<List<Badge>> _initializeDefaultBadges(String patientId) async {
    try {
      List<dynamic> defaultData = jsonDecode(_defaultBadgesJson);
      List<Badge> badges = [];

      for (var badgeData in defaultData) {
        Badge badge = Badge.fromJson(badgeData);
        badges.add(badge);

        // Save to Firebase
        await databaseReference
            .child('patients/$patientId/badges/${badge.id}')
            .set(badge.toJson());
      }

      return badges;
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing default badges: $e');
      }
      return [];
    }
  }

  // Unlock badge when achievement is unlocked
  Future<Badge?> unlockBadgeForAchievement(
      String patientId, String achievementId) async {
    try {
      List<Badge> badges = await getBadges(patientId);

      // Find the badge associated with this achievement
      Badge? badgeToUnlock;
      try {
        badgeToUnlock = badges.firstWhere(
          (badge) => badge.achievementId == achievementId && !badge.isUnlocked,
        );
      } catch (e) {
        return null; // Badge not found or already unlocked
      }

      // Unlock the badge
      Badge unlockedBadge = badgeToUnlock.copyWith(
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );

      // Save to Firebase
      await databaseReference
          .child('patients/$patientId/badges/${unlockedBadge.id}')
          .set(unlockedBadge.toJson());

      return unlockedBadge;
    } catch (e) {
      if (kDebugMode) {
        print('Error unlocking badge: $e');
      }
      return null;
    }
  }

  // Get unlocked badges count
  Future<int> getUnlockedBadgesCount(String patientId) async {
    try {
      List<Badge> badges = await getBadges(patientId);
      return badges.where((badge) => badge.isUnlocked).length;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting unlocked badges count: $e');
      }
      return 0;
    }
  }

  // Get badges by category
  Future<List<Badge>> getBadgesByCategory(
      String patientId, String category) async {
    try {
      List<Badge> badges = await getBadges(patientId);
      if (category == 'all') {
        return badges;
      }
      return badges.where((badge) => badge.category == category).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting badges by category: $e');
      }
      return [];
    }
  }

  // Get badges by rarity
  Future<List<Badge>> getBadgesByRarity(String patientId, String rarity) async {
    try {
      List<Badge> badges = await getBadges(patientId);
      if (rarity == 'all') {
        return badges;
      }
      return badges.where((badge) => badge.rarity == rarity).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting badges by rarity: $e');
      }
      return [];
    }
  }

  // Get recently unlocked badges (last 7 days)
  Future<List<Badge>> getRecentlyUnlockedBadges(String patientId) async {
    try {
      List<Badge> badges = await getBadges(patientId);
      DateTime weekAgo = DateTime.now().subtract(const Duration(days: 7));

      return badges
          .where((badge) =>
              badge.isUnlocked &&
              badge.unlockedAt != null &&
              badge.unlockedAt!.isAfter(weekAgo))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting recently unlocked badges: $e');
      }
      return [];
    }
  }
}
