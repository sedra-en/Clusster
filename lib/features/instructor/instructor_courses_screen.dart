import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';
import 'package:cluster_app/features/instructor/instructor_course_lectures_screen.dart';
import 'package:cluster_app/features/instructor/instructor_course_students_screen.dart';

class InstructorCoursesScreen extends StatefulWidget {
  final String instructorId;
  final String userId;
  const InstructorCoursesScreen({
    super.key,
    required this.instructorId,
    required this.userId,
  });

  @override
  State<InstructorCoursesScreen> createState() => _InstructorCoursesScreenState();
}

class _InstructorCoursesScreenState extends State<InstructorCoursesScreen> {
  bool _loading = true;
  List<dynamic> _courses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getInstructorCoursesByUser(widget.userId);
    if (mounted) setState(() { _courses = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('my_subjects'.tr(),
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _courses.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
                        itemCount: _courses.length,
                        itemBuilder: (_, i) => _buildCourseCard(_courses[i]),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_outlined,
              size: 80, color: getSecondaryTextColor(context).withOpacity(0.3)),
          const SizedBox(height: 12),
          Text('no_courses_assigned'.tr(),
              style: GoogleFonts.poppins(
                  color: getSecondaryTextColor(context))),
          const SizedBox(height: 4),
          Text('contact_admin_for_courses'.tr(),
              style: GoogleFonts.poppins(
                  fontSize: 11, color: getSecondaryTextColor(context))),
        ],
      ),
    );
  }

  Widget _buildCourseCard(dynamic c) {
    final color = _parseColor(c['cover_color']);
    final lectures = int.tryParse(c['lectures_count']?.toString() ?? '0') ?? 0;
    final students = int.tryParse(c['students_count']?.toString() ?? '0') ?? 0;
    final ai       = int.tryParse(c['ai_count']?.toString() ?? '0') ?? 0;
    final semester = c['semester_name']?.toString();
    final status   = c['status']?.toString() ?? 'draft';
    final (statusColor, statusLabel) = _statusInfo(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.18), color.withOpacity(0.05)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(Icons.menu_book_rounded, color: color, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['title'] ?? '',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      if (semester != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(semester,
                              style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  color: getSecondaryTextColor(context))),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                _stat("$lectures", 'stat_lectures'.tr(), color),
                _stat("$students", 'stat_students'.tr(), AppColors.primary),
                _stat("$ai", 'ai_done'.tr(), Colors.green),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _btn(
                    'btn_lectures'.tr(),
                    Icons.video_library_rounded,
                    color,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InstructorCourseLecturesScreen(
                          courseId: c['id'].toString(),
                          courseTitle: c['title'] ?? '',
                          color: color,
                        ),
                      ),
                    ).then((_) => _load()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _btn(
                    'btn_students'.tr(),
                    Icons.groups_rounded,
                    AppColors.primary,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InstructorCourseStudentsScreen(
                          courseId: c['id'].toString(),
                          courseTitle: c['title'] ?? '',
                          color: color,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10, color: getSecondaryTextColor(context))),
        ],
      ),
    );
  }

  Widget _btn(String label, IconData icon, Color color, VoidCallback onTap) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  (Color, String) _statusInfo(String s) {
    switch (s) {
      case 'published': return (Colors.green, 'published'.tr());
      case 'draft':     return (Colors.orange, 'draft'.tr());
      case 'hidden':    return (Colors.grey, 'hidden'.tr());
      default: return (Colors.grey, s);
    }
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.primary;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xff')));
    } catch (_) {
      return AppColors.primary;
    }
  }
}