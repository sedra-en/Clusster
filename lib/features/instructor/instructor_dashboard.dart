import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cluster_app/core/app_keys.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';
import 'package:cluster_app/core/constants/app_icons.dart';
import 'package:cluster_app/core/services/chat_notification_service.dart';
import 'package:cluster_app/features/instructor/instructor_courses_screen.dart';
import 'package:cluster_app/features/instructor/instructor_profile.dart';
import 'package:cluster_app/features/instructor/instructor_lecture_ai_view_screen.dart';
import 'package:cluster_app/features/auth/unified_login_screen.dart';
import 'package:cluster_app/features/settings/settings_screen.dart';

class InstructorDashboard extends StatefulWidget {
  final String userId;
  const InstructorDashboard({super.key, required this.userId});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  Map<String, dynamic> _profile = {};
  Map<String, dynamic> _stats   = {};
  bool _loading = true;

  // ⭐ منع تشغيل الإشعارات أكثر من مرة
  bool _notificationsStarted = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
    _load();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.getInstructorProfile(widget.userId),
      ApiService.getInstructorStats(widget.userId),
    ]);
    if (mounted) {
      setState(() {
        _profile = results[0];
        _stats   = results[1];
        _loading = false;
      });

      // ⭐ يبدأ مرة واحدة فقط
      _startNotifications();
    }
  }

  void _startNotifications() {
    // ⭐ لو بدأت قبل كذا → لا تعيد
    if (_notificationsStarted) return;
    _notificationsStarted = true;

    ChatNotificationService.start(
      userId:       widget.userId,
      userName:     _profile['full_name']?.toString() ?? 'Instructor',
      userRole:     'instructor',
      navigatorKey: appNavigatorKey,
    );
  }

  String? get _instructorId => _profile['instructor_id']?.toString();
  int _s(String k) => int.tryParse(_stats[k]?.toString() ?? '0') ?? 0;

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
                              FadeInSlide(delay: 0.1,  child: _buildWelcomeCard()),
                              const SizedBox(height: 20),
                              FadeInSlide(delay: 0.15, child: _buildStatsGrid()),
                              const SizedBox(height: 22),
                              FadeInSlide(delay: 0.2,  child: _buildQuickActions()),
                              const SizedBox(height: 22),
                              FadeInSlide(delay: 0.25, child: _buildRecentLectures()),
                              const SizedBox(height: 30),
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
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) => Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                boxShadow: [BoxShadow(
                  color: const Color(0xFF6C63FF)
                      .withOpacity(_glowAnimation.value * 0.5),
                  blurRadius: 20, spreadRadius: 2,
                )],
              ),
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('hello'.tr(),
                    style: GoogleFonts.poppins(
                        color: getSecondaryTextColor(context), fontSize: 12)),
                Row(children: [
                  AppIconImage(AppIcons.teacher, size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(_profile['full_name'] ?? '...',
                        style: GoogleFonts.poppins(
                            color: getTextColor(context),
                            fontSize: 17,
                            fontWeight: FontWeight.bold),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ],
            ),
          ),
          _iconButton3D(
            iconPath: AppIcons.profile,
            bgColor: AppColors.primary,
            onTap: () {
              if (_instructorId == null) return;
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => InstructorProfile(userId: widget.userId),
              )).then((_) => _load());
            },
          ),
          const SizedBox(width: 8),
          _iconButton3D(
            iconPath: AppIcons.settings,
            bgColor: AppColors.purple,
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          const SizedBox(width: 8),
          _iconButton3D(
            iconPath: AppIcons.logout,
            bgColor: Colors.red,
            onTap: _confirmLogout,
          ),
        ],
      ),
    );
  }

  Widget _iconButton3D({
    required String iconPath,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: bgColor.withOpacity(0.3)),
          boxShadow: [BoxShadow(
              color: bgColor.withOpacity(0.15),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: AppIconImage(iconPath, size: 26),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final coursesCount  = _s('courses_count');
    final aiGen         = _s('ai_generated_count');
    final lecturesCount = _s('lectures_count');

    final sub = lecturesCount == 0
        ? 'first_lecture_hint'.tr()
        : aiGen < lecturesCount
            ? 'lectures_need_ai'.tr().replaceAll('{n}', '${lecturesCount - aiGen}')
            : 'all_lectures_summarized'.tr();

    return ProGlassCard(
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('instructor_impact_today'.tr(),
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.bold,
                      color: getTextColor(context))),
              const SizedBox(height: 4),
              Text(sub, style: GoogleFonts.poppins(
                  fontSize: 11.5, color: getSecondaryTextColor(context))),
              const SizedBox(height: 6),
              Row(children: [
                AppIconImage(AppIcons.book, size: 14),
                const SizedBox(width: 4),
                Text('active_courses'.tr().replaceAll('{n}', '$coursesCount'),
                    style: GoogleFonts.poppins(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
              ]),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14)),
          child: AppIconImage(AppIcons.microchip, size: 40),
        ),
      ]),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: AppIconImage(AppIcons.business, size: 22),
          ),
          const SizedBox(width: 8),
          Text('statistics'.tr(),
              style: GoogleFonts.poppins(
                  fontSize: 15.5, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _statCard3D(value: "${_s('courses_count')}",   label: 'stat_courses'.tr(),
              iconPath: AppIcons.book,      color: AppColors.primary),
          const SizedBox(width: 10),
          _statCard3D(value: "${_s('lectures_count')}",  label: 'stat_lectures'.tr(),
              iconPath: AppIcons.pdf,       color: AppColors.orange),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _statCard3D(value: "${_s('unique_students')}", label: 'stat_students'.tr(),
              iconPath: AppIcons.community, color: AppColors.purple),
          const SizedBox(width: 10),
          _statCard3D(value: "${_s('ai_generated_count')}", label: 'stat_ai_content'.tr(),
              iconPath: AppIcons.microchip, color: Colors.green),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _statCard3D(value: "${_s('quiz_attempts')}",   label: 'stat_quiz_attempts_label'.tr(),
              iconPath: AppIcons.checkMark, color: Colors.teal),
          const SizedBox(width: 10),
          _statCard3D(value: "${_s('published_courses')}", label: 'stat_published_courses'.tr(),
              iconPath: AppIcons.dashboard, color: AppColors.darkBlue),
        ]),
      ],
    );
  }

  Widget _statCard3D({
    required String value, required String label,
    required String iconPath, required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [color.withOpacity(0.14), color.withOpacity(0.05)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25), width: 1.2),
          boxShadow: [BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10)),
            child: AppIconImage(iconPath, size: 28),
          ),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.poppins(
              fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w500,
              color: getSecondaryTextColor(context))),
        ]),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: AppIconImage(AppIcons.dashboard, size: 22),
        ),
        const SizedBox(width: 8),
        Text('quick_access'.tr(),
            style: GoogleFonts.poppins(
                fontSize: 15.5, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        _actionCard3D(
          label: 'my_courses'.tr(),
          iconPath: AppIcons.book,
          color: AppColors.primary,
          onTap: () {
            if (_instructorId == null) return;
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => InstructorCoursesScreen(
                instructorId: _instructorId!,
                userId: widget.userId,
              ),
            )).then((_) => _load());
          },
        ),
        const SizedBox(width: 12),
        _actionCard3D(
          label: 'my_profile'.tr(),
          iconPath: AppIcons.teacher,
          color: AppColors.purple,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => InstructorProfile(userId: widget.userId),
            )).then((_) => _load());
          },
        ),
      ]),
    ]);
  }

  Widget _actionCard3D({
    required String label, required String iconPath,
    required Color color, required VoidCallback onTap,
  }) {
    return Expanded(
      child: ScaleButton(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.3), width: 1.2),
            boxShadow: [BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14)),
              child: AppIconImage(iconPath, size: 38),
            ),
            const SizedBox(height: 12),
            Text(label, style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, fontSize: 13,
                color: getTextColor(context))),
          ]),
        ),
      ),
    );
  }

  Widget _buildRecentLectures() {
    final List recent = _stats['recent_lectures'] ?? [];
    if (recent.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: AppIconImage(AppIcons.pdf, size: 22),
          ),
          const SizedBox(width: 8),
          Text('recent_lectures'.tr(),
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 14),
        ...recent.map((l) => _lectureRow(l)),
      ]),
    );
  }

  Widget _lectureRow(dynamic l) {
    final color = _parseColor(l['cover_color']);
    final hasAI = l['has_ai']?.toString() == '1';

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => InstructorLectureAIViewScreen(
            lectureId:    l['id'].toString(),
            lectureTitle: l['title'] ?? '',
            color:        color,
          ),
        ));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [color.withOpacity(0.18), color.withOpacity(0.08)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppIconImage(hasAI ? AppIcons.microchip : AppIcons.pdf, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l['title'] ?? '',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(children: [
                AppIconImage(AppIcons.book, size: 11),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(l['course_title'] ?? '',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: getSecondaryTextColor(context)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ]),
            ]),
          ),
          if (hasAI)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                AppIconImage(AppIcons.checkMark, size: 11),
                const SizedBox(width: 3),
                Text('ai_done'.tr(),
                    style: const TextStyle(
                        color: Colors.green,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 12, color: Colors.grey),
        ]),
      ),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.primary;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xff')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          AppIconImage(AppIcons.logout, size: 28),
          const SizedBox(width: 8),
          Text('logout'.tr(),
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        ]),
        content: Text('logout_confirm'.tr(),
            style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr())),
          TextButton(
            onPressed: () {
              ChatNotificationService.stop();
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const UnifiedLoginScreen()),
                (route) => false,
              );
            },
            child: Text('logout'.tr(),
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}