import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';
import 'package:cluster_app/features/student/student_course_lectures_screen.dart';

class StudentCoursesScreen extends StatefulWidget {
  final String userId;
  final String studentId;
  const StudentCoursesScreen({
    super.key,
    required this.userId,
    required this.studentId,
  });

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
  bool _loading = true;
  List<dynamic> _courses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getStudentEnrolledCourses(widget.userId);
    if (mounted) setState(() { _courses = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('my_courses'.tr(),
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
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
          Text('no_courses_enrolled'.tr(),
              style: GoogleFonts.poppins(
                  color: getSecondaryTextColor(context))),
        ],
      ),
    );
  }

  Widget _buildCourseCard(dynamic c) {
    final color = _parseColor(c['cover_color']);
    final lectures = int.tryParse(c['lectures_count']?.toString() ?? '0') ?? 0;
    final ai       = int.tryParse(c['ai_count']?.toString() ?? '0') ?? 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentCourseLecturesScreen(
            courseId: c['id'].toString(),
            courseTitle: c['title'] ?? '',
            studentId: widget.studentId,
            color: color,
          ),
        ),
      ).then((_) => _load()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: getCardColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
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
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(Icons.menu_book_rounded, color: color, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(c['title'] ?? '',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _stat("$lectures", 'lectures'.tr(), color),
                  _stat("$ai", "AI ✓", Colors.green),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: GoogleFonts.poppins(fontSize: 10, color: getSecondaryTextColor(context))),
        ],
      ),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.primary;
    try { return Color(int.parse(hex.replaceFirst('#', '0xff'))); } catch (_) { return AppColors.primary; }
  }
}