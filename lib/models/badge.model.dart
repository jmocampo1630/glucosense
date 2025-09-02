import 'package:flutter/material.dart';

class Badge {
  final String id;
  final String name;
  final String description;
  final String category;
  final String iconPath; // Path to badge icon/image
  final String rarity; // common, rare, epic, legendary
  final Color backgroundColor;
  final Color borderColor;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final String achievementId; // Link to the achievement that unlocks this badge

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.iconPath,
    this.rarity = 'common',
    required this.backgroundColor,
    required this.borderColor,
    this.isUnlocked = false,
    this.unlockedAt,
    required this.achievementId,
  });

  factory Badge.fromJson(Map<dynamic, dynamic> json) {
    return Badge(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      iconPath: json['iconPath'],
      rarity: json['rarity'] ?? 'common',
      backgroundColor: Color(json['backgroundColor']),
      borderColor: Color(json['borderColor']),
      isUnlocked: json['isUnlocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'])
          : null,
      achievementId: json['achievementId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'iconPath': iconPath,
      'rarity': rarity,
      'backgroundColor': backgroundColor.value,
      'borderColor': borderColor.value,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'achievementId': achievementId,
    };
  }

  Badge copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? iconPath,
    String? rarity,
    Color? backgroundColor,
    Color? borderColor,
    bool? isUnlocked,
    DateTime? unlockedAt,
    String? achievementId,
  }) {
    return Badge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      iconPath: iconPath ?? this.iconPath,
      rarity: rarity ?? this.rarity,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      achievementId: achievementId ?? this.achievementId,
    );
  }

  // Get rarity color
  Color getRarityColor() {
    switch (rarity) {
      case 'common':
        return const Color(0xFF9E9E9E); // Grey
      case 'rare':
        return const Color(0xFF2196F3); // Blue
      case 'epic':
        return const Color(0xFF9C27B0); // Purple
      case 'legendary':
        return const Color(0xFFFF9800); // Orange
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  // Get rarity label
  String getRarityLabel() {
    switch (rarity) {
      case 'common':
        return 'Common';
      case 'rare':
        return 'Rare';
      case 'epic':
        return 'Epic';
      case 'legendary':
        return 'Legendary';
      default:
        return 'Common';
    }
  }

  // Get category emoji for badge
  String getCategoryEmoji() {
    switch (category) {
      case 'milestone':
        return '🎯';
      case 'streak':
        return '⚡';
      case 'health':
        return '💚';
      case 'feature':
        return '🌟';
      default:
        return '🏅';
    }
  }
}
