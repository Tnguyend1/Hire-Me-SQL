import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/problem.dart';
import '../models/sql_execution_result.dart';

class SqlRunner {
  Future<SqlExecutionResult> run({
    required Problem problem,
    required String query,
  }) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      return SqlExecutionResult.failure(
        message: 'Please enter a SQL query.',
        query: query,
      );
    }

    if (!_isSafeReadOnlyQuery(trimmedQuery)) {
      return SqlExecutionResult.failure(
        message: 'Only SELECT queries are allowed.',
        query: query,
      );
    }

    Database? db;
    String? dbPath;

    try {
      dbPath = p.join(
        await getDatabasesPath(),
        'sql_practice_${DateTime.now().microsecondsSinceEpoch}.db',
      );

      db = await openDatabase(dbPath);

      for (final statement in problem.schema ?? const <String>[]) {
        final sql = statement.trim();
        if (sql.isNotEmpty) {
          await db.execute(sql);
        }
      }

      for (final entry in (problem.sampleData ?? {}).entries) {
        final tableName = entry.key;
        final rows = entry.value;

        for (final row in rows) {
          await db.insert(
            tableName,
            Map<String, Object?>.from(row),
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }
      }

      final rawRows = await db.rawQuery(trimmedQuery);
      final rows = rawRows
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);

      final columns = rows.isNotEmpty
          ? rows.first.keys.toList(growable: false)
          : _expectedColumns(problem);

      return SqlExecutionResult.success(
        columns: columns,
        rows: rows,
        query: trimmedQuery,
      );
    } catch (e) {
      return SqlExecutionResult.failure(
        message: _friendlyErrorMessage(e),
        query: trimmedQuery,
      );
    } finally {
      if (db != null) {
        await db.close();
      }
      if (dbPath != null) {
        await deleteDatabase(dbPath);
      }
    }
  }

  bool _isSafeReadOnlyQuery(String sql) {
    final normalized = sql.trim().toUpperCase();

    final startsCorrectly =
        normalized.startsWith('SELECT') || normalized.startsWith('WITH');

    if (!startsCorrectly) return false;

    const blockedTokens = <String>[
      'INSERT ',
      'UPDATE ',
      'DELETE ',
      'DROP ',
      'ALTER ',
      'TRUNCATE ',
      'ATTACH ',
      'DETACH ',
      'PRAGMA ',
      'REPLACE ',
      'VACUUM ',
      'CREATE INDEX',
      'CREATE TRIGGER',
      'CREATE VIEW',
    ];

    for (final token in blockedTokens) {
      if (normalized.contains(token)) {
        return false;
      }
    }

    return true;
  }

  List<String> _expectedColumns(Problem problem) {
    final expected = problem.expectedOutput ?? const <Map<String, dynamic>>[];
    if (expected.isEmpty) return const [];
    return expected.first.keys.map((e) => e.toString()).toList();
  }

  String _friendlyErrorMessage(Object error) {
    final text = error.toString();
    if (text.startsWith('DatabaseException(')) {
      return text
          .replaceFirst('DatabaseException(', '')
          .replaceFirst(')', '');
    }
    return text;
  }
}