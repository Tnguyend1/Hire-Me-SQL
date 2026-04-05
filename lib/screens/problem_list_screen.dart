import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../models/problem.dart';
import '../state/app_state.dart';
import '../widgets/section_card.dart';
import 'question_screen.dart';

class ProblemListScreen extends StatelessWidget {
  final String title;
  final List<Problem> problems;

  const ProblemListScreen({
    super.key,
    required this.title,
    required this.problems,
  });

  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return AppColors.green;
      case 'Hard':
        return AppColors.red;
      default:
        return AppColors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: problems.isEmpty
          ? Center(
        child: Text(
          'No questions yet for $title',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: problems.length,
        itemBuilder: (context, index) {
          final problem = problems[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _ProblemCard(
              problem: problem,
              difficultyColor: _difficultyColor(problem.difficulty),
            ),
          );
        },
      ),
    );
  }
}

class _ProblemCard extends StatelessWidget {
  final Problem problem;
  final Color difficultyColor;

  const _ProblemCard({
    required this.problem,
    required this.difficultyColor,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isCompleted = appState.isProblemSolved(problem.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuestionScreen(problem: problem),
          ),
        );
      },
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    problem.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isCompleted) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.green.withOpacity(0.35),
                      ),
                    ),
                    child: const Text(
                      'Completed',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(
              problem.statement,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Pill(
                  text: problem.company,
                  bg: AppColors.cardSoft,
                  textColor: AppColors.textPrimary,
                ),
                _Pill(
                  text: problem.topic,
                  bg: const Color(0xFF24304A),
                  textColor: Colors.white,
                ),
                _Pill(
                  text: problem.difficulty,
                  bg: difficultyColor,
                  textColor: Colors.white,
                ),
                _Pill(
                  text: isCompleted ? 'Practice Again' : '+${problem.xp} XP',
                  bg: isCompleted ? AppColors.cardSoft : AppColors.purple,
                  textColor: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color textColor;

  const _Pill({
    required this.text,
    required this.bg,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}