// ============================================================
// 🚫 MutedStudentsScreen — إدارة الطلاب المكتومين
// ============================================================
//
// المكان: lib/features/chat/muted_students_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cluster_app/core/api/chat_api.dart';
import 'package:cluster_app/core/constants/app_icons.dart';

class MutedStudentsScreen extends StatefulWidget {
  final int courseId;
  final int instructorUserId;
  final Color color;

  const MutedStudentsScreen({
    super.key,
    required this.courseId,
    required this.instructorUserId,
    required this.color,
  });

  @override
  State<MutedStudentsScreen> createState() => _MutedStudentsScreenState();
}

class _MutedStudentsScreenState extends State<MutedStudentsScreen> {
  List<dynamic> _mutedList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await ChatApi.getMutedList(
      courseId: widget.courseId,
      instructorUserId: widget.instructorUserId,
    );
    if (mounted) {
      setState(() {
        _mutedList = list;
        _loading = false;
      });
    }
  }

  Future<void> _unmute(dynamic m) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('unmute_student'.tr()),
        content: Text('unmute_confirm'
            .tr()
            .replaceAll('{name}', m['full_name'] ?? '')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('cancel'.tr())),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('unmute'.tr(),
                  style: const TextStyle(color: Colors.green))),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await ChatApi.unmuteStudent(
      courseId: widget.courseId,
      instructorUserId: widget.instructorUserId,
      studentUserId: m['student_user_id'],
    );

    if (!mounted) return;

    if (result['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${'unmuted_successfully'.tr()}'),
          backgroundColor: Colors.green,
        ),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'فشل')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: _mutedList.isEmpty
                          ? _empty()
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _mutedList.length,
                              itemBuilder: (_, i) =>
                                  _mutedCard(_mutedList[i]),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.color, widget.color.withOpacity(0.7)],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          AppIconImage(AppIcons.warning, size: 26),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'muted_students'.tr(),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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
              "${_mutedList.length}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Center(
          child: Opacity(
            opacity: 0.5,
            child: AppIconImage(AppIcons.community, size: 80),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'no_muted_students'.tr(),
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _mutedCard(dynamic m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: AppIconImage(AppIcons.education, size: 26),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m['full_name'] ?? '',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      m['email'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _unmute(m),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIconImage(AppIcons.checkMark, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'unmute'.tr(),
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (m['reason'] != null && m['reason'].toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "📝 ${m['reason']}",
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            '${'muted_at'.tr()}: ${m['muted_at']}',
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}