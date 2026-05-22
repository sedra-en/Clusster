import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:cluster_app/core/app_provider.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/features/settings/settings_screen.dart';
import 'package:cluster_app/features/auth/unified_login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale == const Locale('ar');

    return Scaffold(
      body: AppBackground(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, isAr)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    FadeInSlide(delay: 0.2, child: _buildStatsRow(context, isAr)),
                    const SizedBox(height: 25),
                    FadeInSlide(
                      delay: 0.3,
                      child: _buildInfoCard(
                        context,
                        'personal_info'.tr(),
                        Icons.person_outline_rounded,
                        [
                          {"label": 'full_name'.tr(), "value": "Nour Ahmad"},
                          {"label": 'email'.tr(), "value": "nour@university.edu"},
                          {"label": 'phone'.tr(), "value": "+963 999 123 456"},
                          {"label": 'student_id'.tr(), "value": "2021-CS-1234"},
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeInSlide(
                      delay: 0.4,
                      child: _buildInfoCard(
                        context,
                        'academic_info'.tr(),
                        Icons.school_outlined,
                        [
                          {"label": 'faculty'.tr(), "value": 'it_engineering'.tr()},
                          {"label": 'major'.tr(), "value": 'software_engineering'.tr()},
                          {"label": 'year'.tr(), "value": '4th_year'.tr()},
                          {"label": 'advisor'.tr(), "value": isAr ? "د. محمد علي" : "Dr. Mohammad Ali"},
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeInSlide(delay: 0.5, child: _buildQuickSettings(context)),
                    const SizedBox(height: 20),
                    FadeInSlide(delay: 0.6, child: _buildLogoutButton(context)),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isAr) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.darkBlue]),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                ),
              ),
              const Spacer(),
              Text('my_profile'.tr(), style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Stack(
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const CircleAvatar(radius: 50, backgroundColor: Colors.white, child: Icon(Icons.person, size: 50, color: AppColors.primary)),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                  child: const Icon(Icons.camera_alt, color: AppColors.darkBlue, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text("Nour Ahmad", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text('software_engineering'.tr(), style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, bool isAr) {
    return Row(
      children: [
        _statItem(context, "3.98", 'gpa'.tr(), Icons.star_rounded, Colors.amber),
        const SizedBox(width: 12),
        _statItem(context, "120", 'hours'.tr(), Icons.access_time_rounded, AppColors.primary),
        const SizedBox(width: 12),
        _statItem(context, isAr ? "٤" : "4th", 'year'.tr(), Icons.school_rounded, AppColors.purple),
      ],
    );
  }

  Widget _statItem(BuildContext context, String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: getCardColor(context), borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 22)),
            const SizedBox(height: 10),
            Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: getTextColor(context))),
            Text(label, style: GoogleFonts.poppins(fontSize: 11, color: getSecondaryTextColor(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, IconData icon, List<Map<String, String>> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: getCardColor(context), borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColors.primary, size: 22)),
            const SizedBox(width: 12),
            Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: getTextColor(context))),
          ]),
          const SizedBox(height: 20),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(item["label"]!, style: GoogleFonts.poppins(fontSize: 13, color: getSecondaryTextColor(context))),
              Text(item["value"]!, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: getTextColor(context))),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _buildQuickSettings(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    final isAr = context.locale == const Locale('ar');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: getCardColor(context), borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.settings_outlined, color: AppColors.orange, size: 22)),
            const SizedBox(width: 12),
            Text('settings'.tr(), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: getTextColor(context))),
          ]),
          const SizedBox(height: 15),

          // Dark Mode
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.dark_mode_outlined, color: getSecondaryTextColor(context), size: 22),
            title: Text('dark_mode'.tr(), style: GoogleFonts.poppins(fontSize: 14, color: getTextColor(context))),
            trailing: Switch(value: app.isDarkMode, onChanged: (_) => app.toggleTheme(), activeColor: AppColors.primary),
          ),

          // Language
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.language_rounded, color: getSecondaryTextColor(context), size: 22),
            title: Text('language'.tr(), style: GoogleFonts.poppins(fontSize: 14, color: getTextColor(context))),
            trailing: Switch(
              value: isAr,
              onChanged: (_) {
                if (isAr) {
                  context.setLocale(const Locale('en'));
                } else {
                  context.setLocale(const Locale('ar'));
                }
              },
              activeColor: AppColors.primary,
            ),
          ),

          const Divider(height: 20),

          // All Settings
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
            title: Text(isAr ? "كل الإعدادات" : "All Settings", style: GoogleFonts.poppins(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primary),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ScaleButton(
      onTap: () => _showLogoutDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.red.withOpacity(0.3))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.logout_rounded, color: Colors.red),
          const SizedBox(width: 10),
          Text('logout'.tr(), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red)),
        ]),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: getCardColor(context),
        title: Text('logout'.tr(), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: getTextColor(context))),
        content: Text('logout_confirm'.tr(), style: GoogleFonts.poppins(color: getSecondaryTextColor(context))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr(), style: GoogleFonts.poppins(color: getSecondaryTextColor(context)))),
          ElevatedButton(
            onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()), (route) => false),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('logout'.tr(), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}