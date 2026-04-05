import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../models/problem.dart';
import '../models/sql_execution_result.dart';
import '../services/sql_result_validator.dart';
import '../services/sql_runner.dart';
import '../state/app_state.dart';
import 'result_screen.dart';

class QuestionScreen extends StatefulWidget {
  final Problem problem;

  const QuestionScreen({super.key, required this.problem});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _showHint = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final userAnswer = _controller.text.trim();
    if (userAnswer.isEmpty || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final runner = SqlRunner();
    final validator = SqlResultValidator();

    final executionResult = await runner.run(
      problem: widget.problem,
      query: userAnswer,
    );

    final validationResult = validator.validate(
      executionResult: executionResult,
      expectedOutput: widget.problem.expectedOutput ?? const [],
      requiredKeywords: widget.problem.requiredKeywords,
      userQuery: userAnswer,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          problem: widget.problem,
          userAnswer: userAnswer,
          isCorrect: validationResult.passed,
          executionResult: executionResult,
          validationReason: validationResult.reason,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.problem;
    final user = context.watch<AppState>().userStats;
    final solvedTodayProgress = (user.solvedCount % 10) / 10;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context),
              const SizedBox(height: 16),
              _buildMetaRow(p),
              const SizedBox(height: 14),
              _buildTitleSection(p),
              const SizedBox(height: 22),
              _buildProblemCard(p),
              if (_hasTableContent(p)) ...[
                const SizedBox(height: 18),
                _buildTablesSection(p),
              ],
              if ((p.expectedOutput ?? []).isNotEmpty) ...[
                const SizedBox(height: 18),
                _buildExpectedOutputSection(p),
              ],
              const SizedBox(height: 18),
              _buildHintCard(),
              if (_showHint) ...[
                const SizedBox(height: 10),
                _buildHintTextCard(p),
              ],
              const SizedBox(height: 18),
              _buildEditorCard(),
              const SizedBox(height: 18),
              _buildProgressCard(user.solvedCount % 10, solvedTodayProgress),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpectedOutputSection(Problem p) {
    final rows = p.expectedOutput ?? [];
    final columns = rows.isNotEmpty
        ? rows.first.keys.map((e) => e.toString()).toList()
        : <String>[];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.fact_check_rounded,
                color: AppColors.purpleBright,
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'Expected Output',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (rows.isEmpty)
            const Text(
              'No expected output provided',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            )
          else
            _buildDataTable(columns: columns, rows: rows),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(999),
          child: const Padding(
            padding: EdgeInsets.all(6),
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
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildMetaRow(Problem p) {
    return Row(
      children: [
        _pill(
          text: p.difficulty,
          background: AppColors.orange,
          textColor: Colors.white,
        ),
        const SizedBox(width: 10),
        _pill(
          text: _topicLabel(p),
          background: const Color(0xFF2A2C37),
          textColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildTitleSection(Problem p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            height: 1.15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${p.company} • ${p.xp} XP',
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProblemCard(Problem p) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.storage_rounded,
                color: AppColors.purpleBright,
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'Problem Statement',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF2B2C37),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              p.statement,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.6,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablesSection(Problem p) {
    final tableNames = <String>{};

    for (final statement in p.schema ?? const <String>[]) {
      final tableName = _extractTableNameFromCreateStatement(statement);
      if (tableName != null && tableName.isNotEmpty) {
        tableNames.add(tableName);
      }
    }

    if (p.sampleData != null) {
      tableNames.addAll(p.sampleData!.keys);
    }

    final orderedTables = tableNames.toList()..sort();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.table_chart_rounded,
                color: AppColors.purpleBright,
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'Tables',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (final tableName in orderedTables) ...[
            _buildSingleTableCard(
              tableName: tableName,
              columns: _columnsForTable(p, tableName),
              rows: p.sampleData?[tableName] ?? const [],
            ),
            if (tableName != orderedTables.last) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildSingleTableCard({
    required String tableName,
    required List<String> columns,
    required List<Map<String, dynamic>> rows,
  }) {
    final effectiveColumns = columns.isNotEmpty
        ? columns
        : (rows.isNotEmpty
        ? rows.first.keys.map((e) => e.toString()).toList()
        : <String>[]);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131625),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tableName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (effectiveColumns.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: effectiveColumns
                  .map(
                    (column) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF232432),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    column,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
                  .toList(),
            ),
          if (effectiveColumns.isNotEmpty) const SizedBox(height: 14),
          if (rows.isEmpty)
            const Text(
              'No sample rows provided',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            )
          else
            _buildDataTable(columns: effectiveColumns, rows: rows),
        ],
      ),
    );
  }

  Widget _buildHintCard() {
    return InkWell(
      onTap: () => setState(() => _showHint = !_showHint),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1020),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF18356E)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.lightbulb_outline_rounded,
              color: AppColors.blue,
              size: 24,
            ),
            const SizedBox(width: 10),
            const Text(
              'Need a hint?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              _showHint ? 'Hide' : 'Show',
              style: const TextStyle(
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

  Widget _buildHintTextCard(Problem p) {
    return _card(
      color: const Color(0xFF131625),
      child: Text(
        p.hint,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 15,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildEditorCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.code_rounded,
                color: AppColors.purpleBright,
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'Your SQL Query',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1B26),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: TextField(
              controller: _controller,
              minLines: 10,
              maxLines: 10,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.5,
                fontFamily: 'monospace',
              ),
              decoration: const InputDecoration(
                hintText: 'SELECT * FROM ...',
                hintStyle: TextStyle(
                  color: Colors.white38,
                  fontSize: 15,
                  fontFamily: 'monospace',
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(18),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '${_controller.text.length} characters',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              _secondaryButton(
                text: 'Clear',
                onPressed: _isSubmitting
                    ? null
                    : () {
                  _controller.clear();
                },
              ),
              const SizedBox(width: 10),
              _primaryButton(
                text: _isSubmitting ? 'Running...' : 'Submit Answer',
                onPressed: _controller.text.trim().isEmpty || _isSubmitting
                    ? null
                    : _submit,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(int solvedInCycle, double progress) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Today's Progress",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '$solvedInCycle / 10 questions',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.purpleBright,
              ),
            ),
          ),
        ],
      ),
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

  Widget _pill({
    required String text,
    required Color background,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _card({
    required Widget child,
    Color? color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: child,
    );
  }

  Widget _secondaryButton({
    required String text,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF232432),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF232432).withOpacity(0.5),
          disabledForegroundColor: Colors.white54,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.white.withOpacity(0.06)),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String text,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          disabledBackgroundColor: AppColors.purple.withOpacity(0.45),
          disabledForegroundColor: Colors.white54,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  String _topicLabel(Problem p) {
    if (p.concepts.isNotEmpty) {
      return p.concepts.join(' & ').toUpperCase();
    }
    return p.topic.toUpperCase();
  }

  bool _hasTableContent(Problem p) {
    final hasSchema = p.schema != null && p.schema!.isNotEmpty;
    final hasSampleData = p.sampleData != null && p.sampleData!.isNotEmpty;
    return hasSchema || hasSampleData;
  }

  List<String> _columnsForTable(Problem p, String tableName) {
    for (final statement in p.schema ?? const <String>[]) {
      final parsedTableName = _extractTableNameFromCreateStatement(statement);
      if (parsedTableName == tableName) {
        return _extractColumnNamesFromCreateStatement(statement);
      }
    }

    final rows = p.sampleData?[tableName] ?? const <Map<String, dynamic>>[];
    if (rows.isNotEmpty) {
      return rows.first.keys.map((e) => e.toString()).toList();
    }

    return const [];
  }

  String? _extractTableNameFromCreateStatement(String statement) {
    final regex = RegExp(
      r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?["`]?([A-Za-z0-9_]+)["`]?',
      caseSensitive: false,
    );

    final match = regex.firstMatch(statement);
    return match?.group(1);
  }

  List<String> _extractColumnNamesFromCreateStatement(String statement) {
    final start = statement.indexOf('(');
    final end = statement.lastIndexOf(')');

    if (start == -1 || end == -1 || end <= start) {
      return const [];
    }

    final body = statement.substring(start + 1, end);
    final parts = body.split(',');

    final columns = <String>[];
    for (final rawPart in parts) {
      final part = rawPart.trim();
      if (part.isEmpty) continue;

      final upper = part.toUpperCase();
      if (upper.startsWith('PRIMARY KEY') ||
          upper.startsWith('FOREIGN KEY') ||
          upper.startsWith('UNIQUE') ||
          upper.startsWith('CHECK') ||
          upper.startsWith('CONSTRAINT')) {
        continue;
      }

      final tokens = part.split(RegExp(r'\s+'));
      if (tokens.isEmpty) continue;

      var column = tokens.first.trim();
      column = column.replaceAll('`', '').replaceAll('"', '');
      if (column.isNotEmpty) {
        columns.add(column);
      }
    }

    return columns;
  }
}