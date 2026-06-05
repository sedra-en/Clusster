import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';
import 'package:cluster_app/features/instructor/upload_lecture_screen.dart';

class InstructorCoursesScreen extends StatefulWidget {
  final String instructorId;
  const InstructorCoursesScreen({super.key, required this.instructorId});

  @override
  State<InstructorCoursesScreen> createState() =>
      _InstructorCoursesScreenState();
}

class _InstructorCoursesScreenState extends State<InstructorCoursesScreen> {
  bool _isLoading = true;
  List<dynamic> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getInstructorCourses(widget.instructorId);
    setState(() {
      _courses = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("موادي الدراسية"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AppBackground(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    final course = _courses[index];
                    return _buildCourseCard(course);
                  },
                ),
      ),
    );
  }

  Widget _buildCourseCard(dynamic course) {
    final color = AppColors.primary;
    return ScaleButton(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => UploadLectureScreen(
                    courseId: course['id'].toString(),
                    courseTitle: course['title'],
                    color: color,
                  ),
            ),
          ),
      child: Container(
        decoration: BoxDecoration(
          color: getCardColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_rounded, color: color, size: 40),
            const SizedBox(height: 10),
            Text(
              course['title'],
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
