class UserStats {
  final String name;
  final int totalXp;
  final int solvedCount;
  final int attemptCount;
  final int streakDays;
  final int badges;
  final int currentLevelXp;
  final int nextLevelXp;

  const UserStats({
    required this.name,
    required this.totalXp,
    required this.solvedCount,
    required this.attemptCount,
    required this.streakDays,
    required this.badges,
    required this.currentLevelXp,
    required this.nextLevelXp,
  });

  double get accuracy {
    if (attemptCount == 0) return 0;
    return (solvedCount / attemptCount) * 100;
  }

  UserStats copyWith({
    String? name,
    int? totalXp,
    int? solvedCount,
    int? attemptCount,
    int? streakDays,
    int? badges,
    int? currentLevelXp,
    int? nextLevelXp,
  }) {
    return UserStats(
      name: name ?? this.name,
      totalXp: totalXp ?? this.totalXp,
      solvedCount: solvedCount ?? this.solvedCount,
      attemptCount: attemptCount ?? this.attemptCount,
      streakDays: streakDays ?? this.streakDays,
      badges: badges ?? this.badges,
      currentLevelXp: currentLevelXp ?? this.currentLevelXp,
      nextLevelXp: nextLevelXp ?? this.nextLevelXp,
    );
  }
}