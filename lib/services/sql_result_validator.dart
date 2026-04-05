import '../models/sql_execution_result.dart';

class SqlResultValidation {
  final bool passed;
  final String reason;

  const SqlResultValidation({
    required this.passed,
    required this.reason,
  });
}

class SqlResultValidator {
  SqlResultValidation validate({
    required SqlExecutionResult executionResult,
    required List<Map<String, dynamic>> expectedOutput,
    required List<String> requiredKeywords,
    required String userQuery,
  }) {
    if (!executionResult.success) {
      return SqlResultValidation(
        passed: false,
        reason: executionResult.errorMessage ?? 'SQL execution failed.',
      );
    }

    final actual = _normalizeRows(executionResult.rows);
    final expected = _normalizeRows(expectedOutput);

    if (_rowsEqual(actual, expected)) {
      return const SqlResultValidation(
        passed: true,
        reason: 'Correct result.',
      );
    }

    final keywordFallbackPassed = _keywordFallback(
      userQuery: userQuery,
      requiredKeywords: requiredKeywords,
    );

    if (keywordFallbackPassed) {
      return const SqlResultValidation(
        passed: false,
        reason: 'Query structure looks reasonable, but the output does not match expected output.',
      );
    }

    return const SqlResultValidation(
      passed: false,
      reason: 'Output does not match expected output.',
    );
  }

  List<Map<String, dynamic>> _normalizeRows(List<Map<String, dynamic>> rows) {
    return rows
        .map((row) {
      final normalized = <String, dynamic>{};
      final sortedKeys = row.keys.toList()..sort();

      for (final key in sortedKeys) {
        normalized[key] = _normalizeValue(row[key]);
      }

      return normalized;
    })
        .toList()
      ..sort((a, b) => a.toString().compareTo(b.toString()));
  }

  dynamic _normalizeValue(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toString();
    if (value is String) return value.trim();
    return value.toString();
  }

  bool _rowsEqual(
      List<Map<String, dynamic>> a,
      List<Map<String, dynamic>> b,
      ) {
    if (a.length != b.length) return false;

    for (var i = 0; i < a.length; i++) {
      if (a[i].toString() != b[i].toString()) {
        return false;
      }
    }

    return true;
  }

  bool _keywordFallback({
    required String userQuery,
    required List<String> requiredKeywords,
  }) {
    final lower = userQuery.toLowerCase();
    return requiredKeywords.every((k) => lower.contains(k.toLowerCase()));
  }
}