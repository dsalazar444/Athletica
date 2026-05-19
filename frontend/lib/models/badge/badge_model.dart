class BadgeDefinition {
  final int id;
  final String badgeType;
  final String badgeTypeDisplay;
  final int level;
  final String name;
  final String description;
  final String svgFilename;
  final String unlockCondition;

  BadgeDefinition({
    required this.id,
    required this.badgeType,
    required this.badgeTypeDisplay,
    required this.level,
    required this.name,
    required this.description,
    required this.svgFilename,
    required this.unlockCondition,
  });

  factory BadgeDefinition.fromJson(Map<String, dynamic> json) {
    return BadgeDefinition(
      id: json['id'] as int,
      badgeType: (json['badge_type'] as String?) ?? '',
      badgeTypeDisplay: (json['badge_type_display'] as String?) ?? '',
      level: (json['level'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      svgFilename: (json['svg_filename'] as String?) ?? '',
      unlockCondition: (json['unlock_condition'] as String?) ?? '',
    );
  }
}

class UserBadgeEntry {
  final int id;
  final BadgeDefinition badge;
  final DateTime unlockedAt;

  UserBadgeEntry({
    required this.id,
    required this.badge,
    required this.unlockedAt,
  });

  factory UserBadgeEntry.fromJson(Map<String, dynamic> json) {
    return UserBadgeEntry(
      id: json['id'] as int,
      badge: BadgeDefinition.fromJson(json['badge'] as Map<String, dynamic>),
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
    );
  }
}

class BadgeStats {
  final int nutritionStreak;
  final int workoutStreak;
  final int completeStreak;

  BadgeStats({
    required this.nutritionStreak,
    required this.workoutStreak,
    required this.completeStreak,
  });

  factory BadgeStats.fromJson(Map<String, dynamic> json) {
    return BadgeStats(
      nutritionStreak: (json['nutrition_streak'] as num?)?.toInt() ?? 0,
      workoutStreak: (json['workout_streak'] as num?)?.toInt() ?? 0,
      completeStreak: (json['complete_streak'] as num?)?.toInt() ?? 0,
    );
  }
}

class BadgeSummaryResponse {
  final int totalBadges;
  final List<UserBadgeEntry> unlockedBadges;
  final List<BadgeDefinition> newlyAwarded;
  final BadgeStats stats;

  BadgeSummaryResponse({
    required this.totalBadges,
    required this.unlockedBadges,
    required this.newlyAwarded,
    required this.stats,
  });

  factory BadgeSummaryResponse.fromJson(Map<String, dynamic> json) {
    return BadgeSummaryResponse(
      totalBadges: (json['total_badges'] as num?)?.toInt() ?? 0,
      unlockedBadges: (json['unlocked_badges'] as List? ?? [])
          .map((item) => UserBadgeEntry.fromJson(item as Map<String, dynamic>))
          .toList(),
      newlyAwarded: (json['newly_awarded'] as List? ?? [])
          .map((item) => BadgeDefinition.fromJson(item as Map<String, dynamic>))
          .toList(),
      stats: BadgeStats.fromJson(
        (json['stats'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }
}
