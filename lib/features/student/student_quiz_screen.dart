import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';

class StudentQuizScreen extends StatefulWidget {
  final String lectureId;
  final String lectureTitle;
  final String studentId;
  final List<dynamic> questions;
  final Color color;

  const StudentQuizScreen({
    super.key,
    required this.lectureId,
    required this.lectureTitle,
    required this.studentId,
    required this.questions,
    required this.color,
  });

  @override
  State<StudentQuizScreen> createState() => _StudentQuizScreenState();
}

class _StudentQuizScreenState extends State<StudentQuizScreen> {
  int _currentIndex = 0;
  final Map<int, String> _answers = {};
  bool _submitting = false;
  bool _showFeedback = false; // ✅ عرض التصحيح بعد الاختيار
  Map<String, dynamic>? _result;

  Map<String, dynamic> get _q =>
      widget.questions[_currentIndex] as Map<String, dynamic>;

  String get _correctAnswer {
    final q = _q;
    final qType = q['type']?.toString().toUpperCase() ?? '';
    if (qType == 'TF') return q['answer']?.toString() ?? '';
    // للـ MCQ — الجواب هو المفتاح (أ،ب،ج،د) لكن بدنا نرجع النص
    final correct = q['answer']?.toString() ?? q['correct']?.toString() ?? '';
    var choices = q['choices'];
    if (choices is String) {
      try {
        choices = json.decode(choices);
      } catch (_) {}
    }
    if (choices is Map && choices.containsKey(correct)) {
      return choices[correct].toString();
    }
    return correct;
  }

  List get _options {
    var choices = _q['choices'];
    final qType = _q['type']?.toString().toUpperCase() ?? '';
    if (qType == 'TF') return ['صح', 'خطأ'];
    if (choices == null) return [];
    if (choices is List) return choices;
    if (choices is String) {
      try {
        final decoded = json.decode(choices);
        if (decoded is Map) return decoded.values.toList();
      } catch (_) {}
    }
    if (choices is Map) return choices.values.toList();
    return [];
  }

  bool get _isLast => _currentIndex == widget.questions.length - 1;
  int get _answeredCount => _answers.length;

  void _selectAnswer(String option) {
    if (_showFeedback) return; // ما تسمحي بالتغيير بعد التصحيح
    setState(() {
      _answers[_currentIndex] = option;
      _showFeedback = true; // اعرض التصحيح فوراً
    });
  }

