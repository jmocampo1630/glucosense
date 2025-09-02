class Achievement {
  final String id;
  final String name;
  final String description;
  final String category;
  final AchievementCondition condition;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.condition,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  factory Achievement.fromJson(Map<dynamic, dynamic> json) {
    return Achievement(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      condition: AchievementCondition.fromJson(json['condition']),
      isUnlocked: json['isUnlocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'condition': condition.toJson(),
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  Achievement copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    AchievementCondition? condition,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  // Get category color
  String getCategoryColor() {
    switch (category) {
      case 'milestone':
        return '#4CAF50'; // Green
      case 'streak':
        return '#FF9800'; // Orange
      case 'health':
        return '#2196F3'; // Blue
      case 'feature':
        return '#9C27B0'; // Purple
      default:
        return '#757575'; // Grey
    }
  }

  // Get category icon
  String getCategoryIcon() {
    switch (category) {
      case 'milestone':
        return '🏆';
      case 'streak':
        return '🔥';
      case 'health':
        return '❤️';
      case 'feature':
        return '⭐';
      default:
        return '🎯';
    }
  }
}

class AchievementCondition {
  final String field;
  final String operator;
  final dynamic value;

  AchievementCondition({
    required this.field,
    required this.operator,
    required this.value,
  });

  factory AchievementCondition.fromJson(Map<dynamic, dynamic> json) {
    return AchievementCondition(
      field: json['field'],
      operator: json['operator'],
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'operator': operator,
      'value': value,
    };
  }

  // Check if condition is met
  bool isMet(dynamic currentValue) {
    switch (operator) {
      case '>=':
        return currentValue >= value;
      case '>':
        return currentValue > value;
      case '<=':
        return currentValue <= value;
      case '<':
        return currentValue < value;
      case '==':
        return currentValue == value;
      default:
        return false;
    }
  }
}
