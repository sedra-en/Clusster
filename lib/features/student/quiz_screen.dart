import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';

class QuizScreen extends StatefulWidget {
  final String lectureId;
  final List<dynamic> questions;

  const QuizScreen({
    super.key,
    required this.lectureId,
    required this.questions,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  int _score = 0;
  String? _selectedAnswer;
  bool _isFinished = false;
  bool _isSubmitting = false;

  List<MapEntry<String, String>> _getChoices(Map<String, dynamic> q) {
    var choices = q['choices'];
    debugPrint("[DEBUG] choices type: ${choices.runtimeType}");
    debugPrint("[DEBUG] choices value: $choices");
    if (choices == null) return [];

    if (choices is String) {
      try {
        choices = json.decode(choices);
      } catch (_) {
        return [];
      }
    }

    if (choices is! Map) return [];
    return choices.entries
        .map((e) => MapEntry(e.key.toString(), e.value.toString()))
        .toList();
  }

  bool _isCorrect(Map<String, dynamic> q) {
    return _selectedAnswer == q['answer']?.toString();
  }

  void _nextQuestion() {
    final q = widget.questions[_currentIndex] as Map<String, dynamic>;
    if (_isCorrect(q)) _score++;

    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
      });
    } else {
      setState(() => _isFinished = true);
      _submitResult();
    }
  }

  Future<void> _submitResult() async {
    setState(() => _isSubmitting = true);
    final quizData = {
      "student_id": "1",
      "lecture_id": widget.lectureId,
      "score": ((_score / widget.questions.length) * 100).toInt(),
      "total_q": widget.questions.length,
      "correct_q": _score,
      "answers_json": [],
    };
    await ApiService.submitQuiz(quizData);
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) return _buildResultView();

    final q = widget.questions[_currentIndex] as Map<String, dynamic>;
    final qType = q['type']?.toString().toUpperCase() ?? 'MCQ';
    final choices = _getChoices(q);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'smart_quiz'.tr(),
          style: GoogleFonts.poppins(fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: AppBackground(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: (_currentIndex + 1) / widget.questions.length,
                backgroundColor: Colors.grey.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 20),
              Text(
                "${'question'.tr()} ${_currentIndex + 1} ${'of'.tr()} ${widget.questions.length}",
                style: GoogleFonts.poppins(
                  color: getSecondaryTextColor(context),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 15),
              ProGlassCard(
                child: Text(
                  q['question']?.toString() ?? '',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: getTextColor(context),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (qType == 'MCQ' && choices.isNotEmpty)
                Expanded(
                  child: ListView(
                    children:
                        choices
                            .map((e) => _buildChoiceTile(e.key, e.value))
                            .toList(),
                  ),
                ),

              if (qType == 'TF')
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildChoiceTile('صح', 'صح'),
                      const SizedBox(height: 16),
                      _buildChoiceTile('خطأ', 'خطأ'),
                    ],
                  ),
                ),

              if (qType == 'MCQ' && choices.isEmpty)
                const Expanded(child: Center(child: Text("لا يوجد خيارات"))),

              const SizedBox(height: 20),
              ScaleButton(
                onTap: _selectedAnswer == null ? () {} : _nextQuestion,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient:
                        _selectedAnswer == null
                            ? const LinearGradient(
                              colors: [Colors.grey, Colors.grey],
                            )
                            : const LinearGradient(
                              colors: [AppColors.primary, AppColors.darkBlue],
                            ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      _currentIndex == widget.questions.length - 1
                          ? 'done'.tr()
                          : 'next'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceTile(String key, String text) {
    bool isSelected = _selectedAnswer == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedAnswer = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : getCardColor(context),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color:
                isSelected ? AppColors.primary : Colors.grey.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: getTextColor(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView() {
    return Scaffold(
      body: AppBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  size: 100,
                  color: Colors.orangeAccent,
                ),
                const SizedBox(height: 20),
                Text(
                  'congratulations'.tr(),
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "${'you_scored'.tr()} $_score ${'out_of'.tr()} ${widget.questions.length}",
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 40),
                _isSubmitting
                    ? const CircularProgressIndicator()
                    : ScaleButton(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.darkBlue],
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: Text(
                            'done'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
