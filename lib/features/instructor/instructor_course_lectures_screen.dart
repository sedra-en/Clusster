import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';
import 'package:cluster_app/core/api/chat_api.dart';
import 'package:cluster_app/features/instructor/upload_lecture_screen.dart';
import 'package:cluster_app/features/instructor/instructor_lecture_ai_view_screen.dart';
import 'package:cluster_app/features/instructor/instructor_course_quiz_stats_screen.dart';
import 'package:cluster_app/shared/lecture_view_screen.dart';
import 'package:cluster_app/features/chat/course_chat_screen.dart';

class InstructorCourseLecturesScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final Color color;
  final String? userId;
  final String? userName;

  const InstructorCourseLecturesScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.color,
    this.userId,
    this.userName,
  });

  @override
  State<InstructorCourseLecturesScreen> createState() =>
      _InstructorCourseLecturesScreenState();
}

class _InstructorCourseLecturesScreenState
    extends State<InstructorCourseLecturesScreen> {
  List<dynamic> _lectures = [];
  bool _loading = true;
  int _unreadCount = 0;
  Timer? _unreadTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _loadUnreadCount();
    _unreadTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadUnreadCount();
    });
  }

  @override
  void dispose() {
    _unreadTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getLectures(widget.courseId);
    if (mounted) {
      setState(() {
        _lectures = data;
        _loading = false;
      });
    }
  }

  Future<void> _loadUnreadCount() async {
    final userIdInt = int.tryParse(widget.userId ?? '0') ?? 0;
    if (userIdInt == 0) return;
    final courseIdInt = int.tryParse(widget.courseId) ?? 0;
    try {
      final data = await ChatApi.getUnreadCounts(userIdInt);
      final rawPerCourse = data['per_course'];
      Map<String, dynamic> perCourse = {};
      if (rawPerCourse is Map) {
        perCourse = Map<String, dynamic>.from(rawPerCourse);
      }
      final count = perCourse[courseIdInt.toString()] ??
          perCourse[courseIdInt] ?? 0;
      if (mounted) {
        setState(() {
          _unreadCount = (count is int)
              ? count
              : int.tryParse(count.toString()) ?? 0;
        });
      }
    } catch (e) {
      print('🔴 loadUnreadCount error: $e');
    }
  }

  Future<void> _openUpload() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UploadLectureScreen(
          courseId: widget.courseId,
          courseTitle: widget.courseTitle,
          color: widget.color,
        ),
      ),
    );
    _load();
  }

  void _openQuizStats() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InstructorCourseQuizStatsScreen(
          courseId: widget.courseId,
          courseTitle: widget.courseTitle,
          color: widget.color,
        ),
      ),
    );
  }

  void _openChat() {
    final userIdInt = int.tryParse(widget.userId ?? '0') ?? 0;
    final courseIdInt = int.tryParse(widget.courseId) ?? 0;
    if (userIdInt == 0 || courseIdInt == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطأ في معرّفات المستخدم')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseChatScreen(
          courseId: courseIdInt,
          userId: userIdInt,
          userName: widget.userName ?? 'Instructor',
          userRole: 'instructor',
          courseTitle: widget.courseTitle,
          color: widget.color,
        ),
      ),
    ).then((_) => _loadUnreadCount());
  }

  // ⭐ الانتقال الجديد — دائماً يفتح LectureViewScreen
  void _openLecture(dynamic l) {
    final hasAI = l['has_ai']?.toString() == '1';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LectureViewScreen(
          lectureId: l['id'].toString(),
          lectureTitle: l['title'] ?? '',
          color: widget.color,
          hasAI: hasAI,
          filePath: l['file_path']?.toString(),
          audioPath: l['audio_path']?.toString(),
          contentType: l['content_type']?.toString() ?? 'pdf',
          buildAIScreen: () => InstructorLectureAIViewScreen(
            lectureId: l['id'].toString(),
            lectureTitle: l['title'] ?? '',
            color: widget.color,
          ),
        ),
      ),
    ).then((_) => _load());
  }

  Future<void> _confirmDelete(dynamic l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('delete_lecture'.tr()),
        content: Text('delete_lecture_confirm'
            .tr()
            .replaceAll('{title}', l['title'] ?? '')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('cancel'.tr())),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('delete'.tr(),
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;

    final res = await ApiService.deleteLecture(l['id'].toString());
    if (!mounted) return;

    if (res['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('deleted_successfully'.tr()),
          backgroundColor: Colors.green));
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'delete_failed'.tr())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: _lectures.isEmpty
                          ? _emptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 5, 20, 90),
                              itemCount: _lectures.length,
                              itemBuilder: (_, i) => _lectureCard(_lectures[i]),
                            ),
                    ),
            ),
          ]),
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildChatFAB(),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'upload_btn',
            backgroundColor: widget.color,
            onPressed: _openUpload,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text('upload_new_lecture'.tr(),
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildChatFAB() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        FloatingActionButton(
          heroTag: 'chat_btn',
          onPressed: _openChat,
          backgroundColor: Colors.white,
          elevation: 6,
          child: Image.asset('assets/icons/icons8-message.gif',
              width: 32, height: 32),
        ),
        if (_unreadCount > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
              ),
              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
              child: Text(
                _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                style: const TextStyle(
                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
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
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('lectures'.tr(),
                style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.courseTitle,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.85), fontSize: 12)),
          ]),
        ),
        GestureDetector(
          onTap: _openQuizStats,
          child: Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(left: 6),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: Image.asset("assets/icons/icons8-statistics.gif",
                width: 22, height: 22, fit: BoxFit.contain),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10)),
          child: Text("${_lectures.length}",
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ]),
    );
  }

  Widget _emptyState() {
    return ListView(children: [
      const SizedBox(height: 100),
      Icon(Icons.video_library_outlined,
          size: 80, color: getSecondaryTextColor(context).withOpacity(0.3)),
      const SizedBox(height: 12),
      Center(child: Text('no_lectures_yet'.tr(),
          style: GoogleFonts.poppins(color: getSecondaryTextColor(context)))),
      const SizedBox(height: 4),
      Center(child: Text('press_upload_lecture'.tr())),
    ]);
  }

  Widget _lectureCard(dynamic l) {
    final hasAI = l['has_ai']?.toString() == '1';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: widget.color.withOpacity(0.15)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          // ⭐ دائماً يفتح LectureViewScreen
          onTap: () => _openLecture(l),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              const Icon(Icons.menu_book_rounded, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l['title'] ?? '',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    // Badge AI
                    if (hasAI)
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: Colors.green.withOpacity(0.3))),
                          child: const Text('AI ✓',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ])
                    else
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: Colors.orange.withOpacity(0.3))),
                          child: Text('preparing'.tr(),
                              style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ]),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.red, size: 20),
                onPressed: () => _confirmDelete(l),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}