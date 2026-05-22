import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';
import 'package:cluster_app/models/app_user.dart';
import 'package:cluster_app/features/admin/admin_users_screen.dart';
import 'package:cluster_app/features/admin/admin_create_user_screen.dart';
import 'package:cluster_app/features/admin/admin_courses_screen.dart';
import 'package:cluster_app/features/admin/admin_semesters_screen.dart';
import 'package:cluster_app/features/settings/settings_screen.dart';
import 'package:cluster_app/features/auth/unified_login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
    _loadStats();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final stats = await ApiService.getAdminStats();
    if (mounted) setState(() { _stats = stats; _loading = false; });
  }

  int _u(String k) => (_stats['users']?[k] ?? 0) as int;
  int _c(String k) => (_stats['courses']?[k] ?? 0) as int;
  int _l(String k) => (_stats['lectures']?[k] ?? 0) as int;
  int _e(String k) => (_stats['engagement']?[k] ?? 0) as int;
  Map<String, dynamic>? get _activeSemester =>
      _stats['semesters']?['active'] as Map<String, dynamic>?;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (_activeSemester != null) _buildSemesterBanner(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadStats,
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              FadeInSlide(delay: 0.1, child: _buildUsersSection()),
                              const SizedBox(height: 20),
                              FadeInSlide(delay: 0.15, child: _buildCoursesSection()),
                              const SizedBox(height: 20),
                              FadeInSlide(delay: 0.2, child: _buildEngagementSection()),
                              const SizedBox(height: 25),
                              FadeInSlide(delay: 0.25, child: _buildQuickActions()),
                              const SizedBox(height: 25),
                              FadeInSlide(delay: 0.3, child: _buildRecentSection()),
                            ],
                          ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) => Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(_glowAnimation.value * 0.7),
                  blurRadius: 25,
                  spreadRadius: 3,
                ),
              ]),
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${'welcome'.tr()} 👋",
                    style: GoogleFonts.poppins(
                        color: getSecondaryTextColor(context), fontSize: 13)),
                Text('system_admin'.tr(),
                    style: GoogleFonts.poppins(
                        color: getTextColor(context), fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          _iconBtn(Icons.settings_rounded,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
          const SizedBox(width: 8),
          _iconBtn(Icons.logout_rounded, _showLogoutDialog, isRed: true),
        ],
      ),
    );
  }

  Widget _buildSemesterBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 5, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.15), AppColors.darkBlue.withOpacity(0.15)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('current_semester'.tr(),
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: getSecondaryTextColor(context))),
                Text(_activeSemester!['name'] ?? '',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.bold, color: getTextColor(context))),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AdminSemestersScreen()))
                .then((_) => _loadStats()),
            child: const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, {bool isRed = false}) {
    Color col = isRed ? Colors.red : const Color(0xFF6C63FF);
    return  _hoverPressWrapper(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: col.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: col.withOpacity(0.3)),
        ),
        child: Icon(icon, color: col, size: 20),
      ),
    );
  }

  Widget _buildUsersSection() {
    return _section(
      title: 'users_section'.tr(),
      icon: Icons.groups_rounded,
      color: AppColors.primary,
      children: [
        Row(children: [
          _miniStat("${_u('students')}", 'students'.tr(), AppColors.primary),
          const SizedBox(width: 10),
          _miniStat("${_u('instructors')}", 'instructors'.tr(), AppColors.purple),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _miniStat("${_u('active')}", 'active'.tr(), Colors.green),
          const SizedBox(width: 10),
          _miniStat("${_u('pending')}", 'pending'.tr(), Colors.orange),
          const SizedBox(width: 10),
          _miniStat("${_u('blocked')}", 'blocked'.tr(), Colors.red),
        ]),
      ],
    );
  }

  Widget _buildCoursesSection() {
    return _section(
      title: 'courses_section'.tr(),
      icon: Icons.menu_book_rounded,
      color: AppColors.orange,
      children: [
        Row(children: [
          _miniStat("${_c('total')}", 'stat_total'.tr(), AppColors.orange),
          const SizedBox(width: 10),
          _miniStat("${_c('published')}", 'stat_published'.tr(), Colors.green),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _miniStat("${_c('draft')}", 'stat_draft'.tr(), Colors.grey),
          const SizedBox(width: 10),
          _miniStat("${_c('hidden')}", 'stat_hidden'.tr(), Colors.blueGrey),
        ]),
      ],
    );
  }

  Widget _buildEngagementSection() {
    return _section(
      title: 'engagement_section'.tr(),
      icon: Icons.insights_rounded,
      color: AppColors.purple,
      children: [
        Row(children: [
          _miniStat("${_l('total')}", 'stat_lectures_total'.tr(), AppColors.darkBlue),
          const SizedBox(width: 10),
          _miniStat("${_l('ai_generated')}", 'stat_ai_generated'.tr(), AppColors.purple),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _miniStat("${_e('enrollments')}", 'stat_active_enrollments'.tr(), AppColors.primary),
          const SizedBox(width: 10),
          _miniStat("${_e('quiz_attempts')}", 'stat_quiz_attempts'.tr(), Colors.teal),
        ]),
      ],
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.bold, color: getTextColor(context))),
          ]),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 10.5, color: getSecondaryTextColor(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('quick_actions'.tr(),
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 14),
          Row(children: [
            _actionBtn(
              'add_user'.tr(),
              Icons.person_add_alt_1_rounded,
              AppColors.primary,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const AdminCreateUserScreen(defaultRole: UserRole.student))).then((_) => _loadStats()),
            ),
            const SizedBox(width: 10),
            _actionBtn(
              'manage_users'.tr(),
              Icons.manage_accounts_rounded,
              AppColors.purple,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen()))
                  .then((_) => _loadStats()),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _actionBtn(
              'courses'.tr(),
              Icons.menu_book_rounded,
              AppColors.orange,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCoursesScreen()))
                  .then((_) => _loadStats()),
            ),
            const SizedBox(width: 10),
            _actionBtn(
              'semesters'.tr(),
              Icons.event_note_rounded,
              AppColors.darkBlue,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSemestersScreen()))
                  .then((_) => _loadStats()),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color col, VoidCallback onTap) {
    return Expanded(
     child: _hoverPressWrapper(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: col.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: col.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: col, size: 26),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      color: col, fontSize: 11.5, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSection() {
    final recent = (_stats['recent_users'] as List?) ?? [];
    if (recent.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('recent_users'.tr(),
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          ...recent.map((u) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: (u['role'] == 'student'
                              ? AppColors.primary
                              : AppColors.purple)
                          .withOpacity(0.15),
                      child: Text(
                        (u['full_name'] ?? '?').toString().isNotEmpty
                            ? u['full_name'][0]
                            : '?',
                        style: TextStyle(
                            color: u['role'] == 'student'
                                ? AppColors.primary
                                : AppColors.purple,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u['full_name'] ?? '',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(u['email'] ?? '',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: getSecondaryTextColor(context))),
                        ],
                      ),
                    ),
                    _statusChip(u['status'] ?? 'pending'),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final map = {
      'active': (Colors.green, 'active'.tr()),
      'pending': (Colors.orange, 'pending'.tr()),
      'blocked': (Colors.red, 'blocked'.tr()),
    };
    final (color, label) = map[status] ?? (Colors.grey, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('logout'.tr()),
        content: Text('logout_confirm'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr())),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
                (route) => false,
              );
            },
            child: Text('logout'.tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  Widget _hoverPressWrapper({
  required Widget child,
  required VoidCallback onTap,
}) {
  return StatefulBuilder(
    builder: (context, setState) {
      bool hovered = false;
      bool pressed = false;

      return MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => hovered = true),
        onExit: (_) => setState(() => hovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => pressed = true),
          onTapUp: (_) {
            setState(() => pressed = false);
            onTap();
          },
          onTapCancel: () => setState(() => pressed = false),
          child: AnimatedScale(
            scale: pressed ? 0.96 : 1,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: hovered
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ]
                    : [],
              ),
              child: child,
            ),
          ),
        ),
      );
    },
  );
}
}