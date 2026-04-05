class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final bool isUnlocked;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.isUnlocked,
  });

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? emoji,
    bool? isUnlocked,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }
}