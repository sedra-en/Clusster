import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';
import 'package:cluster_app/core/constants/app_icons.dart';
import 'package:cluster_app/features/student/student_lecture_ai_screen.dart';

class StudentCourseLecturesScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final String studentId;
  final Color color;

  const StudentCourseLecturesScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.studentId,
    required this.color,
  });

  @override
  State<StudentCourseLecturesScreen> createState() =>
      _StudentCourseLecturesScreenState();
}

class _StudentCourseLecturesScreenState
    extends State<StudentCourseLecturesScreen> {
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
    if (mounted) {
      setState(() {
        _lectures = data;
        _loading = false;
      });
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
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: _lectures.isEmpty
                            ? _emptyState()
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 12, 20, 30),
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
          colors: [widget.color, widget.color.withOpacity(0.7)],
        ),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(28)),
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
              child: const AppIconImage(
                AppIcons.dashboard,
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
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "${_lectures.length}",
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

  Widget _emptyState() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        const Center(
          child: AppIconImage(
            AppIcons.pdf,
            size: 80,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'no_lectures_in_course'.tr(),
            style: GoogleFonts.poppins(
              color: getSecondaryTextColor(context),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'instructor_will_upload_soon'.tr(),
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: getSecondaryTextColor(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _lectureCard(dynamic l, int index) {
    final hasAI = l['has_ai']?.toString() == '1';
    final contentType = l['content_type']?.toString() ?? '';

    String typeIcon;

    switch (contentType) {
      case 'audio':
        typeIcon = AppIcons.microchip;
        break;
      case 'image':
        typeIcon = AppIcons.education;
        break;
      case 'video':
        typeIcon = AppIcons.business;
        break;
      default:
        typeIcon = AppIcons.pdf;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: widget.color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: widget.color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
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
                    SnackBar(
                      content:
                          Text('ai_content_not_ready_yet'.tr()),
                    ),
                  );
                },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.color.withOpacity(0.06),
                  widget.color.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${index + 1}",
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
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
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
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            AppIconImage(typeIcon, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              _typeLabel(contentType),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: getSecondaryTextColor(
                                    context),
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (hasAI)
                              AppMiniBadge3D(
                                label: "AI ✓",
                                iconPath: AppIcons.microchip,
                                color: Colors.green,
                              )
                            else
                              AppMiniBadge3D(
                                label: 'preparing'.tr(),
                                iconPath: AppIcons.warning,
                                color: Colors.orange,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppIconImage(
                    hasAI
                        ? AppIcons.dashboard
                        : AppIcons.warning,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'audio':
        return 'type_audio'.tr();
      case 'image':
        return 'type_image'.tr();
      case 'video':
        return 'type_video'.tr();
      case 'pdf':
        return 'type_pdf'.tr();
      default:
        return 'type_lecture'.tr();
    }
  }
}