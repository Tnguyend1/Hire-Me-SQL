import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import '../data/mock_problems.dart';
import '../data/mock_user_stats.dart';
import '../models/achievement.dart';
import '../models/activity_item.dart';
import '../models/problem.dart';
import '../models/topic_progress.dart';
import '../models/user_stats.dart';
import '../models/wrong_attempt.dart';
import '../data/question_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AppState extends ChangeNotifier {
  static const String _userNameKey = 'user_name';
  static const String _totalXpKey = 'total_xp';
  static const String _solvedCountKey = 'solved_count';
  static const String _attemptCountKey = 'attempt_count';
  static const String _streakDaysKey = 'streak_days';
  static const String _badgesKey = 'badges';
  static const String _currentLevelXpKey = 'current_level_xp';
  static const String _nextLevelXpKey = 'next_level_xp';
  // Legacy key (pre-uid scoping). We'll still read it as a fallback.
  static const String _wrongAttemptsLegacyKey = 'wrong_attempts';
  static const String _wrongAttemptsGuestKey = 'wrong_attempts_guest';
  static const String _wrongAttemptsKeyPrefix = 'wrong_attempts_';
  static const String _recentActivityLegacyKey = 'recent_activity';
  static const String _recentActivityGuestKey = 'recent_activity_guest';
  static const String _recentActivityKeyPrefix = 'recent_activity_';
  static const String _lastSignedInUidKey = 'last_signed_in_uid';
  static const String _dailyProblemIdKey = 'daily_problem_id';
  static const String _dailyDateKey = 'daily_date';
  static const String _lastActiveDateKey = 'last_active_date';
  static const String _achievementsKey = 'achievements';

  bool _isReady = false;

  UserStats _userStats = mockUserStats;
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  User? firebaseUser;
  Map<String, dynamic>? firebaseUserData;

  final Set<String> _solvedProblemIds = {};
  final List<Problem> _problems = [];
  final List<WrongAttempt> _wrongAttempts = [];
  final List<ActivityItem> _recentActivity = [];
  List<Achievement> _achievements = [
    const Achievement(
      id: 'first_steps',
      title: 'First Steps',
      description: 'Solve 1 question',
      emoji: '🎯',
      isUnlocked: false,
    ),
    const Achievement(
      id: 'getting_warmed_up',
      title: 'Getting Warmed Up',
      description: 'Solve 5 questions',
      emoji: '📘',
      isUnlocked: false,
    ),
    const Achievement(
      id: 'consistent_learner',
      title: 'Consistent Learner',
      description: 'Reach a 3-day streak',
      emoji: '🔥',
      isUnlocked: false,
    ),
    const Achievement(
      id: 'on_fire',
      title: 'On Fire',
      description: 'Reach a 7-day streak',
      emoji: '🚀',
      isUnlocked: false,
    ),
    const Achievement(
      id: 'accuracy_master',
      title: 'Accuracy Master',
      description: 'Reach 80% accuracy with at least 10 attempts',
      emoji: '🏆',
      isUnlocked: false,
    ),
  ];

  bool get isReady => _isReady;
  UserStats get userStats => _userStats;
  List<Problem> get problems => List.unmodifiable(_problems);
  List<WrongAttempt> get wrongAttempts => List.unmodifiable(_wrongAttempts);
  List<ActivityItem> get recentActivity => List.unmodifiable(_recentActivity);
  List<Achievement> get achievements => List.unmodifiable(_achievements);

  void initAuth() {
    _authService.authStateChanges.listen((user) async {
      firebaseUser = user;

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        _loadWrongAttemptsForUid(prefs, user.uid);
        _loadRecentActivityForUid(prefs, user.uid);

        Map<String, dynamic>? data;
        List<Map<String, dynamic>> progressList = const [];
        try {
          data = await _firestoreService.getUser(user.uid);
          progressList = await _firestoreService.getUserProgress(user.uid);
        } catch (_) {
          // If Firestore is unavailable, keep local cached state and avoid crashing.
        }

        firebaseUserData = data;

        // If Firestore has history, it should override the local cache.
        // If it's empty (or the user has no progress yet), keep the cached activity.
        if (progressList.isNotEmpty) {
          _recentActivity
            ..clear()
            ..addAll(
              progressList.map((p) {
                final questionId = p['questionId'] as String?;
                final titleFromDoc = p['title'] as String?;
                final titleFromQuestionId =
                    (questionId != null ? getProblemById(questionId)?.title : null);
                final title = titleFromDoc ?? titleFromQuestionId ?? 'Question';
                final topic = p['topic'] as String? ?? '';
                final company = p['company'] as String? ?? '';

                final isCorrect =
                    p['isCorrect'] == true ||
                    p['lastResult'] == true ||
                    p['status'] == 'correct';

                final ts = (p['timestamp'] as Timestamp?) ?? (p['updatedAt'] as Timestamp?);
                final date = ts?.toDate() ?? DateTime.now();

                final subtitle = isCorrect
                    ? '$topic • $company'
                    : 'Wrong attempt • $topic';

                return ActivityItem(
                  title: title,
                  subtitle: subtitle,
                  xp: isCorrect ? 10 : 0,
                  date: date,
                );
              }),
            );
        }

        if (data != null) {
          _userStats = _userStats.copyWith(
            totalXp: data['xp'] ?? _userStats.totalXp,
            solvedCount: data['totalSolved'] ?? _userStats.solvedCount,
            attemptCount: data['attemptCount'] ?? _userStats.attemptCount,
            streakDays: data['streak'] ?? _userStats.streakDays,
            badges: data['badges'] ?? _userStats.badges,
            currentLevelXp: data['currentLevelXp'] ?? _userStats.currentLevelXp,
            nextLevelXp: data['nextLevelXp'] ?? _userStats.nextLevelXp,
          );
        }
      } else {
        _recentActivity.clear();
        _wrongAttempts.clear();
        firebaseUserData = null;
      }

      notifyListeners();
    });
  }

  Future<String?> signUp(String email, String password, String name) async {
    try {
      final cred = await _authService.signUp(email, password);

      await _firestoreService.createUser(
        uid: cred.user!.uid,
        name: name,
        email: email,
      );

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Signup failed';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _authService.signIn(email, password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Login failed';
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    firebaseUser = null;
    firebaseUserData = null;
    _recentActivity.clear();
    _wrongAttempts.clear();
    notifyListeners();
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final loaded = await QuestionRepository.loadQuestions();

    _problems.clear();
    _problems.addAll(loaded);

    print('Loaded problems: ${_problems.length}');
    print('Topics: ${_problems.map((p) => p.topic).toList()}');

    _userStats = _userStats.copyWith(
      totalXp: prefs.getInt(_totalXpKey) ?? _userStats.totalXp,
      solvedCount: prefs.getInt(_solvedCountKey) ?? _userStats.solvedCount,
      attemptCount: prefs.getInt(_attemptCountKey) ?? _userStats.attemptCount,
      streakDays: prefs.getInt(_streakDaysKey) ?? _userStats.streakDays,
      badges: prefs.getInt(_badgesKey) ?? _userStats.badges,
      currentLevelXp:
      prefs.getInt(_currentLevelXpKey) ?? _userStats.currentLevelXp,
      nextLevelXp: prefs.getInt(_nextLevelXpKey) ?? _userStats.nextLevelXp,
    );

    _loadAchievements(prefs);

    _isReady = true;
    // Start auth listener only after core data is loaded, so lookups (e.g. by problemId)
    // work deterministically when hydrating per-user caches.
    initAuth();
    notifyListeners();
  }

  Future<void> updateUserName(String name) async {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, cleaned);

    _userStats = _userStats.copyWith(name: cleaned);
    notifyListeners();
  }

  Problem? getProblemById(String id) {
    try {
      return _problems.firstWhere((problem) => problem.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Problem> getProblemsByTopic(String topic) {
    return _problems
        .where((problem) => problem.topic.toLowerCase() == topic.toLowerCase())
        .toList();
  }

  List<Problem> getProblemsByCompany(String company) {
    return _problems
        .where(
          (problem) => problem.company.toLowerCase() == company.toLowerCase(),
    )
        .toList();
  }

  Problem getRandomProblem() {
    if (_problems.isEmpty) {
      throw Exception('No problems available');
    }

    final shuffled = List<Problem>.from(_problems)..shuffle();
    return shuffled.first;
  }

  Problem getWeightedRandomProblem() {
    if (_problems.isEmpty) {
      throw Exception('No problems available');
    }

    final weightedPool = <Problem>[];

    for (final problem in _problems) {
      switch (problem.difficulty) {
        case 'Easy':
          weightedPool.addAll([problem, problem, problem, problem]);
          break;
        case 'Medium':
          weightedPool.addAll([problem, problem, problem]);
          break;
        case 'Hard':
          weightedPool.addAll([problem, problem]);
          break;
        default:
          weightedPool.add(problem);
      }
    }

    weightedPool.shuffle();
    return weightedPool.first;
  }

  List<String> get spinLabels {
    return _problems
        .map((problem) => '${problem.topic} • ${problem.difficulty}')
        .toSet()
        .toList();
  }

  Future<Problem> getDailyChallengeProblem() async {
    if (_problems.isEmpty) {
      throw Exception('No problems available');
    }

    final prefs = await SharedPreferences.getInstance();

    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';

    final savedDate = prefs.getString(_dailyDateKey);
    final savedProblemId = prefs.getString(_dailyProblemIdKey);

    if (savedDate == todayString && savedProblemId != null) {
      final existing = getProblemById(savedProblemId);
      if (existing != null) return existing;
    }

    final shuffled = List<Problem>.from(_problems)..shuffle();
    final newProblem = shuffled.first;

    await prefs.setString(_dailyDateKey, todayString);
    await prefs.setString(_dailyProblemIdKey, newProblem.id);

    return newProblem;
  }

  bool isProblemSolved(String id) {
    return _solvedProblemIds.contains(id);
  }

  Future<void> submitAttempt({
    required bool isCorrect,
    required int xpEarned,
    required Problem problem,
    required String userAnswer,
  }) async {
    await _updateStreak();

    final updatedAttempts = _userStats.attemptCount + 1;

    int updatedSolved = _userStats.solvedCount;
    int updatedXp = _userStats.totalXp;

    final alreadySolved = _solvedProblemIds.contains(problem.id);

    if (isCorrect) {
      if (!alreadySolved) {
        updatedSolved += 1;
        updatedXp += xpEarned;
        _solvedProblemIds.add(problem.id);
      }

      _recentActivity.insert(
        0,
        ActivityItem(
          title: problem.title,
          subtitle: '${problem.topic} • ${problem.company}',
          xp: xpEarned,
          date: DateTime.now(),
        ),
      );
    } else {
      _wrongAttempts.insert(
        0,
        WrongAttempt(
          problem: problem,
          userAnswer: userAnswer,
          date: DateTime.now(),
        ),
      );

      _recentActivity.insert(
        0,
        ActivityItem(
          title: problem.title,
          subtitle: 'Wrong attempt • ${problem.topic}',
          xp: 0,
          date: DateTime.now(),
        ),
      );
    }

    if (_recentActivity.length > 20) {
      _recentActivity.removeRange(20, _recentActivity.length);
    }

    _userStats = _userStats.copyWith(
      attemptCount: updatedAttempts,
      solvedCount: updatedSolved,
      totalXp: updatedXp,
      currentLevelXp: updatedXp,
    );

    _updateAchievements();
    await _persistState();

    if (firebaseUser != null) {
      final uid = firebaseUser!.uid;

      try {
        await _firestoreService.saveQuestionProgress(
          uid: uid,
          questionId: problem.id.toString(),
          title: problem.title,
          topic: problem.topic,
          company: problem.company ?? '',
          isCorrect: isCorrect,
        );

        await _firestoreService.updateUserStats(
          uid: uid,
          totalXp: userStats.totalXp,
          solvedCount: userStats.solvedCount,
          attemptCount: userStats.attemptCount,
          streakDays: userStats.streakDays,
          badges: userStats.badges,
          currentLevelXp: userStats.currentLevelXp,
          nextLevelXp: userStats.nextLevelXp,
        );
      } catch (_) {
        // Don't crash the app during review if network/Firestore fails.
      }
    }

    notifyListeners();
  }

  Future<void> markWrongAttemptRetried(WrongAttempt attempt) async {
    if (attempt.isRetried) return;
    attempt.isRetried = true;
    await _persistState();
    notifyListeners();
  }

  List<TopicProgress> get topicProgress {
    final Map<String, int> totals = {};
    final Map<String, int> solvedCounts = {};

    for (final problem in _problems) {
      totals[problem.topic] = (totals[problem.topic] ?? 0) + 1;
    }

    for (final activity in _recentActivity) {
      if (activity.xp <= 0) continue;

      final matchedProblems =
      _problems.where((problem) => problem.title == activity.title);

      for (final problem in matchedProblems) {
        solvedCounts[problem.topic] = (solvedCounts[problem.topic] ?? 0) + 1;
      }
    }

    return totals.entries.map((entry) {
      return TopicProgress(
        topic: entry.key,
        solved: solvedCounts[entry.key] ?? 0,
        total: entry.value,
      );
    }).toList();
  }

  Future<void> _updateStreak() async {
    final prefs = await SharedPreferences.getInstance();

    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';

    final lastActive = prefs.getString(_lastActiveDateKey);

    if (lastActive == null) {
      await prefs.setString(_lastActiveDateKey, todayString);
      _userStats = _userStats.copyWith(streakDays: 1);
      return;
    }

    final parts = lastActive.split('-');
    final lastDate = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );

    final todayDate = DateTime(today.year, today.month, today.day);
    final difference = todayDate.difference(lastDate).inDays;

    if (difference == 0) {
      return;
    } else if (difference == 1) {
      _userStats = _userStats.copyWith(streakDays: _userStats.streakDays + 1);
    } else {
      _userStats = _userStats.copyWith(streakDays: 1);
    }

    await prefs.setString(_lastActiveDateKey, todayString);
  }

  void _updateAchievements() {
    _achievements = _achievements.map((achievement) {
      bool unlock = achievement.isUnlocked;

      switch (achievement.id) {
        case 'first_steps':
          unlock = _userStats.solvedCount >= 1;
          break;
        case 'getting_warmed_up':
          unlock = _userStats.solvedCount >= 5;
          break;
        case 'consistent_learner':
          unlock = _userStats.streakDays >= 3;
          break;
        case 'on_fire':
          unlock = _userStats.streakDays >= 7;
          break;
        case 'accuracy_master':
          unlock = _userStats.attemptCount >= 10 && _userStats.accuracy >= 80;
          break;
      }

      return achievement.copyWith(isUnlocked: unlock);
    }).toList();

    final unlockedCount =
        _achievements.where((item) => item.isUnlocked).length;

    _userStats = _userStats.copyWith(badges: unlockedCount);
  }

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = firebaseUser?.uid;
    if (uid != null) {
      // Used to safely migrate legacy caches only for the same previously signed-in user.
      prefs.setString(_lastSignedInUidKey, uid);
    }

    await prefs.setInt(_totalXpKey, _userStats.totalXp);
    await prefs.setInt(_solvedCountKey, _userStats.solvedCount);
    await prefs.setInt(_attemptCountKey, _userStats.attemptCount);
    await prefs.setInt(_streakDaysKey, _userStats.streakDays);
    await prefs.setInt(_badgesKey, _userStats.badges);
    await prefs.setInt(_currentLevelXpKey, _userStats.currentLevelXp);
    await prefs.setInt(_nextLevelXpKey, _userStats.nextLevelXp);

    final wrongAttemptsJson = _wrongAttempts.map((attempt) {
      return {
        'problemId': attempt.problem.id,
        'userAnswer': attempt.userAnswer,
        'date': attempt.date.toIso8601String(),
        'isRetried': attempt.isRetried,
      };
    }).toList();

    final recentActivityJson = _recentActivity.map((item) {
      return {
        'title': item.title,
        'subtitle': item.subtitle,
        'xp': item.xp,
        'date': item.date.toIso8601String(),
      };
    }).toList();

    final achievementsJson = _achievements.map((item) {
      return {
        'id': item.id,
        'title': item.title,
        'description': item.description,
        'emoji': item.emoji,
        'isUnlocked': item.isUnlocked,
      };
    }).toList();

    final wrongAttemptsKey = uid != null ? _wrongAttemptsKeyForUid(uid) : _wrongAttemptsGuestKey;
    await prefs.setString(wrongAttemptsKey, jsonEncode(wrongAttemptsJson));
    final recentActivityKey = firebaseUser?.uid != null
        ? (() {
            final uid = firebaseUser!.uid;
            // Lets us safely migrate the legacy cache only for the same user.
            return _recentActivityKeyForUid(uid);
          })()
        : _recentActivityGuestKey;
    await prefs.setString(recentActivityKey, jsonEncode(recentActivityJson));
    await prefs.setString(_achievementsKey, jsonEncode(achievementsJson));
  }

  String _wrongAttemptsKeyForUid(String uid) {
    return '$_wrongAttemptsKeyPrefix$uid';
  }

  void _loadWrongAttemptsForUid(SharedPreferences prefs, String uid) {
    _wrongAttempts.clear();

    final userKey = _wrongAttemptsKeyForUid(uid);
    final rawUser = prefs.getString(userKey);
    final lastUid = prefs.getString(_lastSignedInUidKey);
    final rawLegacy =
        (lastUid == uid) ? prefs.getString(_wrongAttemptsLegacyKey) : null;
    final raw = rawUser ?? rawLegacy;
    if (raw == null || raw.isEmpty) return;

    try {
      final List<dynamic> decoded = jsonDecode(raw);

      for (final item in decoded) {
        final map = item as Map<String, dynamic>;
        final problem = getProblemById(map['problemId'] as String);
        if (problem == null) continue;

        _wrongAttempts.add(
          WrongAttempt(
            problem: problem,
            userAnswer: map['userAnswer'] as String? ?? '',
            date: DateTime.tryParse(map['date'] as String? ?? '') ??
                DateTime.now(),
            isRetried: map['isRetried'] as bool? ?? false,
          ),
        );
      }
    } catch (_) {}
  }

  String _recentActivityKeyForUid(String uid) {
    return '$_recentActivityKeyPrefix$uid';
  }

  void _loadRecentActivityForUid(SharedPreferences prefs, String uid) {
    _recentActivity.clear();

    final userKey = _recentActivityKeyForUid(uid);
    final rawUser = prefs.getString(userKey);
    final lastUid = prefs.getString(_lastSignedInUidKey);
    final rawLegacy = (lastUid == uid) ? prefs.getString(_recentActivityLegacyKey) : null;
    final raw = rawUser ?? rawLegacy;
    if (raw == null || raw.isEmpty) return;

    try {
      final List<dynamic> decoded = jsonDecode(raw);

      for (final item in decoded) {
        final map = item as Map<String, dynamic>;
        _recentActivity.add(
          ActivityItem(
            title: map['title'] as String? ?? '',
            subtitle: map['subtitle'] as String? ?? '',
            xp: map['xp'] as int? ?? 0,
            date: DateTime.tryParse(map['date'] as String? ?? '') ??
                DateTime.now(),
          ),
        );
      }
    } catch (_) {}
  }

  void _loadAchievements(SharedPreferences prefs) {
    final raw = prefs.getString(_achievementsKey);
    if (raw == null || raw.isEmpty) {
      _updateAchievements();
      return;
    }

    try {
      final List<dynamic> decoded = jsonDecode(raw);
      _achievements = decoded.map((item) {
        final map = item as Map<String, dynamic>;
        return Achievement(
          id: map['id'] as String? ?? '',
          title: map['title'] as String? ?? '',
          description: map['description'] as String? ?? '',
          emoji: map['emoji'] as String? ?? '⭐',
          isUnlocked: map['isUnlocked'] as bool? ?? false,
        );
      }).toList();

      _updateAchievements();
    } catch (_) {
      _updateAchievements();
    }
  }
}