class TopicProgress {
  final String topic;
  final int solved;
  final int total;

  const TopicProgress({
    required this.topic,
    required this.solved,
    required this.total,
  });

  double get progress {
    if (total == 0) return 0;
    return solved / total;
  }
}