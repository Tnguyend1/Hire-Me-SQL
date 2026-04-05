import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/problem.dart';

class QuestionRepository {
  static Future<List<Problem>> loadQuestions() async {
    final raw = await rootBundle.loadString('assets/questions.json');
    final List decoded = jsonDecode(raw);

    return decoded
        .map((e) => Problem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}