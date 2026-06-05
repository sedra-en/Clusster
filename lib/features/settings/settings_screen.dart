import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:cluster_app/core/app_provider.dart';
import 'package:cluster_app/shared/shared_ui.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    final isAr = context.locale == const Locale('ar');

    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  FadeInSlide(
                    delay: 0.1,
                    child: _buildSectionTitle(context, 'appearance'.tr()),
                  ),
                  const SizedBox(height: 15),

                  FadeInSlide(
                    delay: 0.2,
                    child: _buildSettingCard(
                      context,
                      title: 'dark_mode'.tr(),
                      subtitle:
                          app.isDarkMode ? 'enabled'.tr() : 'disabled'.tr(),
                      color: AppColors.purple,
                      trailing: Switch(
                        value: app.isDarkMode,
                        onChanged: (_) => app.toggleTheme(),
                        activeColor: AppColors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  FadeInSlide(
                    delay: 0.3,
                    child: _buildSettingCard(
                      context,
                      title: 'language'.tr(),
                      subtitle: isAr ? "العربية" : "English",
                      color: AppColors.orange,
                      trailing: Switch(
                        value: isAr,
                        onChanged: (_) {
                          context.setLocale(
                            isAr ? const Locale('en') : const Locale('ar'),
                          );
                        },
                        activeColor: AppColors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return FadeInSlide(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: getCardColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: getTextColor(context),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Text(
              'settings'.tr(),
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: getTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: getTextColor(context),
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
    Widget? trailing,
  }) {
    return _PressableCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: getCardColor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.tune_rounded, color: color, size: 22),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: getTextColor(context),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: getSecondaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            trailing ?? const SizedBox(),
          ],
        ),
      ),
    );
  }
}

class _PressableCard extends StatefulWidget {
  final Widget child;
  const _PressableCard({required this.child});

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}
