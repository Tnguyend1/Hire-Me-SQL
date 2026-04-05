class Problem {
  final String id;
  final String title;
  final String topic;
  final String company;
  final String difficulty;
  final int xp;
  final String statement;
  final String hint;
  final String explanation;
  final List<String> concepts;
  final List<String> acceptedAnswers;
  final List<String> requiredKeywords;

  /// Raw SQLite CREATE TABLE statements
  final List<String>? schema;

  /// table name -> list of rows
  final Map<String, List<Map<String, dynamic>>>? sampleData;

  /// expected query result rows
  final List<Map<String, dynamic>>? expectedOutput;

  const Problem({
    required this.id,
    required this.title,
    required this.topic,
    required this.company,
    required this.difficulty,
    required this.xp,
    required this.statement,
    required this.hint,
    required this.explanation,
    required this.concepts,
    required this.acceptedAnswers,
    this.requiredKeywords = const [],
    this.schema,
    this.sampleData,
    this.expectedOutput,
  });

  factory Problem.fromJson(Map<String, dynamic> json) {
    return Problem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      topic: json['topic']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? '',
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      statement: json['statement']?.toString() ?? '',
      hint: json['hint']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      concepts: List<String>.from(json['concepts'] ?? const []),
      acceptedAnswers: List<String>.from(json['acceptedAnswers'] ?? const []),
      requiredKeywords:
      List<String>.from(json['requiredKeywords'] ?? const []),
      schema: json['schema'] != null
          ? List<String>.from(json['schema'] as List)
          : null,
      sampleData: (json['sampleData'] as Map?)?.map(
            (key, value) => MapEntry(
          key.toString(),
          (value as List)
              .map((row) => Map<String, dynamic>.from(row as Map))
              .toList(),
        ),
      ),
      expectedOutput: json['expectedOutput'] != null
          ? (json['expectedOutput'] as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'topic': topic,
      'company': company,
      'difficulty': difficulty,
      'xp': xp,
      'statement': statement,
      'hint': hint,
      'explanation': explanation,
      'concepts': concepts,
      'acceptedAnswers': acceptedAnswers,
      'requiredKeywords': requiredKeywords,
      'schema': schema,
      'sampleData': sampleData,
      'expectedOutput': expectedOutput,
    };
  }

  Problem copyWith({
    String? id,
    String? title,
    String? topic,
    String? company,
    String? difficulty,
    int? xp,
    String? statement,
    String? hint,
    String? explanation,
    List<String>? concepts,
    List<String>? acceptedAnswers,
    List<String>? requiredKeywords,
    List<String>? schema,
    Map<String, List<Map<String, dynamic>>>? sampleData,
    List<Map<String, dynamic>>? expectedOutput,
  }) {
    return Problem(
      id: id ?? this.id,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      company: company ?? this.company,
      difficulty: difficulty ?? this.difficulty,
      xp: xp ?? this.xp,
      statement: statement ?? this.statement,
      hint: hint ?? this.hint,
      explanation: explanation ?? this.explanation,
      concepts: concepts ?? this.concepts,
      acceptedAnswers: acceptedAnswers ?? this.acceptedAnswers,
      requiredKeywords: requiredKeywords ?? this.requiredKeywords,
      schema: schema ?? this.schema,
      sampleData: sampleData ?? this.sampleData,
      expectedOutput: expectedOutput ?? this.expectedOutput,
    );
  }
}