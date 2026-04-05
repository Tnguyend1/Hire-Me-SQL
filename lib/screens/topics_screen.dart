import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../models/problem.dart';
import '../state/app_state.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/section_card.dart';
import 'problem_list_screen.dart';

class TopicsScreen extends StatefulWidget {
  final bool initialShowTopics;

  const TopicsScreen({
    super.key,
    this.initialShowTopics = true,
  });

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  late bool showTopics;

  @override
  void initState() {
    super.initState();
    showTopics = widget.initialShowTopics;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final problems = appState.problems;

    // -------- TOPICS --------
    final topicMap = <String, List<Problem>>{};
    for (final p in problems) {
      final topic = p.topic.trim();
      if (topic.isEmpty) continue;
      topicMap.putIfAbsent(topic, () => []).add(p);
    }

    final topics = topicMap.entries.map((entry) {
      final topic = entry.key;
      final list = entry.value;

      final difficulties = list
          .map((p) => p.difficulty.trim())
          .where((d) => d.isNotEmpty)
          .toSet();

      final difficultyLabel =
      difficulties.length == 1 ? difficulties.first : 'Mixed';

      return (
      topic,
      _questionCountLabel(list.length),
      difficultyLabel,
      _getIconForTopic(topic),
      _getColorForTopic(topic),
      );
    }).toList()
      ..sort((a, b) => a.$1.compareTo(b.$1));

    // -------- COMPANIES --------
    final companyMap = <String, List<Problem>>{};
    for (final p in problems) {
      final company = p.company.trim();
      if (company.isEmpty) continue;
      companyMap.putIfAbsent(company, () => []).add(p);
    }

    final companies = companyMap.entries.map((entry) {
      final company = entry.key;
      final list = entry.value;

      final difficulties = list
          .map((p) => p.difficulty.trim())
          .where((d) => d.isNotEmpty)
          .toSet();

      final difficultyLabel =
      difficulties.length == 1 ? difficulties.first : 'Mixed';

      return (
      company,
      _questionCountLabel(list.length),
      difficultyLabel,
      _getIconForCompany(company),
      _getColorForCompany(company),
      );
    }).toList()
      ..sort((a, b) => a.$1.compareTo(b.$1));

    final items = showTopics ? topics : companies;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Choose Your Path',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                showTopics
                    ? 'Select a topic to start practicing'
                    : 'Select a company to practice real-style questions',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 22),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardSoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            showTopics = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: showTopics
                                ? AppColors.card
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              'By Topic',
                              style: TextStyle(
                                color: showTopics
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            showTopics = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: !showTopics
                                ? AppColors.card
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              'By Company',
                              style: TextStyle(
                                color: !showTopics
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              ...items.map(
                    (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _BrowseCard(
                    title: item.$1,
                    count: item.$2,
                    difficulty: item.$3,
                    icon: item.$4,
                    color: item.$5,
                    onTap: () {
                      final List<Problem> filteredProblems = showTopics
                          ? appState.getProblemsByTopic(item.$1)
                          : appState.getProblemsByCompany(item.$1);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProblemListScreen(
                            title: item.$1,
                            problems: filteredProblems,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrowseCard extends StatelessWidget {
  final String title;
  final String count;
  final String difficulty;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BrowseCard({
    required this.title,
    required this.count,
    required this.difficulty,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  Color get difficultyColor {
    switch (difficulty) {
      case 'Easy':
        return AppColors.green;
      case 'Hard':
        return AppColors.red;
      case 'Mixed':
        return AppColors.purple;
      default:
        return AppColors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SectionCard(
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [color, AppColors.purple],
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Pill(
                        text: count,
                        bg: AppColors.cardSoft,
                        textColor: AppColors.textPrimary,
                      ),
                      _Pill(
                        text: difficulty,
                        bg: difficultyColor,
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 30,
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
        ),
      ),
    );
  }
}

String _questionCountLabel(int count) {
  return count == 1 ? '1 question' : '$count questions';
}

IconData _getIconForTopic(String topic) {
  switch (topic) {
    case 'JOIN':
      return Icons.route;
    case 'Aggregation':
      return Icons.trending_up;
    case 'Subquery':
      return Icons.search;
    case 'Window Function':
      return Icons.bar_chart;
    case 'CTE':
      return Icons.account_tree;
    case 'Ranking':
      return Icons.leaderboard;
    case 'Date Functions':
      return Icons.calendar_month;
    case 'Case When':
      return Icons.rule;
    default:
      return Icons.code;
  }
}

Color _getColorForTopic(String topic) {
  switch (topic) {
    case 'JOIN':
      return AppColors.blue;
    case 'Aggregation':
      return AppColors.green;
    case 'Subquery':
      return AppColors.orange;
    case 'Window Function':
      return AppColors.purple;
    case 'CTE':
      return AppColors.purpleBright;
    case 'Ranking':
      return AppColors.orange;
    case 'Date Functions':
      return AppColors.blue;
    case 'Case When':
      return AppColors.green;
    default:
      return AppColors.blue;
  }
}

IconData _getIconForCompany(String company) {
  switch (company) {
    case 'Amazon':
      return Icons.shopping_bag_outlined;
    case 'Meta':
      return Icons.public;
    case 'Shopify':
      return Icons.storefront_outlined;
    case 'Instacart':
      return Icons.local_grocery_store_outlined;
    case 'DoorDash':
      return Icons.delivery_dining;
    case 'Uber':
      return Icons.local_taxi_outlined;
    case 'Google':
      return Icons.search;
    case 'Etsy':
      return Icons.shopping_cart_outlined;
    default:
      return Icons.business;
  }
}

Color _getColorForCompany(String company) {
  switch (company) {
    case 'Meta':
      return AppColors.purpleBright;
    case 'Shopify':
      return AppColors.green;
    case 'Amazon':
      return AppColors.orange;
    case 'Instacart':
      return AppColors.green;
    case 'DoorDash':
      return AppColors.red;
    case 'Uber':
      return AppColors.blue;
    case 'Google':
      return AppColors.purple;
    case 'Etsy':
      return AppColors.orange;
    default:
      return AppColors.purpleBright;
  }
}