import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';
import 'package:cluster_app/features/settings/settings_screen.dart';
import 'package:cluster_app/features/auth/unified_login_screen.dart';

class InstructorProfile extends StatefulWidget {
  final String userId;
  const InstructorProfile({super.key, required this.userId});

  @override
  State<InstructorProfile> createState() => _InstructorProfileState();
}

class _InstructorProfileState extends State<InstructorProfile> {
  Map<String, dynamic> _p = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final p = await ApiService.getInstructorProfile(widget.userId);
    if (mounted) setState(() { _p = p; _loading = false; });
  }

  String _v(String key, {String fallback = '—'}) =>
      (_p[key]?.toString().isNotEmpty == true) ? _p[key].toString() : fallback;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            FadeInSlide(delay: 0.2, child: _buildStatsRow()),
                            const SizedBox(height: 22),
                            FadeInSlide(
                              delay: 0.3,
                              child: _buildInfoCard(
                                'personal_info'.tr(),
                                Icons.person_outline_rounded,
                                [
                                  {"label": 'full_name'.tr(),  "value": _v('full_name')},
                                  {"label": 'email'.tr(),      "value": _v('email')},
                                  {"label": 'employee_id'.tr(),"value": _v('employee_num')},
                                  {"label": 'status'.tr(),     "value": _statusLabel(_v('status'))},
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            FadeInSlide(
                              delay: 0.4,
                              child: _buildInfoCard(
                                'academic_info'.tr(),
                                Icons.school_outlined,
                                [
                                  {"label": 'department_label'.tr(),       "value": _v('department')},
                                  {"label": 'specialization_label'.tr(),    "value": _v('specialization')},
                                  {"label": 'experience_years_label'.tr(),  "value": "${_v('experience_years', fallback: '0')} ${'years_unit'.tr()}"},
                                ],
                              ),
                            ),
                            if (_v('bio', fallback: '') != '') ...[
                              const SizedBox(height: 18),
                              FadeInSlide(
                                delay: 0.45,
                                child: _buildBioCard(_v('bio')),
                              ),
                            ],
                            const SizedBox(height: 22),
                            FadeInSlide(delay: 0.5, child: _settingsButton()),
                            const SizedBox(height: 12),
                            FadeInSlide(delay: 0.55, child: _logoutButton()),
                            const SizedBox(height: 30),
                          ],
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
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.purple, Color(0xFF6C63FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(35)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
              const Spacer(),
              Text('my_profile'.tr(),
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              const SizedBox(width: 34),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              color: Colors.white.withOpacity(0.2),
            ),
            child: Center(
              child: Text(
                _v('full_name', fallback: '?').isNotEmpty
                    ? _v('full_name').substring(0, 1).toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(_v('full_name'),
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(_v('specialization', fallback: 'instructor'.tr()),
              style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.85), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final coursesCount = int.tryParse(_p['courses_count']?.toString() ?? '0') ?? 0;
    final lecturesCount = int.tryParse(_p['lectures_count']?.toString() ?? '0') ?? 0;
    final years = int.tryParse(_p['experience_years']?.toString() ?? '0') ?? 0;

    return Row(
      children: [
        _statBox("$coursesCount", 'stat_courses'.tr(), AppColors.primary),
        const SizedBox(width: 10),
        _statBox("$lecturesCount", 'stat_lectures'.tr(), AppColors.orange),
        const SizedBox(width: 10),
        _statBox("$years", 'experience_years_label'.tr(), AppColors.purple),
      ],
    );
  }

  Widget _statBox(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: getSecondaryTextColor(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Map<String, String>> items) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: AppColors.primary, size: 19),
            const SizedBox(width: 8),
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          ...items.map((it) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(it["label"] ?? '',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: getSecondaryTextColor(context))),
                    Flexible(
                      child: Text(
                        it["value"] ?? '',
                        textAlign: TextAlign.end,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildBioCard(String bio) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.notes_rounded, color: AppColors.primary, size: 19),
            const SizedBox(width: 8),
            Text('biography'.tr(),
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          Text(bio,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  height: 1.6,
                  color: getSecondaryTextColor(context))),
        ],
      ),
    );
  }

  Widget _settingsButton() {
    return ScaleButton(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SettingsScreen())),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.settings_rounded, color: AppColors.primary, size: 19),
            const SizedBox(width: 8),
            Text('settings'.tr(),
                style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _logoutButton() {
    return ScaleButton(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('logout'.tr()),
          content: Text('logout_confirm'.tr()),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr())),
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
                    (r) => false,
                  );
                },
                child: Text('logout'.tr(),
                    style: const TextStyle(color: Colors.red))),
          ],
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: Colors.red, size: 19),
            const SizedBox(width: 8),
            Text('logout'.tr(),
                style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'active':  return 'status_active_check'.tr();
      case 'pending': return 'status_pending_label'.tr();
      case 'blocked': return 'status_blocked_label'.tr();
      default: return s;
    }
  }
}