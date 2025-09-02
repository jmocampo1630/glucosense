class AchievementStats {
  final int totalLogs;
  final int logStreakDays;
  final int withinTargetConsecutive;
  final int withinTargetWeek;
  final int notesAdded;
  final int tagsUsed;
  final int exportsDone;
  final DateTime lastLogDate;
  final List<DateTime> logDates;

  AchievementStats({
    this.totalLogs = 0,
    this.logStreakDays = 0,
    this.withinTargetConsecutive = 0,
    this.withinTargetWeek = 0,
    this.notesAdded = 0,
    this.tagsUsed = 0,
    this.exportsDone = 0,
    DateTime? lastLogDate,
    this.logDates = const [],
  }) : lastLogDate = lastLogDate ?? DateTime.now();

  factory AchievementStats.fromJson(Map<dynamic, dynamic> json) {
    List<DateTime> parsedLogDates = [];
    if (json['logDates'] != null) {
      for (var dateString in json['logDates']) {
        parsedLogDates.add(DateTime.parse(dateString));
      }
    }

    return AchievementStats(
      totalLogs: json['totalLogs'] ?? 0,
      logStreakDays: json['logStreakDays'] ?? 0,
      withinTargetConsecutive: json['withinTargetConsecutive'] ?? 0,
      withinTargetWeek: json['withinTargetWeek'] ?? 0,
      notesAdded: json['notesAdded'] ?? 0,
      tagsUsed: json['tagsUsed'] ?? 0,
      exportsDone: json['exportsDone'] ?? 0,
      lastLogDate: json['lastLogDate'] != null
          ? DateTime.parse(json['lastLogDate'])
          : DateTime.now(),
      logDates: parsedLogDates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalLogs': totalLogs,
      'logStreakDays': logStreakDays,
      'withinTargetConsecutive': withinTargetConsecutive,
      'withinTargetWeek': withinTargetWeek,
      'notesAdded': notesAdded,
      'tagsUsed': tagsUsed,
      'exportsDone': exportsDone,
      'lastLogDate': lastLogDate.toIso8601String(),
      'logDates': logDates.map((date) => date.toIso8601String()).toList(),
    };
  }

  AchievementStats copyWith({
    int? totalLogs,
    int? logStreakDays,
    int? withinTargetConsecutive,
    int? withinTargetWeek,
    int? notesAdded,
    int? tagsUsed,
    int? exportsDone,
    DateTime? lastLogDate,
    List<DateTime>? logDates,
  }) {
    return AchievementStats(
      totalLogs: totalLogs ?? this.totalLogs,
      logStreakDays: logStreakDays ?? this.logStreakDays,
      withinTargetConsecutive:
          withinTargetConsecutive ?? this.withinTargetConsecutive,
      withinTargetWeek: withinTargetWeek ?? this.withinTargetWeek,
      notesAdded: notesAdded ?? this.notesAdded,
      tagsUsed: tagsUsed ?? this.tagsUsed,
      exportsDone: exportsDone ?? this.exportsDone,
      lastLogDate: lastLogDate ?? this.lastLogDate,
      logDates: logDates ?? this.logDates,
    );
  }

  // Get value by field name
  dynamic getValueByField(String field) {
    switch (field) {
      case 'total_logs':
        return totalLogs;
      case 'log_streak_days':
        return logStreakDays;
      case 'within_target_consecutive':
        return withinTargetConsecutive;
      case 'within_target_week':
        return withinTargetWeek;
      case 'notes_added':
        return notesAdded;
      case 'tags_used':
        return tagsUsed;
      case 'exports_done':
        return exportsDone;
      default:
        return 0;
    }
  }
}
