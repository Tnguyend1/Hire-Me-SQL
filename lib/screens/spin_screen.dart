import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../models/problem.dart';
import '../state/app_state.dart';
import '../widgets/section_card.dart';
import 'question_screen.dart';

class SpinScreen extends StatefulWidget {
  const SpinScreen({super.key});

  @override
  State<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends State<SpinScreen> {
  final Random _random = Random();

  bool _isSpinning = false;
  int _currentIndex = 0;
  String? _selectedLabel;
  Problem? _selectedProblem;

  Future<void> _startSpin() async {
    if (_isSpinning) return;

    final appState = context.read<AppState>();
    final labels = appState.spinLabels;
    if (labels.isEmpty) return;

    final selectedProblem = appState.getWeightedRandomProblem();
    final selectedLabel =
        '${selectedProblem.topic} • ${selectedProblem.difficulty}';

    int targetIndex = labels.indexOf(selectedLabel);
    if (targetIndex == -1) {
      targetIndex = 0;
    }

    setState(() {
      _isSpinning = true;
      _selectedProblem = null;
      _selectedLabel = null;
    });

    int fakeIndex = _random.nextInt(labels.length);
    int totalSteps = 24 + _random.nextInt(10);

    for (int i = 0; i < totalSteps; i++) {
      await Future.delayed(Duration(milliseconds: 70 + (i * 12)));

      if (!mounted) return;

      setState(() {
        fakeIndex = (fakeIndex + 1) % labels.length;
        _currentIndex = fakeIndex;
      });
    }

    await Future.delayed(const Duration(milliseconds: 250));

    if (!mounted) return;

    setState(() {
      _currentIndex = targetIndex;
      _selectedProblem = selectedProblem;
      _selectedLabel = selectedLabel;
      _isSpinning = false;
    });
  }

  void _goToQuestion() {
    if (_selectedProblem == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionScreen(problem: _selectedProblem!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labels = context.watch<AppState>().spinLabels;
    final currentLabel =
    labels.isEmpty ? 'No challenges available' : labels[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Spin Mode',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Spin Me!',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Spin to get a random SQL challenge',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SectionCard(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 230,
                        height: 230,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.purpleBright, AppColors.purple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.purple.withOpacity(0.35),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(
                                currentLabel,
                                key: ValueKey(currentLabel),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        _isSpinning
                            ? 'Spinning...'
                            : _selectedLabel ?? 'Tap spin to choose a challenge',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (_selectedProblem != null)
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Pill(
                              text: _selectedProblem!.topic,
                              bg: AppColors.cardSoft,
                            ),
                            _Pill(
                              text: _selectedProblem!.company,
                              bg: const Color(0xFF24304A),
                            ),
                            _Pill(
                              text: _selectedProblem!.difficulty,
                              bg: _difficultyColor(
                                _selectedProblem!.difficulty,
                              ),
                            ),
                            _Pill(
                              text: '+${_selectedProblem!.xp} XP',
                              bg: AppColors.purple,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [AppColors.purpleBright, AppColors.purple],
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: _isSpinning ? null : _startSpin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: Text(
                      _isSpinning ? 'Spinning...' : 'Spin Now',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _selectedProblem == null || _isSpinning
                      ? null
                      : _goToQuestion,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _selectedProblem == null
                          ? AppColors.textSecondary.withOpacity(0.3)
                          : AppColors.purple,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Start Challenge',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
}

class _Pill extends StatelessWidget {
  final String text;
  final Color bg;

  const _Pill({
    required this.text,
    required this.bg,
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
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}