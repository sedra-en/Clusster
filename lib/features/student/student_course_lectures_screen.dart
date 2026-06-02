// ============================================================
// lib/features/student/student_course_lectures_screen.dart
// تبويبان: المحاضرات (PDF فقط) + الملخصات
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';
import 'package:cluster_app/core/api/chat_api.dart';
import 'package:cluster_app/core/constants/app_icons.dart';
import 'package:cluster_app/features/student/student_lecture_ai_screen.dart';
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
    extends State<StudentCourseLecturesScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _lectures = [];
  bool _loading = true;
  int _unreadCount = 0;
  Timer? _unreadTimer;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
    _loadUnreadCount();
    _unreadTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadUnreadCount();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      final count =
          perCourse[courseIdInt.toString()] ?? perCourse[courseIdInt] ?? 0;
      if (mounted) {
        setState(() {
          _unreadCount =
              (count is int) ? count : int.tryParse(count.toString()) ?? 0;
        });
      }
    } catch (_) {}
  }

  void _openChat() {
    final userIdInt = int.tryParse(widget.userId ?? '0') ?? 0;
    final courseIdInt = int.tryParse(widget.courseId) ?? 0;
    if (userIdInt == 0 || courseIdInt == 0) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => CourseChatScreen(
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

  Future<void> _openPdf(String filePath) async {
    final url = '${ApiService.baseUrl}/uploads/$filePath';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('cannot_open_file'.tr())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              // ─── Tab Bar ───────────────────────────
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
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.menu_book_rounded, size: 18),
                      text: 'lectures'.tr(),
                    ),
                    Tab(
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      text: 'summaries'.tr(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : TabBarView(
                          controller: _tabController,
                          children: [_lecturesTab(), _summariesTab()],
                        ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildChatFAB(),
    );
  }

  // ─── تبويب المحاضرات (PDF فقط) ──────────────────────────
  Widget _lecturesTab() {
    final pdfLectures =
        _lectures.where((l) {
          final fp = l['file_path']?.toString() ?? '';
          final ct = l['content_type']?.toString() ?? '';
          return fp.isNotEmpty && ct != 'audio';
        }).toList();

    if (pdfLectures.isEmpty) {
      return _emptyState('no_lectures_in_course'.tr(), AppIcons.pdf);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
        itemCount: pdfLectures.length,
        itemBuilder: (_, i) => _lectureCard(pdfLectures[i], i),
      ),
    );
  }

  Widget _lectureCard(dynamic l, int index) {
    final filePath = l['file_path']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: widget.color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: widget.color.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: filePath.isNotEmpty ? () => _openPdf(filePath) : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l['title'] ?? '',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.picture_as_pdf_rounded,
                            size: 14,
                            color: Colors.red.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'type_pdf'.tr(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: getSecondaryTextColor(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.open_in_new_rounded, color: widget.color, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── تبويب الملخصات ──────────────────────────────────────
  Widget _summariesTab() {
    final aiLectures =
        _lectures.where((l) {
          return l['has_ai']?.toString() == '1';
        }).toList();

    if (aiLectures.isEmpty) {
      return _emptyState('no_summaries_yet'.tr(), AppIcons.microchip);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
        itemCount: aiLectures.length,
        itemBuilder: (_, i) => _summaryCard(aiLectures[i], i),
      ),
    );
  }

  Widget _summaryCard(dynamic l, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => StudentLectureAIScreen(
                        lectureId: l['id'].toString(),
                        lectureTitle: l['title'] ?? '',
                        studentId: widget.studentId,
                        color: widget.color,
                      ),
                ),
              ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.green,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l['title'] ?? '',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                              ),
                            ),
                            child: const Text(
                              'AI ✓',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'tap_to_view_summary'.tr(),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: getSecondaryTextColor(context),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────
  Widget _emptyState(String text, String icon) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(child: AppIconImage(icon, size: 70)),
        const SizedBox(height: 12),
        Center(
          child: Text(
            text,
            style: GoogleFonts.poppins(color: getSecondaryTextColor(context)),
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
                color: Colors.white.withOpacity(0.25),
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
                  'lectures'.tr(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.courseTitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_lectures.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
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
          icon: Image.asset(
            'assets/icons/icons8-message.gif',
            width: 24,
            height: 24,
          ),
          label: Text(
            'course_chat'.tr(),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
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
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
