import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cluster_app/core/app_keys.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';
import 'package:cluster_app/core/constants/app_icons.dart';
import 'package:cluster_app/core/services/chat_notification_service.dart';
import 'package:cluster_app/features/student/student_profile.dart';
import 'package:cluster_app/features/student/student_course_lectures_screen.dart';
import 'package:cluster_app/features/auth/unified_login_screen.dart';
import 'package:cluster_app/features/settings/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userId;
  const DashboardScreen({super.key, required this.userId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _profile = {};
  List<dynamic> _courses = [];
  bool _loading = true;

  // ⭐ منع تشغيل الإشعارات أكثر من مرة
  bool _notificationsStarted = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await ApiService.getStudentProfile(widget.userId);
      final courses = await ApiService.getStudentEnrolledCourses(widget.userId);

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _courses = courses;
        _loading = false;
      });

      // ⭐ يبدأ مرة واحدة فقط
      _startNotifications();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _startNotifications() {
    // ⭐ لو بدأت قبل كذا → لا تعيد
    if (_notificationsStarted) return;
    _notificationsStarted = true;

    ChatNotificationService.start(
      userId: widget.userId,
      userName: _userName,
      userRole: 'student',
      navigatorKey: appNavigatorKey,
    );
  }

  String? get _studentId => _profile['student_id']?.toString();
  String get _userName   => _profile['full_name']?.toString() ?? 'Student';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildHeader(),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _buildStatsRow(),
                              const SizedBox(height: 25),
                              _buildMyCoursesSection(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset('assets/images/logo.png', width: 90, fit: BoxFit.contain),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              _profile['full_name'] ?? '',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          _iconButton(
            imagePath: "assets/icons/icons8-profile-50.png",
            color: AppColors.primary,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => StudentProfileScreen(userId: widget.userId)));
            },
          ),
          const SizedBox(width: 12),
          _iconButton(
            iconPath: AppIcons.settings,
            color: AppColors.purple,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const SettingsScreen()));
            },
          ),
          const SizedBox(width: 12),
          _iconButton(
            iconPath: AppIcons.logout,
            color: Colors.red,
            onTap: _confirmLogout,
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    String? imagePath,
    String? iconPath,
    required Color color,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: _HoverPressEffect(
        onTap: onTap,
        color: color,
        child: imagePath != null
            ? Image.asset(imagePath, width: 26, height: 26)
            : AppIconImage(iconPath!, size: 26),
      ),
    );
  }

  Widget _buildStatsRow() {
    final enrolled = int.tryParse(_profile['enrolled_count']?.toString() ?? '0') ?? 0;
    final attempts = int.tryParse(_profile['quiz_attempts_count']?.toString() ?? '0') ?? 0;

    return Row(
      children: [
        Expanded(child: _statCard(enrolled.toString(), 'my_courses'.tr(), AppColors.primary)),
        const SizedBox(width: 15),
        Expanded(child: _statCard(attempts.toString(), 'quizzes'.tr(), AppColors.orange)),
      ],
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.poppins(
              fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.poppins(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMyCoursesSection() {
    if (_courses.isEmpty) {
      return Center(child: Text('no_courses_enrolled'.tr()));
    }

    return Column(
      children: _courses.take(3).map((c) {
        return _HoverPressEffect(
          color: AppColors.primary,
          onTap: () {
            if (_studentId == null) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentCourseLecturesScreen(
                  courseId:    c['id'].toString(),
                  courseTitle: c['title'],
                  studentId:   _studentId!,
                  color:       AppColors.primary,
                  userId:      widget.userId,
                  userName:    _userName,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                AppIconImage(AppIcons.book, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(c['title'],
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _confirmLogout() {
    ChatNotificationService.stop();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
      (route) => false,
    );
  }
}

class _HoverPressEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color color;

  const _HoverPressEffect({
    required this.child,
    required this.onTap,
    required this.color,
  });

  @override
  State<_HoverPressEffect> createState() => _HoverPressEffectState();
}

class _HoverPressEffectState extends State<_HoverPressEffect> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown:  (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(_hovered ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}