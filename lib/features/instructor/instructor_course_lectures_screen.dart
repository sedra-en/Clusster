import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';
import 'package:cluster_app/features/instructor/upload_lecture_screen.dart';
import 'package:cluster_app/features/instructor/instructor_lecture_ai_view_screen.dart';
import 'package:cluster_app/features/instructor/instructor_course_quiz_stats_screen.dart';

class InstructorCourseLecturesScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final Color color;

  const InstructorCourseLecturesScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.color,
  });

  @override
  State<InstructorCourseLecturesScreen> createState() =>
      _InstructorCourseLecturesScreenState();
}

class _InstructorCourseLecturesScreenState
    extends State<InstructorCourseLecturesScreen> {

  List<dynamic> _lectures = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data =
        await ApiService.getLectures(widget.courseId);
    if (mounted) {
      setState(() {
        _lectures = data;
        _loading = false;
      });
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
        builder: (_) =>
            InstructorCourseQuizStatsScreen(
          courseId: widget.courseId,
          courseTitle: widget.courseTitle,
          color: widget.color,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(dynamic l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('delete_lecture'.tr()),
        content: Text(
          'delete_lecture_confirm'
              .tr()
              .replaceAll('{title}', l['title'] ?? ''),
        ),
        actions: [
          TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: Text('cancel'.tr())),
          TextButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              child: Text('delete'.tr(),
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (ok != true) return;

    final res =
        await ApiService.deleteLecture(
            l['id'].toString());

    if (!mounted) return;

    if (res['status'] == 'success') {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text('deleted_successfully'
                  .tr()),
          backgroundColor:
              Colors.green,
        ),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(res['message'] ??
              'delete_failed'.tr()),
        ),
      );
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
              Expanded(
                child: _loading
                    ? const Center(
                        child:
                            CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: _lectures.isEmpty
                            ? _emptyState()
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(
                                        20,
                                        5,
                                        20,
                                        90),
                                itemCount:
                                    _lectures.length,
                                itemBuilder:
                                    (_, i) =>
                                        _lectureCard(
                                            _lectures[i]),
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        backgroundColor: widget.color,
        onPressed: _openUpload,
        icon: const Icon(Icons.add,
            color: Colors.white),
        label: Text(
            'upload_new_lecture'.tr(),

            style: GoogleFonts.poppins(
                color: Colors.white)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          20, 10, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [
              widget.color,
              widget.color
                  .withOpacity(0.7)
            ]),
        borderRadius:
            const BorderRadius.vertical(
                bottom:
                    Radius.circular(28)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                Navigator.pop(context),
            child: Container(
              padding:
                  const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white
                    .withOpacity(0.2),
                shape:
                    BoxShape.circle,
              ),
              child: const Icon(
                Icons
                    .arrow_back_ios_new_rounded,
                color:
                    Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text('lectures'.tr(),
                    style:
                        GoogleFonts.poppins(
                      color:
                          Colors.white,
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    )),
                Text(widget.courseTitle,
                    style: TextStyle(
                        color: Colors
                            .white
                            .withOpacity(
                                0.85),
                        fontSize: 12)),
              ],
            ),
          ),

          // ✅ GIF بدل أيقونة الإحصائيات
          GestureDetector(
            onTap: _openQuizStats,
            child: Container(
              padding:
                  const EdgeInsets.all(8),
              margin:
                  const EdgeInsets.only(
                      left: 6),
              decoration: BoxDecoration(
                color: Colors.white
                    .withOpacity(0.2),
                shape:
                    BoxShape.circle,
              ),
              child: Image.asset(
                "assets/icons/icons8-statistics.gif",
                width: 22,
                height: 22,
                fit: BoxFit.contain,
              ),
            ),
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white
                  .withOpacity(0.25),
              borderRadius:
                  BorderRadius.circular(
                      10),
            ),
            child: Text(
              "${_lectures.length}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight:
                    FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Icon(Icons.video_library_outlined,
            size: 80,
            color: getSecondaryTextColor(context)
                .withOpacity(0.3)),
        const SizedBox(height: 12),
        Center(
          child: Text('no_lectures_yet'.tr(),
              style: GoogleFonts.poppins(
                  color:
                      getSecondaryTextColor(
                          context))),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text('press_upload_lecture'
              .tr()),
        ),
      ],
    );
  }

 Widget _lectureCard(dynamic l) {
  final hasAI = l['has_ai']?.toString() == '1';

  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: getCardColor(context),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: widget.color.withOpacity(0.15),
      ),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InstructorLectureAIViewScreen(
                lectureId: l['id'].toString(),
                lectureTitle: l['title'] ?? '',
                color: widget.color,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(
                Icons.menu_book_rounded,
                size: 22,
              ),
              const SizedBox(width: 12),
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
        ),
      ),
    ),
  );
}
}