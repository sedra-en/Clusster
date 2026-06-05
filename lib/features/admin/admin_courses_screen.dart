import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';
import 'package:cluster_app/core/constants/app_icons.dart';
import 'package:cluster_app/features/admin/admin_create_course_screen.dart';
import 'package:cluster_app/features/admin/admin_course_management_screen.dart';

class AdminCoursesScreen extends StatefulWidget {
  const AdminCoursesScreen({super.key});
  @override
  State<AdminCoursesScreen> createState() => _AdminCoursesScreenState();
}

class _AdminCoursesScreenState extends State<AdminCoursesScreen> {
  List<dynamic> _courses = [];
  List<dynamic> _semesters = [];
  bool _loading = true;
  String _semesterFilter = 'active';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.getSemesters(),
      ApiService.getAdminCourses(semesterId: _semesterFilter),
    ]);
    if (mounted) {
      setState(() {
        _semesters = results[0];
        _courses = results[1];
        _loading = false;
      });
    }
  }

  Future<void> _reloadCourses() async {
    setState(() => _loading = true);
    final c = await ApiService.getAdminCourses(semesterId: _semesterFilter);
    if (mounted)
      setState(() {
        _courses = c;
        _loading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIconImage(AppIcons.book, size: 24),
            const SizedBox(width: 8),
            Text(
              'manage_courses'.tr(),
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildSemesterFilter(),
              Expanded(
                child:
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                          onRefresh: _reloadCourses,
                          child:
                              _courses.isEmpty
                                  ? _emptyState()
                                  : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      5,
                                      20,
                                      90,
                                    ),
                                    itemCount: _courses.length,
                                    itemBuilder:
                                        (_, i) => _courseCard(_courses[i]),
                                  ),
                        ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        elevation: 6,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminCreateCourseScreen()),
          );
          _reloadCourses();
        },
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'new_course'.tr(),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSemesterFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _filterChip('active', 'current_semester'.tr(), AppIcons.event),
          _filterChip('all', 'all_semesters'.tr(), AppIcons.dashboard),
          ..._semesters.map(
            (s) => _filterChip(
              s['id'].toString(),
              s['name'] ?? '',
              AppIcons.event,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label, String iconPath) {
    final selected = _semesterFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => _semesterFilter = value);
          _reloadCourses();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                selected
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withOpacity(selected ? 1 : 0.2),
            ),
            boxShadow:
                selected
                    ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : [],
          ),
          child: Row(
            children: [
              AppIconImage(iconPath, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: selected ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Center(
          child: Opacity(
            opacity: 0.5,
            child: AppIconImage(AppIcons.book, size: 90),
          ),
        ),
        const SizedBox(height: 15),
        Center(
          child: Text(
            'no_courses_in_semester'.tr(),
            style: GoogleFonts.poppins(color: getSecondaryTextColor(context)),
          ),
        ),
      ],
    );
  }

  Widget _courseCard(dynamic c) {
    final color = _parseColor(c['cover_color']);
    final status = (c['status'] ?? 'draft').toString();
    final (statusColor, statusLabel) = _statusInfo(status);
    final enrollments =
        int.tryParse(c['enrollments_count']?.toString() ?? '0') ?? 0;
    final lectures = int.tryParse(c['lectures_count']?.toString() ?? '0') ?? 0;
    final instructor = c['instructor_name']?.toString();
    final semesterName = c['semester_name']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminCourseManagementScreen(course: c),
              ),
            );
            _reloadCourses();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // أيقونة الكتاب 3D بـ gradient
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color.withOpacity(0.2), color.withOpacity(0.08)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Center(child: AppIconImage(AppIcons.book, size: 36)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c['title'] ?? '',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // اسم الدكتور بأيقونة teacher
                      Row(
                        children: [
                          AppIconImage(AppIcons.teacher, size: 13),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              instructor ?? 'no_instructor'.tr(),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color:
                                    instructor != null
                                        ? AppColors.purple
                                        : Colors.orange,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (semesterName != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            AppIconImage(AppIcons.event, size: 12),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                semesterName,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: getSecondaryTextColor(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Badges
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          AppMiniBadge3D(
                            label: "$enrollments ${'students'.tr()}",
                            iconPath: AppIcons.community,
                            color: color,
                          ),
                          AppMiniBadge3D(
                            label: "$lectures ${'lectures'.tr()}",
                            iconPath: AppIcons.pdf,
                            color: color,
                          ),
                          _statusBadge(status, statusColor, statusLabel),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status, Color color, String label) {
    String iconPath;
    if (status == 'published') {
      iconPath = AppIcons.checkMark;
    } else if (status == 'draft') {
      iconPath = AppIcons.warning;
    } else {
      iconPath = AppIcons.delete;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconImage(iconPath, size: 11),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  (Color, String) _statusInfo(String status) {
    switch (status) {
      case 'published':
        return (Colors.green, 'published'.tr());
      case 'draft':
        return (Colors.orange, 'draft'.tr());
      case 'hidden':
        return (Colors.grey, 'hidden'.tr());
      default:
        return (Colors.grey, status);
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
