class SqlExecutionResult {
  final bool success;
  final List<String> columns;
  final List<Map<String, dynamic>> rows;
  final String? errorMessage;
  final String executedQuery;

  const SqlExecutionResult({
    required this.success,
    required this.columns,
    required this.rows,
    required this.executedQuery,
    this.errorMessage,
  });

  factory SqlExecutionResult.success({
    required List<String> columns,
    required List<Map<String, dynamic>> rows,
    required String query,
  }) {
    return SqlExecutionResult(
      success: true,
      columns: columns,
      rows: rows,
      executedQuery: query,
    );
  }

  factory SqlExecutionResult.failure({
    required String message,
    required String query,
  }) {
    return SqlExecutionResult(
      success: false,
      columns: const [],
      rows: const [],
      executedQuery: query,
      errorMessage: message,
    );
  }
}