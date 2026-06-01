// ============================================================
// 📄 LectureViewScreen
// المكان: lib/shared/lecture_view_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class LectureViewScreen extends StatelessWidget {
  final String lectureId;
  final String lectureTitle;
  final Color color;
  final bool hasAI;
  final String? filePath;
  final String? audioPath;
  final String contentType;
  final Widget Function() buildAIScreen;

  const LectureViewScreen({
    super.key,
    required this.lectureId,
    required this.lectureTitle,
    required this.color,
    required this.hasAI,
    required this.buildAIScreen,
    this.filePath,
    this.audioPath,
    this.contentType = 'pdf',
  });

  String? get _fileUrl {
    if (filePath == null || filePath!.isEmpty) return null;
    return '${ApiService.baseUrl}/uploads/$filePath';
  }

  String? get _audioUrl {
    if (audioPath == null || audioPath!.isEmpty) return null;
    return '${ApiService.baseUrl}/uploads/$audioPath';
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('cannot_open_file'.tr())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const SizedBox(height: 10),

                    // ── قسم المحاضرة الأصلية
                    _sectionTitle(
                      context,
                      Icons.folder_open_rounded,
                      'original_lecture'.tr(),
                      Colors.blue.shade700,
                    ),
                    const SizedBox(height: 12),

                    // ── PDF
                    if (_fileUrl != null) ...[
                      _actionCard(
                        context: context,
                        icon: Icons.picture_as_pdf_rounded,
                        iconColor: Colors.red.shade700,
                        title: 'pdf_lecture'.tr(),
                        subtitle: filePath?.split('/').last ?? '',
                        buttonLabel: 'open_pdf'.tr(),
                        buttonColor: Colors.red.shade700,
                        onTap: () async => await _openUrl(context, _fileUrl!),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── صوت
                    if (_audioUrl != null) ...[
                      _actionCard(
                        context: context,
                        icon: Icons.audiotrack_rounded,
                        iconColor: Colors.purple,
                        title: 'audio_lecture'.tr(),
                        subtitle: audioPath?.split('/').last ?? '',
                        buttonLabel: 'play_audio'.tr(),
                        buttonColor: Colors.purple,
                        onTap: () async => await _openUrl(context, _audioUrl!),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── لو ما في ملف
                    if (_fileUrl == null && _audioUrl == null)
                      _noFileCard(context),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // ── قسم الملخص الذكي
                    _sectionTitle(
                      context,
                      Icons.auto_awesome_rounded,
                      'ai_smart_content'.tr(),
                      color,
                    ),
                    const SizedBox(height: 12),

                    // ── زر الملخص
                    if (hasAI)
                      _actionCard(
                        context: context,
                        icon: Icons.psychology_rounded,
                        iconColor: color,
                        title: 'smart_summary_quiz'.tr(),
                        subtitle: 'tap_to_view_summary'.tr(),
                        buttonLabel: 'view_summary'.tr(),
                        buttonColor: color,
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => buildAIScreen(),
                              ),
                            ),
                      )
                    else
                      _aiNotReadyCard(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
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
                  'lecture'.tr(),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  lectureTitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color:
                  hasAI
                      ? Colors.green.withOpacity(0.85)
                      : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasAI ? Icons.check_circle_rounded : Icons.pending_rounded,
                  color: Colors.white,
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  hasAI ? 'ai_ready'.tr() : 'ai_pending'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    BuildContext context,
    IconData icon,
    String title,
    Color c,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: c.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: c, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: getTextColor(context),
          ),
        ),
      ],
    );
  }

  Widget _actionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required Color buttonColor,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: getSecondaryTextColor(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              buttonLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noFileCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder_off_rounded,
            color: Colors.grey.withOpacity(0.5),
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'no_original_file'.tr(),
            style: TextStyle(color: getSecondaryTextColor(context)),
          ),
        ],
      ),
    );
  }

  Widget _aiNotReadyCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.hourglass_top_rounded,
            color: Colors.orange,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ai_not_ready'.tr(),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'ai_being_prepared'.tr(),
                  style: TextStyle(
                    fontSize: 11,
                    color: getSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
