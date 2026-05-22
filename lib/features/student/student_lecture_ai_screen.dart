import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';
import 'package:cluster_app/features/student/student_quiz_screen.dart';

class StudentLectureAIScreen extends StatefulWidget {
  final String lectureId;
  final String lectureTitle;
  final String studentId;
  final Color color;

  const StudentLectureAIScreen({
    super.key,
    required this.lectureId,
    required this.lectureTitle,
    required this.studentId,
    required this.color,
  });

  @override
  State<StudentLectureAIScreen> createState() => _StudentLectureAIScreenState();
}

class _StudentLectureAIScreenState extends State<StudentLectureAIScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> _ai = {};
  bool _loading = true;
  String _selectedLevel = 'medium';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getAIContent(widget.lectureId);
    if (mounted) {
      setState(() {
        final aiContent = data['ai_content'];
        _ai = (aiContent is Map) ? Map<String, dynamic>.from(aiContent) : {};
        _loading = false;
      });
    }
  }

  String _summaryFor(String level) {
    switch (level) {
      case 'easy':
        return _ai['easy_summary']?.toString() ?? '';
      case 'medium':
        return _ai['medium_summary']?.toString() ?? '';
      case 'hard':
        return _ai['hard_summary']?.toString() ?? '';
    }
    return '';
  }

  List get _quizQuestions {
    final q = _ai['quiz_json'];
    if (q is List) return q;
    if (q is String) {
      try {
        final decoded = json.decode(q);
        if (decoded is List) return decoded;
      } catch (_) {}
    }
    if (q is Map && q['questions'] is List) return q['questions'];
    return [];
  }

  bool get _hasQuiz => _quizQuestions.isNotEmpty;

  Widget _buildFormattedText(String text) {
    final lines = text.split('\n');
    final widgets = <Widget>[];
    bool titleFound = false;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty ||
          trimmed.startsWith('===') ||
          trimmed.startsWith('---'))
        continue;
      if (trimmed.contains('مستوى التلخيص')) continue;
      final cleaned = trimmed.replaceAll(RegExp(r'\s*\(\d+[^)]*\)'), '').trim();
      if (cleaned.isEmpty) continue;

      if (!titleFound) {
        titleFound = true;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              cleaned,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.color,
              ),
            ),
          ),
        );
        continue;
      }

      if (cleaned.startsWith('* ')) {
        String content =
            cleaned.substring(2).replaceAll(RegExp(r'^JI\s*'), '').trim();
        if (content.isEmpty) continue;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    content,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      if (RegExp(r'^\d+\.').hasMatch(cleaned)) {
        final content = cleaned.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
        if (content.isEmpty) continue;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    content,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 13, height: 1.7),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      if (cleaned.length < 50 &&
          !cleaned.endsWith('.') &&
          !cleaned.contains('،')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 6),
            child: Text(
              cleaned,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: widget.color,
              ),
            ),
          ),
        );
        continue;
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4, right: 14),
          child: Text(
            cleaned,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, height: 1.8),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: widgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (_loading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(child: _contentView()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.color, widget.color.withOpacity(0.7)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'smart_content'.tr(),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  widget.lectureTitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contentView() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: getCardColor(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.color, widget.color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: getSecondaryTextColor(context),
            labelStyle: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            tabs: [
              Tab(
                icon: const Icon(Icons.description_rounded, size: 18),
                text: 'tab_summaries'.tr(),
              ),
              Tab(
                icon: const Icon(Icons.quiz_rounded, size: 18),
                text: "${'tab_quiz'.tr()} (${_quizQuestions.length})",
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_summariesTab(), _quizTab()],
          ),
        ),
      ],
    );
  }

  Widget _summariesTab() {
    final summaryText = _summaryFor(_selectedLevel);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tune_rounded, color: widget.color, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'choose_understanding_level'.tr(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _levelChip('easy', 'Basic', Colors.green),
                  const SizedBox(width: 8),
                  _levelChip('medium', 'Standard', Colors.orange),
                  const SizedBox(width: 8),
                  _levelChip('hard', 'Advanced', Colors.red),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: getCardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.color.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    color: widget.color,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: summaryText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('summary_copied_check'.tr())),
                      );
                    },
                  ),
                  const Spacer(),
                  Text(
                    'summary_for_level'.tr().replaceAll(
                      '{level}',
                      _levelLabel(_selectedLevel),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: widget.color,
                    size: 18,
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              summaryText.isEmpty
                  ? Text(
                    'no_summary_for_level'.tr(),
                    textAlign: TextAlign.right,
                    style: TextStyle(color: getSecondaryTextColor(context)),
                  )
                  : _buildFormattedText(summaryText),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_hasQuiz)
          ScaleButton(
            onTap: () => _tabController.animateTo(1),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.color, widget.color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.quiz_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'ready_for_quiz'.tr(),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _levelChip(String level, String label, Color color) {
    final selected = _selectedLevel == level;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedLevel = level),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(selected ? 1 : 0.3)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _quizTab() {
    if (!_hasQuiz) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 60,
              color: getSecondaryTextColor(context).withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'no_quiz_for_lecture'.tr(),
              style: GoogleFonts.poppins(color: getSecondaryTextColor(context)),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.color, widget.color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.psychology_rounded,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 10),
                Text(
                  'smart_quiz_title'.tr(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'test_after_summaries'.tr(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _quizMeta(
                      Icons.help_outline_rounded,
                      "${_quizQuestions.length}",
                      'questions_label'.tr(),
                    ),
                    _quizMeta(
                      Icons.timer_outlined,
                      "~${_quizQuestions.length * 2}",
                      'minutes_label'.tr(),
                    ),
                    _quizMeta(
                      Icons.emoji_events_outlined,
                      "${_quizQuestions.length}",
                      'points_label'.tr(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ScaleButton(
            onTap: _startQuiz,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'start_quiz_btn'.tr(),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quizMeta(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  Future<void> _startQuiz() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => StudentQuizScreen(
              lectureId: widget.lectureId,
              lectureTitle: widget.lectureTitle,
              studentId: widget.studentId,
              questions: _quizQuestions,
              color: widget.color,
            ),
      ),
    );
    if (result != null && mounted) _load();
  }

  String _levelLabel(String l) {
    switch (l) {
      case 'easy':
        return 'Basic';
      case 'medium':
        return 'Standard';
      case 'hard':
        return 'Advanced';
      default:
        return l;
    }
  }
}
