import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';

class InstructorLectureAIViewScreen extends StatefulWidget {
  final String lectureId;
  final String lectureTitle;
  final Color color;

  const InstructorLectureAIViewScreen({
    super.key,
    required this.lectureId,
    required this.lectureTitle,
    required this.color,
  });

  @override
  State<InstructorLectureAIViewScreen> createState() =>
      _InstructorLectureAIViewScreenState();
}

class _InstructorLectureAIViewScreenState
    extends State<InstructorLectureAIViewScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> _data = {};
  bool _loading = true;
  bool _generating = false;
  bool _saving = false;
  bool _isPublished = false;
  String _selectedLevel = 'medium';
  late TabController _tabController;

  final Map<String, TextEditingController> _summaryControllers = {
    'easy': TextEditingController(),
    'medium': TextEditingController(),
    'hard': TextEditingController(),
  };
  bool _editingMode = false;
  List<dynamic> _editableQuiz = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _summaryControllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getLectureAIContent(widget.lectureId);
    if (mounted) {
      setState(() {
        _data = data;
        _loading = false;
        _isPublished = (_ai?['is_published']?.toString() == '1');
        _summaryControllers['easy']!.text =
            _ai?['easy_summary']?.toString() ?? '';
        _summaryControllers['medium']!.text =
            _ai?['medium_summary']?.toString() ?? '';
        _summaryControllers['hard']!.text =
            _ai?['hard_summary']?.toString() ?? '';
        _editableQuiz = List<dynamic>.from(_quizQuestions);
      });
    }
  }

  Future<void> _generateNow() async {
    setState(() => _generating = true);
    final res = await ApiService.generateAIContent(widget.lectureId);
    if (!mounted) return;
    setState(() => _generating = false);
    if (res['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ai_generated_success'.tr()),
          backgroundColor: Colors.green,
        ),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'ai_generation_failed'.tr())),
      );
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _saving = true);
    final res = await ApiService.updateAIContent(
      lectureId: widget.lectureId,
      easySummary: _summaryControllers['easy']!.text,
      mediumSummary: _summaryControllers['medium']!.text,
      hardSummary: _summaryControllers['hard']!.text,
      quizJson: _editableQuiz,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _editingMode = false;
    });
    if (res['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم الحفظ بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      _load();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res['message'] ?? 'فشل الحفظ')));
    }
  }

  // ✅ النشر يشتغل دايماً — مو بس أول مرة
  Future<void> _publish() async {
    final res = await ApiService.publishAIContent(widget.lectureId);
    if (!mounted) return;
    if (res['status'] == 'success') {
      setState(() => _isPublished = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم النشر للطلاب بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Map<String, dynamic>? get _ai {
    final ai = _data['ai_content'];
    if (ai is Map) return Map<String, dynamic>.from(ai);
    return null;
  }

  bool get _hasAI => _ai != null && _ai!['is_generated']?.toString() == '1';

  List get _quizQuestions {
    if (_ai == null) return [];
    final q = _ai!['quiz_json'];
    if (q is List) return q;
    if (q is String) {
      try {
        final decoded = json.decode(q);
        if (decoded is List) return decoded;
        if (decoded is Map && decoded['questions'] is List)
          return decoded['questions'];
      } catch (_) {}
    }
    if (q is Map && q['questions'] is List) return q['questions'];
    return [];
  }

  List<Map<String, String>> _extractOptions(Map q) {
    final qType = q['type']?.toString().toUpperCase() ?? '';
    if (qType == 'TF')
      return [
        {'key': 'صح', 'value': 'صح'},
        {'key': 'خطأ', 'value': 'خطأ'},
      ];
    var choices = q['choices'];
    if (choices is String) {
      try {
        choices = json.decode(choices);
      } catch (_) {}
    }
    if (choices is Map)
      return choices.entries
          .map((e) => {'key': e.key.toString(), 'value': e.value.toString()})
          .toList();
    return [];
  }

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
              else if (!_hasAI)
                Expanded(child: _emptyState())
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
                  'ai_smart_content'.tr(),
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
          if (_hasAI)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color:
                    _isPublished ? Colors.green : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isPublished ? Icons.check_circle : Icons.pending,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isPublished ? 'منشور' : 'غير منشور',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 60,
                color: widget.color,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'ai_not_generated_yet'.tr(),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            ScaleButton(
              onTap: _generating ? () {} : _generateNow,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.color, widget.color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_generating)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    else
                      const Icon(
                        Icons.psychology_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    const SizedBox(width: 10),
                    Text(
                      _generating ? 'generating'.tr() : 'generate_now'.tr(),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
                text: "${'tab_quiz'.tr()} (${_editableQuiz.length})",
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
    final controller = _summaryControllers[_selectedLevel]!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      children: [
        Row(
          children: [
            _levelChip('easy', 'Basic', Colors.green),
            const SizedBox(width: 8),
            _levelChip('medium', 'Standard', Colors.orange),
            const SizedBox(width: 8),
            _levelChip('hard', 'Advanced', Colors.red),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: getCardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  _editingMode ? widget.color : widget.color.withOpacity(0.15),
              width: _editingMode ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _editingMode ? Icons.save_rounded : Icons.edit_rounded,
                      size: 20,
                    ),
                    color: _editingMode ? Colors.green : widget.color,
                    onPressed:
                        _editingMode
                            ? _saveChanges
                            : () => setState(() => _editingMode = true),
                  ),
                  if (_editingMode)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: Colors.red,
                      onPressed: () => setState(() => _editingMode = false),
                    ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    color: widget.color,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: controller.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('summary_copied'.tr())),
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
              _editingMode
                  ? TextField(
                    controller: controller,
                    maxLines: null,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      hintText: 'اكتب التلخيص هنا...',
                    ),
                    style: const TextStyle(fontSize: 13, height: 1.8),
                  )
                  : (controller.text.isEmpty
                      ? Text(
                        'no_summary_for_level'.tr(),
                        textAlign: TextAlign.right,
                        style: TextStyle(color: getSecondaryTextColor(context)),
                      )
                      : _buildFormattedText(controller.text)),
            ],
          ),
        ),
        if (_saving) ...[
          const SizedBox(height: 10),
          const Center(child: CircularProgressIndicator()),
        ],
        const SizedBox(height: 14),
        ScaleButton(
          onTap: _generating ? () {} : _generateNow,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_generating)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: widget.color,
                      strokeWidth: 2,
                    ),
                  )
                else
                  Icon(Icons.refresh_rounded, color: widget.color, size: 18),
                const SizedBox(width: 8),
                Text(
                  _generating ? 'regenerating'.tr() : 'regenerate_content'.tr(),
                  style: TextStyle(
                    color: widget.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // ✅ زر النشر يشتغل دايماً
        ScaleButton(
          onTap: _publish,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _isPublished ? Colors.green : Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isPublished
                      ? Icons.check_circle_rounded
                      : Icons.publish_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _isPublished ? 'إعادة نشر للطلاب' : 'نشر للطلاب',
                  style: const TextStyle(
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
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
    if (_editableQuiz.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
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
                'no_quiz_questions'.tr(),
                style: GoogleFonts.poppins(
                  color: getSecondaryTextColor(context),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      itemCount: _editableQuiz.length,
      itemBuilder: (_, i) => _questionCard(i, _editableQuiz[i]),
    );
  }

  Widget _questionCard(int index, dynamic q) {
    if (q is! Map) return const SizedBox.shrink();
    final question = q['question']?.toString() ?? '';
    final correct = q['answer']?.toString() ?? q['correct']?.toString() ?? '';
    final options = _extractOptions(q);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 18),
                color: widget.color,
                onPressed: () => _showEditQuestionDialog(index, q),
              ),
              Expanded(
                child: Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: Text(
                    question,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${index + 1}",
                  style: TextStyle(
                    color: widget.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (options.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...options.map((entry) {
              final key = entry['key']!;
              final value = entry['value']!;
              final isCorrect = key == correct;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color:
                      isCorrect
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      isCorrect
                          ? Border.all(color: Colors.green.withOpacity(0.4))
                          : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Directionality(
                        textDirection: ui.TextDirection.rtl,
                        child: Text(
                          value,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight:
                                isCorrect ? FontWeight.w600 : FontWeight.normal,
                            color:
                                isCorrect
                                    ? Colors.green.shade800
                                    : getTextColor(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isCorrect
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: isCorrect ? Colors.green : Colors.grey.shade400,
                    ),
                    if (isCorrect) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'correct_answer'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  void _showEditQuestionDialog(int index, Map q) {
    final questionController = TextEditingController(
      text: q['question']?.toString() ?? '',
    );
    final answerController = TextEditingController(
      text: q['answer']?.toString() ?? '',
    );

    // استخراج الخيارات الحالية
    var choices = q['choices'];
    if (choices is String) {
      try {
        choices = json.decode(choices);
      } catch (_) {}
    }

    final Map<String, TextEditingController> choiceControllers = {};
    if (choices is Map) {
      choices.forEach((key, value) {
        choiceControllers[key.toString()] = TextEditingController(
          text: value.toString(),
        );
      });
    }

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(
              'تعديل السؤال ${index + 1}',
              textAlign: TextAlign.right,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: questionController,
                    maxLines: 3,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      labelText: 'نص السؤال',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (choiceControllers.isNotEmpty) ...[
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'الخيارات:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...choiceControllers.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextField(
                          controller: entry.value,
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            labelText: 'خيار ${entry.key}',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: answerController,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      labelText: 'الجواب الصحيح (مفتاح الخيار)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: widget.color),
                onPressed: () {
                  setState(() {
                    final updated = Map<String, dynamic>.from(q);
                    updated['question'] = questionController.text;
                    updated['answer'] = answerController.text;
                    // حفظ الخيارات المعدلة
                    if (choiceControllers.isNotEmpty) {
                      final updatedChoices = <String, String>{};
                      choiceControllers.forEach((key, ctrl) {
                        updatedChoices[key] = ctrl.text;
                      });
                      updated['choices'] = updatedChoices;
                    }
                    _editableQuiz[index] = updated;
                  });
                  Navigator.pop(context);
                  _saveChanges();
                },
                child: const Text('حفظ', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
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