  void _goNext() {
    if (_isLast) {
      _submit();
    } else {
      setState(() {
        _currentIndex++;
        _showFeedback = false;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final answers = <Map<String, dynamic>>[];
    for (int i = 0; i < widget.questions.length; i++) {
      final q = widget.questions[i] as Map<String, dynamic>;
      answers.add({
        "question": q['question']?.toString() ?? '',
        "selected": _answers[i] ?? '',
        "correct": q['answer']?.toString() ?? q['correct']?.toString() ?? '',
      });
    }
    final res = await ApiService.submitQuiz({
      "student_id": widget.studentId,
      "lecture_id": widget.lectureId,
      "answers": answers,
    });
    if (!mounted) return;
    if (res['status'] == 'success') {
      setState(() {
        _submitting = false;
        _result = Map<String, dynamic>.from(res['data'] ?? {});
      });
    } else {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res['message'] ?? 'فشل الإرسال')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _result != null,
      child: Scaffold(
        body: AppBackground(
          child: SafeArea(
            child:
                _result != null
                    ? _resultView()
                    : Column(
                      children: [
                        _buildHeader(),
                        _buildProgressBar(),
                        Expanded(child: _questionView()),
                        _buildBottomBar(),
                      ],
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.color, widget.color.withOpacity(0.7)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _confirmExit,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
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
                  'quiz_label'.tr(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.lectureTitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "${_currentIndex + 1}/${widget.questions.length}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: (_currentIndex + 1) / widget.questions.length,
          minHeight: 6,
          backgroundColor: Colors.grey.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation(widget.color),
        ),
      ),
    );
  }

  Widget _questionView() {
    final selected = _answers[_currentIndex];
    final correct = _correctAnswer;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.color.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'question_n'.tr().replaceAll('{n}', '${_currentIndex + 1}'),
                    style: TextStyle(
                      color: widget.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: Text(
                    _q['question']?.toString() ?? '',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'choose_correct_answer'.tr(),
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: getSecondaryTextColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ..._options.map((e) => _optionTile(e.toString(), selected, correct)),

          if (_showFeedback && selected != null) ...[
            const SizedBox(height: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                    selected == correct
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected == correct ? Colors.green : Colors.red,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          selected == correct
                              ? '✅ إجابة صحيحة!'
                              : '❌ إجابة خاطئة',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                selected == correct ? Colors.green : Colors.red,
                            fontSize: 14,
                          ),
                        ),
                        if (selected != correct) ...[
                          const SizedBox(height: 6),
                          Text(
                            'الإجابة الصحيحة:',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              color: getSecondaryTextColor(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Directionality(
                            textDirection: ui.TextDirection.rtl,
                            child: Text(
                              correct,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    selected == correct
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: selected == correct ? Colors.green : Colors.red,
                    size: 28,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _optionTile(String option, String? selected, String correct) {
    final isSelected = selected == option;
    final isCorrect = option == correct;

    Color borderColor = Colors.grey.withOpacity(0.2);
    Color bgColor = getCardColor(context);
    Widget? trailingIcon;

    if (_showFeedback) {
      if (isCorrect) {
        borderColor = Colors.green;
        bgColor = Colors.green.withOpacity(0.1);
        trailingIcon = const Icon(
          Icons.check_circle_rounded,
          color: Colors.green,
          size: 20,
        );
      } else if (isSelected && !isCorrect) {
        borderColor = Colors.red;
        bgColor = Colors.red.withOpacity(0.1);
        trailingIcon = const Icon(
          Icons.cancel_rounded,
          color: Colors.red,
          size: 20,
        );
      }
    } else if (isSelected) {
      borderColor = widget.color;
      bgColor = widget.color.withOpacity(0.15);
    }

    return GestureDetector(
      onTap: () => _selectAnswer(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: borderColor,
            width: (_showFeedback && (isCorrect || isSelected)) ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Directionality(
                textDirection: ui.TextDirection.rtl,
                child: Text(
                  option,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight:
                        isSelected || (_showFeedback && isCorrect)
                            ? FontWeight.w600
                            : FontWeight.normal,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            trailingIcon ??
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? widget.color : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? widget.color : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child:
                      isSelected
                          ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                          : null,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final answered = _answers.containsKey(_currentIndex);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: getCardColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentIndex > 0 && !_showFeedback)
            Expanded(
              child: ScaleButton(
                onTap:
                    () => setState(() {
                      _currentIndex--;
                      _showFeedback = _answers.containsKey(_currentIndex);
                    }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: Text(
                      'previous'.tr(),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_currentIndex > 0 && !_showFeedback) const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ScaleButton(
              onTap:
                  _showFeedback
                      ? (_submitting ? () {} : _goNext)
                      : (!answered
                          ? () {}
                          : () => setState(() => _showFeedback = true)),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient:
                      (answered || _showFeedback)
                          ? LinearGradient(
                            colors: [
                              widget.color,
                              widget.color.withOpacity(0.7),
                            ],
                          )
                          : null,
                  color:
                      (answered || _showFeedback)
                          ? null
                          : Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child:
                      _submitting
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                          : Text(
                            _showFeedback
                                ? (_isLast ? 'submit_quiz'.tr() : 'next'.tr())
                                : 'next'.tr(),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultView() {
    final percentage =
        double.tryParse(_result?['percentage']?.toString() ?? '0') ?? 0;
    final correct = int.tryParse(_result?['correct']?.toString() ?? '0') ?? 0;
    final total =
        int.tryParse(
          _result?['total']?.toString() ?? '${widget.questions.length}',
        ) ??
        widget.questions.length;
    final passed = percentage >= 60;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors:
                      passed
                          ? [Colors.green, Colors.greenAccent]
                          : [Colors.orange, Colors.orangeAccent],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (passed ? Colors.green : Colors.orange).withOpacity(
                      0.4,
                    ),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  "${percentage.round()}%",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              passed ? 'quiz_excellent'.tr() : 'quiz_try_again'.tr(),
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: getCardColor(context),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _resultBox("$correct", 'correct_answers'.tr(), Colors.green),
                  _resultBox(
                    "${total - correct}",
                    'wrong_answers'.tr(),
                    Colors.red,
                  ),
                  _resultBox("$total", 'total_questions'.tr(), widget.color),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ScaleButton(
              onTap: () => Navigator.pop(context, _result),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    'back_to_summaries'.tr(),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultBox(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: getSecondaryTextColor(context),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmExit() async {
    if (_answers.isEmpty) {
      Navigator.pop(context);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('exit_quiz'.tr()),
            content: Text(
              'exit_quiz_confirm'
                  .tr()
                  .replaceAll('{answered}', '$_answeredCount')
                  .replaceAll('{total}', '${widget.questions.length}'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('cancel'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'exit'.tr(),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (ok == true && mounted) Navigator.pop(context);
  }
}
