import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../models/problem.dart';
import '../models/sql_execution_result.dart';
import '../state/app_state.dart';
import 'home_screen.dart';
import 'question_screen.dart';

class ResultScreen extends StatefulWidget {
  final Problem problem;
  final String userAnswer;
  final bool isCorrect;
  final SqlExecutionResult? executionResult;
  final String? validationReason;

  const ResultScreen({
    super.key,
    required this.problem,
    required this.userAnswer,
    required this.isCorrect,
    this.executionResult,
    this.validationReason,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  bool _didUpdateStats = false;
  late final AnimationController _controller;
  late final Animation<double> _popAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _popAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    if (widget.isCorrect) {
      _controller.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_didUpdateStats) {
      context.read<AppState>().submitAttempt(
        isCorrect: widget.isCorrect,
        xpEarned: widget.isCorrect ? widget.problem.xp : 0,
        problem: widget.problem,
        userAnswer: widget.userAnswer,
      );
      _didUpdateStats = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
    );
  }

  void _goNextQuestion() {
    final appState = context.read<AppState>();

    final availableProblems =
    appState.problems.where((p) => p.id != widget.problem.id).toList();

    if (availableProblems.isEmpty) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
      );
      return;
    }

    availableProblems.shuffle();
    final nextProblem = availableProblems.first;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionScreen(problem: nextProblem),
      ),
    );
  }

  void _retrySameQuestion() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionScreen(problem: widget.problem),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final problem = widget.problem;
    final stats = context.watch<AppState>().userStats;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 22),
              _buildHeroCard(problem, stats),
              const SizedBox(height: 18),
              _buildReasonCard(),
              const SizedBox(height: 18),
              _buildYourQueryCard(),
              const SizedBox(height: 18),
              if (widget.executionResult?.success == true) ...[
                _buildActualOutputCard(),
                const SizedBox(height: 18),
              ] else if ((widget.executionResult?.errorMessage ?? '').isNotEmpty) ...[
                _buildSqlErrorCard(),
                const SizedBox(height: 18),
              ],
              _buildExpectedOutputCard(),
              const SizedBox(height: 18),
              _buildExplanationCard(problem),
              if (!widget.isCorrect) ...[
                const SizedBox(height: 18),
                _buildCorrectAnswerCard(problem),
              ],
              const SizedBox(height: 18),
              _buildConceptsCard(problem),
              const SizedBox(height: 22),
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(999),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white70,
              size: 18,
            ),
            SizedBox(width: 6),
            Text(
              'Back',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(Problem problem, dynamic stats) {
    final borderColor = widget.isCorrect
        ? AppColors.green.withValues(alpha: 0.45)
        : AppColors.red.withValues(alpha: 0.45);

    final bgColor =
    widget.isCorrect ? const Color(0xFF041614) : const Color(0xFF190B11);

    final iconColor = widget.isCorrect ? AppColors.green : AppColors.red;

    final title = widget.isCorrect ? 'Correct!' : 'Not quite';
    final subtitle = widget.isCorrect
        ? 'Great job! Your query output matches the expected result.'
        : 'Review your output, compare it to the expected result, and try again.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: borderColor, width: 1.4),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (widget.isCorrect)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.green.withValues(alpha: 0.14),
                    ),
                  ),
                ),
              ScaleTransition(
                scale: widget.isCorrect
                    ? _popAnimation
                    : const AlwaysStoppedAnimation(1),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor.withValues(alpha: 0.18),
                    border: Border.all(color: iconColor, width: 2.4),
                  ),
                  child: Icon(
                    widget.isCorrect
                        ? Icons.check_rounded
                        : Icons.close_rounded,
                    color: iconColor,
                    size: 42,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SlideTransition(
            position: widget.isCorrect
                ? _slideAnimation
                : const AlwaysStoppedAnimation(Offset.zero),
            child: FadeTransition(
              opacity: widget.isCorrect
                  ? _fadeAnimation
                  : const AlwaysStoppedAnimation(1),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (widget.isCorrect)
                      const TextSpan(
                        text: ' 🎉',
                        style: TextStyle(fontSize: 28),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _buildStatBlock(
                  icon: Icons.emoji_events_outlined,
                  iconColor: AppColors.purpleBright,
                  value: widget.isCorrect ? '+${problem.xp}' : '+0',
                  label: 'XP Earned',
                ),
              ),
              Container(
                width: 1,
                height: 68,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              Expanded(
                child: _buildStatBlock(
                  icon: Icons.trending_up_rounded,
                  iconColor: widget.isCorrect ? AppColors.green : AppColors.red,
                  value: '${stats.accuracy.toStringAsFixed(0)}%',
                  label: 'Accuracy',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBlock({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildReasonCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Result',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.validationReason ??
                (widget.isCorrect ? 'Correct result.' : 'Incorrect result.'),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYourQueryCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Query',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1B26),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Text(
              widget.userAnswer,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.6,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSqlErrorCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SQL Error',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1B26),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.red.withValues(alpha: 0.28),
              ),
            ),
            child: Text(
              widget.executionResult?.errorMessage ?? 'Unknown SQL error.',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.6,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActualOutputCard() {
    final rows = widget.executionResult?.rows ?? const <Map<String, dynamic>>[];
    final columns =
        widget.executionResult?.columns ?? const <String>[];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Output',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          if (rows.isEmpty)
            const Text(
              'Query ran successfully but returned no rows.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            )
          else
            _buildDataTable(columns: columns, rows: rows),
        ],
      ),
    );
  }

  Widget _buildExpectedOutputCard() {
    final rows = widget.problem.expectedOutput ?? const <Map<String, dynamic>>[];
    final columns =
    rows.isNotEmpty ? rows.first.keys.map((e) => e.toString()).toList() : <String>[];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expected Output',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          if (rows.isEmpty)
            const Text(
              'No expected output provided.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            )
          else
            _buildDataTable(columns: columns, rows: rows),
        ],
      ),
    );
  }

  Widget _buildExplanationCard(Problem problem) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explanation',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            problem.explanation,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectAnswerCard(Problem problem) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'One Accepted Answer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1B26),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Text(
              problem.acceptedAnswers.isNotEmpty
                  ? problem.acceptedAnswers.first
                  : 'No accepted answer provided.',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.6,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConceptsCard(Problem problem) {
    return _card(
      color: const Color(0xFF20212B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Concepts Used',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: problem.concepts.map((concept) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E3040),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  concept.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final buttonText = widget.isCorrect ? 'Try Again' : 'Try Again';
    final buttonIcon = widget.isCorrect
        ? Icons.arrow_forward_rounded
        : Icons.replay_rounded;
    final buttonAction = widget.isCorrect ? _retrySameQuestion
        : _retrySameQuestion;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _goHome,
              icon: const Icon(Icons.home_outlined, size: 20),
              label: const Text('Home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF141520),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: SizedBox(
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [AppColors.purpleBright, AppColors.purple],
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: buttonAction,
                icon: Icon(buttonIcon, size: 20),
                label: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable({
    required List<String> columns,
    required List<Map<String, dynamic>> rows,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          const Color(0xFF232432),
        ),
        dataRowMinHeight: 42,
        dataRowMaxHeight: 56,
        columns: columns
            .map(
              (column) => DataColumn(
            label: Text(
              column,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        )
            .toList(),
        rows: rows
            .map(
              (row) => DataRow(
            cells: columns
                .map(
                  (column) => DataCell(
                Text(
                  '${row[column] ?? ''}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),
            )
                .toList(),
          ),
        )
            .toList(),
      ),
    );
  }

  Widget _card({
    required Widget child,
    Color? color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }
}