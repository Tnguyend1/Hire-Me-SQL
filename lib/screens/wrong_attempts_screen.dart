import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../models/wrong_attempt.dart';
import '../state/app_state.dart';
import '../widgets/section_card.dart';
import 'question_screen.dart';

class WrongAttemptsScreen extends StatefulWidget {
  const WrongAttemptsScreen({super.key});

  @override
  State<WrongAttemptsScreen> createState() => _WrongAttemptsScreenState();
}

class _WrongAttemptsScreenState extends State<WrongAttemptsScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final attempts = context.watch<AppState>().wrongAttempts;

    final retried = attempts.where((a) => a.isRetried).toList();
    final toReview = attempts.where((a) => !a.isRetried).toList();

    final visible = switch (_selectedTab) {
      1 => toReview,
      2 => retried,
      _ => attempts,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: attempts.isEmpty
            ? SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _back(context),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'No mistakes yet 🎉',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            ],
          ),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _back(context),
              const SizedBox(height: 18),
              _header(),
              const SizedBox(height: 22),

              // 🔥 REAL STATS
              _stats(
                total: attempts.length,
                toReview: toReview.length,
                retried: retried.length,
              ),

              const SizedBox(height: 22),

              _tabs(
                total: attempts.length,
                toReview: toReview.length,
                retried: retried.length,
              ),

              const SizedBox(height: 20),

              ...visible.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: _card(context, a),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _back(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      child: const Row(
        children: [
          Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white70, size: 18),
          SizedBox(width: 8),
          Text(
            'Back to Profile',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return const Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Color(0xFF3A171B),
          child: Icon(Icons.close_rounded,
              color: AppColors.red, size: 30),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wrong Attempts',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 6),
              Text(
                'Review and learn from your mistakes',
                style: TextStyle(color: Colors.white60),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _stats({
    required int total,
    required int toReview,
    required int retried,
  }) {
    return Row(
      children: [
        _stat('$total', 'Total Wrong', AppColors.red),
        const SizedBox(width: 10),
        _stat('$toReview', 'Not Retried', AppColors.orange),
        const SizedBox(width: 10),
        _stat('$retried', 'Retried', AppColors.green),
      ],
    );
  }

  Widget _stat(String number, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              number,
              style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _tabs({
    required int total,
    required int toReview,
    required int retried,
  }) {
    final items = [
      'All ($total)',
      'To Review ($toReview)',
      'Retried ($retried)'
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A37),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final selected = _selectedTab == i;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF3A3A49)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  items[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white60,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _card(BuildContext context, WrongAttempt attempt) {
    final p = attempt.problem;
    final appState = context.read<AppState>();

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + badge
          Row(
            children: [
              Expanded(
                child: Text(
                  p.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800),
                ),
              ),
              if (attempt.isRetried)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Retried',
                    style: TextStyle(
                        color: AppColors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // chips
          Row(
            children: [
              _chip(p.difficulty, AppColors.orange),
              const SizedBox(width: 8),
              _chip(p.topic.toUpperCase(), const Color(0xFF2A2C37)),
              const SizedBox(width: 8),
              _chip(p.company, const Color(0xFF2A2C37)),
            ],
          ),

          const SizedBox(height: 10),

          // date
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Text(
                _formatDate(attempt.date),
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // mistake box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF2A1515),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              attempt.userAnswer,
              style: const TextStyle(color: Colors.white70),
            ),
          ),

          const SizedBox(height: 14),


          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () async {
                await appState.markWrongAttemptRetried(attempt);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuestionScreen(problem: p),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: attempt.isRetried
                    ? const Color(0xFF232432)
                    : AppColors.purple,
              ),
              child: Text(
                attempt.isRetried ? 'Try Again' : 'Retry Now',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return '1 day ago';
    if (diff < 7) return '$diff days ago';

    return '${date.month}/${date.day}';
  }
}