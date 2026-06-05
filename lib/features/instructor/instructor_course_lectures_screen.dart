import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';
import 'package:cluster_app/core/api/chat_api.dart';
import 'package:cluster_app/features/instructor/upload_lecture_screen.dart';
import 'package:cluster_app/features/instructor/instructor_lecture_ai_view_screen.dart';
import 'package:cluster_app/features/instructor/instructor_course_quiz_stats_screen.dart';
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
    extends State<InstructorCourseLecturesScreen>
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

  Future<void> _openUpload() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => UploadLectureScreen(
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
        builder:
            (_) => InstructorCourseQuizStatsScreen(
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
    if (userIdInt == 0 || courseIdInt == 0) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => CourseChatScreen(
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

  Future<void> _openFile(String path) async {
    final url = '${ApiService.baseUrl}/uploads/$path';
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

  Future<void> _confirmDelete(dynamic l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('delete_lecture'.tr()),
            content: Text(
              'delete_lecture_confirm'.tr().replaceAll(
                '{title}',
                l['title'] ?? '',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('cancel'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'delete'.tr(),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (ok != true) return;
    final res = await ApiService.deleteLecture(l['id'].toString());
    if (!mounted) return;
    if (res['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('deleted_successfully'.tr()),
          backgroundColor: Colors.green,
        ),
      );
      _load();
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
      floatingActionButton: _buildFABs(),
    );
  }

  Widget _lecturesTab() {
    if (_lectures.isEmpty) {
      return _emptyState('no_lectures_yet'.tr());
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 90),
        itemCount: _lectures.length,
        itemBuilder: (_, i) => _lectureCard(_lectures[i]),
      ),
    );
  }

  Widget _lectureCard(dynamic l) {
    final filePath = l['file_path']?.toString() ?? '';
    final audioPath = l['audio_path']?.toString() ?? '';
    final contentType = l['content_type']?.toString() ?? 'pdf';
    final hasAI = l['has_ai']?.toString() == '1';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.color.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book_rounded, size: 20, color: widget.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l['title'] ?? '',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasAI)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
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
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: () => _confirmDelete(l),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                if (filePath.isNotEmpty && contentType != 'audio')
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openFile(filePath),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                      label: Text(
                        'open_pdf'.tr(),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),

                if (filePath.isNotEmpty &&
                    contentType != 'audio' &&
                    audioPath.isNotEmpty)
                  const SizedBox(width: 8),

                if (audioPath.isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openFile(audioPath),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.purple,
                        side: const BorderSide(color: Colors.purple),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.audiotrack_rounded, size: 16),
                      label: Text(
                        'play_audio'.tr(),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summariesTab() {
    if (_lectures.isEmpty) {
      return _emptyState('no_lectures_yet'.tr());
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 90),
        itemCount: _lectures.length,
        itemBuilder: (_, i) => _summaryCard(_lectures[i]),
      ),
    );
  }

  Widget _summaryCard(dynamic l) {
    final hasAI = l['has_ai']?.toString() == '1';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color:
              hasAI
                  ? Colors.green.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => InstructorLectureAIViewScreen(
                        lectureId: l['id'].toString(),
                        lectureTitle: l['title'] ?? '',
                        color: widget.color,
                      ),
                ),
              ).then((_) => _load()),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color:
                        hasAI
                            ? Colors.green.withOpacity(0.12)
                            : Colors.orange.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hasAI
                        ? Icons.auto_awesome_rounded
                        : Icons.hourglass_top_rounded,
                    color: hasAI ? Colors.green : Colors.orange,
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
                      Text(
                        hasAI ? 'ai_ready'.tr() : 'ai_pending'.tr(),
                        style: TextStyle(
                          fontSize: 11,
                          color: hasAI ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
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

  Widget _emptyState(String text) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Icon(
          Icons.video_library_outlined,
          size: 80,
          color: getSecondaryTextColor(context).withOpacity(0.3),
        ),
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
          GestureDetector(
            onTap: _openQuizStats,
            child: Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/icons/icons8-statistics.gif',
                width: 22,
                height: 22,
              ),
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

  Widget _buildFABs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            FloatingActionButton(
              heroTag: 'chat_btn',
              onPressed: _openChat,
              backgroundColor: Colors.white,
              elevation: 6,
              child: Image.asset(
                'assets/icons/icons8-message.gif',
                width: 32,
                height: 32,
              ),
            ),
            if (_unreadCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 22,
                    minHeight: 22,
                  ),
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
        ),
        const SizedBox(width: 12),
        FloatingActionButton.extended(
          heroTag: 'upload_btn',
          backgroundColor: widget.color,
          onPressed: _openUpload,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            'upload_new_lecture'.tr(),
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
