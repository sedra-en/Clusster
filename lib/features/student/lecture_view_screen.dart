import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';
import 'package:cluster_app/features/student/student_lecture_ai_screen.dart';

class LectureViewScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final String studentId;
  final Color color;

  const LectureViewScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.studentId,
    required this.color,
  });

  @override
  State<LectureViewScreen> createState() => _LectureViewScreenState();
}

class _LectureViewScreenState extends State<LectureViewScreen> {
  List<dynamic> _lectures = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getLectures(widget.courseId);
    if (mounted) setState(() { _lectures = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: _lectures.isEmpty
                            ? _emptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                                itemCount: _lectures.length,
                                itemBuilder: (_, i) =>
                                    _lectureCard(_lectures[i], i),
                              ),
                      ),
              ),
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
            colors: [widget.color, widget.color.withOpacity(0.7)]),
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
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('lectures'.tr(),
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text(widget.courseTitle,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85), fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text("${_lectures.length}",
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return ListView(children: [
      const SizedBox(height: 100),
      Icon(Icons.video_library_outlined,
          size: 80, color: getSecondaryTextColor(context).withOpacity(0.3)),
      const SizedBox(height: 12),
      Center(
        child: Text('no_lectures_in_course'.tr(),
            style: GoogleFonts.poppins(color: getSecondaryTextColor(context))),
      ),
    ]);
  }

  Widget _lectureCard(dynamic l, int index) {
    final hasAI = l['has_ai']?.toString() == '1';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: widget.color.withOpacity(0.15)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: hasAI
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentLectureAIScreen(
                        lectureId: l['id'].toString(),
                        lectureTitle: l['title'] ?? '',
                        studentId: widget.studentId,
                        color: widget.color,
                      ),
                    ),
                  )
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ai_content_not_ready_yet'.tr())),
                  );
                },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text("${index + 1}",
                      style: TextStyle(
                          color: widget.color,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l['title'] ?? '',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      if (hasAI)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text("AI ✓",
                              style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('preparing'.tr(),
                              style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
                Icon(
                  hasAI
                      ? Icons.arrow_forward_ios_rounded
                      : Icons.lock_outline_rounded,
                  size: 14,
                  color: hasAI ? widget.color : Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}