import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUser({
    required String uid,
    required String name,
    required String email,
  }) async {
    await _db.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'xp': 0,
      'level': 1,
      'streak': 0,
      'totalSolved': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  Future<void> saveQuestionProgress({
    required String uid,
    required String questionId,
    required String title,
    required String topic,
    required String company,
    required bool isCorrect,
  }) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('progress')
        .doc(questionId)
        .set({
      'questionId': questionId,
      'title': title,
      'topic': topic,
      'company': company,
      'status': isCorrect ? 'correct' : 'wrong',
      'isCorrect': isCorrect,
      'lastResult': isCorrect,
      'attempts': FieldValue.increment(1),
      // New field used by the app for ordering.
      'timestamp': FieldValue.serverTimestamp(),
      // Kept for backwards compatibility with older client versions.
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
  Future<void> updateUserStats({
    required String uid,
    required int totalXp,
    required int solvedCount,
    required int attemptCount,
    required int streakDays,
    required int badges,
    required int currentLevelXp,
    required int nextLevelXp,
  }) async {
    await _db.collection('users').doc(uid).set({
      'xp': totalXp,
      'totalSolved': solvedCount,
      'attemptCount': attemptCount,
      'streak': streakDays,
      'badges': badges,
      'currentLevelXp': currentLevelXp,
      'nextLevelXp': nextLevelXp,
      'lastActiveAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }
  Future<List<Map<String, dynamic>>> getUserProgress(String uid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('progress')
        // Older documents used `updatedAt`; keep ordering stable.
        .orderBy('updatedAt', descending: true)
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}