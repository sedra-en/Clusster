import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';
import 'package:cluster_app/core/api/chat_api.dart';
import 'package:cluster_app/core/constants/app_icons.dart';
import 'package:cluster_app/features/student/student_lecture_ai_screen.dart';
import 'package:cluster_app/shared/lecture_view_screen.dart';
import 'package:cluster_app/features/chat/course_chat_screen.dart';

class StudentCourseLecturesScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final String studentId;
  final Color color;
  final String? userId;
  final String? userName;

  const StudentCourseLecturesScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.studentId,
    required this.color,
    this.userId,
    this.userName,
  });

  @override
  State<StudentCourseLecturesScreen> createState() =>
      _StudentCourseLecturesScreenState();
}

class _StudentCourseLecturesScreenState
    extends State<StudentCourseLecturesScreen> {
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
          userName: widget.userName ?? 'Student',
          userRole: 'student',
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
          buildAIScreen: () => StudentLectureAIScreen(
            lectureId: l['id'].toString(),
            lectureTitle: l['title'] ?? '',
            studentId: widget.studentId,
            color: widget.color,
          ),
        ),
      ),
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
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: _lectures.isEmpty
                            ? _emptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
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
      floatingActionButton: _buildChatFAB(),
    );
  }

  Widget _buildChatFAB() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        FloatingActionButton.extended(
          onPressed: _openChat,
          backgroundColor: widget.color,
          elevation: 6,
          icon: Image.asset('assets/icons/icons8-message.gif',
              width: 24, height: 24),
          label: Text('course_chat'.tr(),
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.bold)),
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
                color: Colors.white.withOpacity(0.25), shape: BoxShape.circle),
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
      const Center(child: AppIconImage(AppIcons.pdf, size: 80)),
      const SizedBox(height: 12),
      Center(child: Text('no_lectures_in_course'.tr(),
          style: GoogleFonts.poppins(color: getSecondaryTextColor(context)))),
    ]);
  }

  Widget _lectureCard(dynamic l, int index) {
    final hasAI = l['has_ai']?.toString() == '1';
    final contentType = l['content_type']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: widget.color.withOpacity(0.15)),
        boxShadow: [BoxShadow(
            color: widget.color.withOpacity(0.08),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          // ⭐ دائماً يفتح LectureViewScreen
          onTap: () => _openLecture(l),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                widget.color.withOpacity(0.06),
                widget.color.withOpacity(0.02),
              ]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text("${index + 1}",
                      style: TextStyle(
                          color: widget.color, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l['title'] ?? '',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(children: [
                      AppIconImage(
                        contentType == 'audio' ? AppIcons.microchip : AppIcons.pdf,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(_typeLabel(contentType),
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: getSecondaryTextColor(context))),
                      const SizedBox(width: 10),
                      if (hasAI)
                        AppMiniBadge3D(
                            label: "AI ✓",
                            iconPath: AppIcons.microchip,
                            color: Colors.green)
                      else
                        AppMiniBadge3D(
                            label: 'preparing'.tr(),
                            iconPath: AppIcons.warning,
                            color: Colors.orange),
                    ]),
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.grey, size: 20),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'audio': return 'type_audio'.tr();
      case 'pdf':   return 'type_pdf'.tr();
      default:      return 'type_lecture'.tr();
    }
  }
}