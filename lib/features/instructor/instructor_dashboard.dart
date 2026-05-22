import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';
import 'package:cluster_app/core/constants/app_icons.dart';
import 'package:cluster_app/features/instructor/instructor_courses_screen.dart';
import 'package:cluster_app/features/instructor/instructor_profile.dart';
import 'package:cluster_app/features/instructor/instructor_lecture_ai_view_screen.dart';
import 'package:cluster_app/features/auth/unified_login_screen.dart';
import 'package:cluster_app/features/settings/settings_screen.dart';

class InstructorDashboard extends StatefulWidget {
  final String userId;
  const InstructorDashboard({super.key, required this.userId});

  @override
  State<InstructorDashboard> createState() =>
      _InstructorDashboardState();
}

class _InstructorDashboardState
    extends State<InstructorDashboard> {

  Map<String, dynamic> _profile = {};
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final results = await Future.wait([
      ApiService.getInstructorProfile(widget.userId),
      ApiService.getInstructorStats(widget.userId),
    ]);

    if (!mounted) return;

    setState(() {
      _profile = results[0] as Map<String, dynamic>;
      _stats = results[1] as Map<String, dynamic>;
      _loading = false;
    });
  }

  String? get _instructorId =>
      _profile['instructor_id']?.toString();

  int _s(String k) =>
      int.tryParse(_stats[k]?.toString() ?? '0') ??
      0;

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
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildHeader(),
                        Padding(
                          padding:
                              const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              FadeInSlide(delay: 0.1, child: _buildWelcomeCard()),
                              const SizedBox(height: 20),
                              FadeInSlide(delay: 0.15, child: _buildStatsGrid()),
                              const SizedBox(height: 22),
                              FadeInSlide(delay: 0.2, child: _buildQuickActions()),
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

  // ✅ HEADER بعد التعديل (بدون glow + PNG profile)

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
      child: Row(
        children: [

          // ✅ Logo مكبر بدون animation
          Image.asset(
            'assets/images/logo.png',
            width: 90,
            fit: BoxFit.contain,
          ),

          const SizedBox(width: 20),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text('hello'.tr(),
                    style: GoogleFonts.poppins(
                        color: getSecondaryTextColor(context),
                        fontSize: 12)),
                Row(
                  children: [
                    AppIconImage(AppIcons.teacher, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _profile['full_name'] ?? '...',
                        style: GoogleFonts.poppins(
                            color: getTextColor(context),
                            fontSize: 17,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          _iconButton(
            imagePath: "assets/icons/icons8-profile-50.png",
            color: AppColors.primary,
            onTap: () {
              if (_instructorId == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      InstructorProfile(userId: widget.userId),
                ),
              ).then((_) => _load());
            },
          ),

          const SizedBox(width: 10),

          _iconButton(
            iconPath: AppIcons.settings,
            color: AppColors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SettingsScreen()),
              );
            },
          ),

          const SizedBox(width: 10),

          _iconButton(
            iconPath: AppIcons.logout,
            color: Colors.red,
            onTap: _confirmLogout,
          ),
        ],
      ),
    );
  }  // ============================================================
  // 🎨 زر أيقونة احترافي (محسن مثل الطالب)
  // ============================================================
  Widget _iconButton({
    String? imagePath,
    String? iconPath,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: imagePath != null
            ? Image.asset(imagePath, width: 26, height: 26)
            : AppIconImage(iconPath!, size: 26),
      ),
    );
  }

  // ============================================================
  // 🎨 Welcome Card (كما هو أصلي)
  // ============================================================
  Widget _buildWelcomeCard() {
    final coursesCount = _s('courses_count');
    final aiGen = _s('ai_generated_count');
    final lecturesCount = _s('lectures_count');

    final sub = lecturesCount == 0
        ? 'first_lecture_hint'.tr()
        : aiGen < lecturesCount
            ? 'lectures_need_ai'
                .tr()
                .replaceAll('{n}', '${lecturesCount - aiGen}')
            : 'all_lectures_summarized'.tr();

    return ProGlassCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text('instructor_impact_today'.tr(),
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            getTextColor(context))),
                const SizedBox(height: 4),
                Text(sub,
                    style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color:
                            getSecondaryTextColor(context))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    AppIconImage(
                        AppIcons.book,
                        size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'active_courses'
                          .tr()
                          .replaceAll(
                              '{n}',
                              '$coursesCount'),
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w600,
                          color:
                              AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.all(8),
            decoration:
                BoxDecoration(
              color: Colors.orangeAccent
                  .withOpacity(0.12),
              borderRadius:
                  BorderRadius.circular(
                      14),
            ),
            child: AppIconImage(
                AppIcons.microchip,
                size: 40),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🎨 Statistics Grid (كما هو)
  // ============================================================
  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.all(
                      4),
              decoration:
                  BoxDecoration(
                color: AppColors
                    .primary
                    .withOpacity(
                        0.1),
                borderRadius:
                    BorderRadius
                        .circular(8),
              ),
              child: AppIconImage(
                  AppIcons.business,
                  size: 22),
            ),
            const SizedBox(width: 8),
            Text('statistics'.tr(),
                style:
                    GoogleFonts.poppins(
                        fontSize: 15.5,
                        fontWeight:
                            FontWeight
                                .bold)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _statCard3D(
              value:
                  "${_s('courses_count')}",
              label:
                  'stat_courses'.tr(),
              iconPath:
                  AppIcons.book,
              color:
                  AppColors.primary,
            ),
            const SizedBox(width: 10),
            _statCard3D(
              value:
                  "${_s('lectures_count')}",
              label:
                  'stat_lectures'
                      .tr(),
              iconPath:
                  AppIcons.pdf,
              color:
                  AppColors.orange,
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // 🎨 Stat Card
  // ============================================================
  Widget _statCard3D({
    required String value,
    required String label,
    required String iconPath,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.all(
                14),
        decoration:
            BoxDecoration(
          gradient:
              LinearGradient(
            colors: [
              color
                  .withOpacity(
                      0.14),
              color
                  .withOpacity(
                      0.05),
            ],
          ),
          borderRadius:
              BorderRadius.circular(
                  16),
        ),
        child: Column(
          children: [
            AppIconImage(
                iconPath,
                size: 28),
            const SizedBox(
                height: 10),
            Text(value,
                style:
                    GoogleFonts
                        .poppins(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                  color: color,
                )),
            Text(label,
                style:
                    GoogleFonts
                        .poppins(
                  fontSize: 11,
                  color:
                      getSecondaryTextColor(
                          context),
                )),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🎨 Quick Actions (تصحيح الأخطاء فقط)
  // ============================================================
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            _actionCard3D(
              label: 'my_courses'.tr(),
              iconPath: AppIcons.book,
              color: AppColors.primary,
              onTap: () {
                if (_instructorId ==
                    null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        InstructorCoursesScreen(
                      instructorId:
                          _instructorId!,
                      userId:
                          widget.userId,
                    ),
                  ),
                ).then((_) => _load());
              },
            ),
            const SizedBox(width: 12),
            _actionCard3D(
              label: 'my_profile'.tr(),
              iconPath:
                  AppIcons.teacher,
              color:
                  AppColors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          InstructorProfile(
                              userId:
                                  widget
                                      .userId)),
                ).then((_) => _load());
              },
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // 🎨 Action Card
  // ============================================================
  Widget _actionCard3D({
    required String label,
    required String iconPath,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: ScaleButton(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.all(
                  20),
          decoration:
              BoxDecoration(
            color:
                getCardColor(context),
            borderRadius:
                BorderRadius.circular(
                    18),
            border: Border.all(
                color: color
                    .withOpacity(
                        0.3)),
          ),
          child: Column(
            children: [
              AppIconImage(
                  iconPath,
                  size: 38),
              const SizedBox(
                  height: 12),
              Text(label,
                  style:
                      GoogleFonts
                          .poppins(
                    fontWeight:
                        FontWeight
                            .bold,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 🎨 Recent Lectures (كما هو)
  // ============================================================
  Widget _buildRecentLectures() {
    final List recent =
        _stats['recent_lectures'] ??
            [];
    if (recent.isEmpty)
      return const SizedBox.shrink();

    return Column(
      children:
          recent.map((l) {
        return _lectureRow(l);
      }).toList(),
    );
  }

  // ============================================================
  // 🎨 Lecture Row
  // ============================================================
  Widget _lectureRow(dynamic l) {
    final color =
        _parseColor(
            l['cover_color']);
    final hasAI =
        l['has_ai']?.toString() ==
            '1';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                InstructorLectureAIViewScreen(
              lectureId:
                  l['id']
                      .toString(),
              lectureTitle:
                  l['title'] ??
                      '',
              color: color,
            ),
          ),
        );
      },
      child: Padding(
        padding:
            const EdgeInsets
                .symmetric(
                    vertical:
                        8),
        child: Row(
          children: [
            AppIconImage(
              hasAI
                  ? AppIcons
                      .microchip
                  : AppIcons.pdf,
              size: 22,
            ),
            const SizedBox(
                width: 12),
            Expanded(
              child: Text(
                l['title'] ??
                    '',
                style:
                    GoogleFonts
                        .poppins(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(
      String? hex) {
    if (hex == null ||
        hex.isEmpty)
      return AppColors.primary;
    try {
      return Color(int.parse(
          hex.replaceFirst(
              '#', '0xff')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  // ============================================================
  // ✅ Logout
  // ============================================================
  void _confirmLogout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (_) =>
              const UnifiedLoginScreen()),
      (route) => false,
    );
  }
}