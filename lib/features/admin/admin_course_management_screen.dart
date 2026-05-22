import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';

class AdminCourseManagementScreen extends StatefulWidget {
  final Map<String, dynamic> course;
  const AdminCourseManagementScreen({super.key, required this.course});

  @override
  State<AdminCourseManagementScreen> createState() =>
      _AdminCourseManagementScreenState();
}

class _AdminCourseManagementScreenState
    extends State<AdminCourseManagementScreen> {
  List<dynamic> _enrollments = [];
  bool _loading = true;

  String get _courseId => widget.course['id'].toString();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await ApiService.getCourseEnrollments(_courseId);
    if (mounted) {
      setState(() {
        _enrollments = list;
        _loading = false;
      });
    }
  }

  Future<void> _openAddStudentsSheet() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddStudentsSheet(courseId: _courseId),
    );
    if (added == true) _load();
  }

  Future<void> _confirmUnenroll(dynamic e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('unenroll'.tr()),
        content: Text('unenroll_confirm'.tr().replaceAll('{name}', e['full_name'] ?? '')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('cancel'.tr())),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('unenroll'.tr(),
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;

    final res = await ApiService.unenrollStudent(
        enrollmentId: e['enrollment_id'].toString());
    if (!mounted) return;
    if (res['status'] == 'success') {
      _showSnack('unenrolled'.tr(), color: Colors.green);
      _load();
    } else {
      _showSnack(res['message'] ?? 'update_failed'.tr(), color: Colors.red);
    }
  }

  Future<void> _confirmDeleteCourse() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('delete_course'.tr()),
        content: Text(
            "${widget.course['title']}\n\n${'delete_course_confirm'.tr()}"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('cancel'.tr())),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('delete_permanently'.tr(),
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;

    final res = await ApiService.deleteCourse(_courseId);
    if (!mounted) return;
    if (res['status'] == 'success') {
      _showSnack('course_deleted'.tr(), color: Colors.green);
      Navigator.pop(context);
    } else {
      _showSnack(res['message'] ?? 'update_failed'.tr(), color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(widget.course['cover_color']);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(color),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding:
                              const EdgeInsets.fromLTRB(20, 5, 20, 90),
                          children: [
                            _buildInfoCard(color),
                            const SizedBox(height: 16),
                            _buildEnrollmentsHeader(),
                            const SizedBox(height: 8),
                            if (_enrollments.isEmpty) _buildEmptyState(),
                            ..._enrollments.map((e) => _enrollmentTile(e)),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: color,
        onPressed: _openAddStudentsSheet,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: Text('add_students'.tr(),
            style: GoogleFonts.poppins(color: Colors.white)),
      ),
    );
  }

  Widget _buildHeader(Color color) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(28)),
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
              GestureDetector(
                onTap: _confirmDeleteCourse,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
            ),
            child: const Icon(Icons.menu_book_rounded,
                color: Colors.white, size: 36),
          ),
          const SizedBox(height: 12),
          Text(widget.course['title'] ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Color color) {
    final instructor = widget.course['instructor_name']?.toString();
    final semester = widget.course['semester_name']?.toString();
    final desc = widget.course['description']?.toString();
    final status = widget.course['status']?.toString() ?? 'draft';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (desc != null && desc.isNotEmpty) ...[
            Text(desc,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: getSecondaryTextColor(context),
                    height: 1.5)),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 6),
          ],
          _infoRow(Icons.person_pin_rounded, 'instructor'.tr(),
              instructor ?? 'no_instructor'.tr(),
              valueColor: instructor != null ? AppColors.purple : Colors.orange),
          _infoRow(Icons.event_note_rounded, 'semester'.tr(), semester ?? "—"),
          _infoRow(Icons.toggle_on_rounded, 'course_status'.tr(), _statusLabel(status),
              valueColor: _statusColor(status)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: getSecondaryTextColor(context))),
          const Spacer(),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? getTextColor(context))),
        ],
      ),
    );
  }

  Widget _buildEnrollmentsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const Icon(Icons.groups_rounded,
              color: AppColors.primary, size: 18),
          const SizedBox(width: 6),
          Text('enrolled_students'.tr(),
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(width: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text("${_enrollments.length}",
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Icon(Icons.person_add_alt_rounded,
              size: 50,
              color: getSecondaryTextColor(context).withOpacity(0.4)),
          const SizedBox(height: 10),
          Text('no_enrolled_students'.tr(),
              style: GoogleFonts.poppins(
                  color: getSecondaryTextColor(context))),
          const SizedBox(height: 4),
          Text('press_add_students'.tr(),
              style: GoogleFonts.poppins(
                  fontSize: 11, color: getSecondaryTextColor(context))),
        ],
      ),
    );
  }

  Widget _enrollmentTile(dynamic e) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: Text(
              (e['full_name'] ?? '?').toString().isNotEmpty
                  ? e['full_name'][0]
                  : '?',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e['full_name'] ?? '',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (e['student_num'] != null)
                      Text("${e['student_num']}",
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: getSecondaryTextColor(context))),
                    if (e['major'] != null) ...[
                      Text(" • ",
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: getSecondaryTextColor(context))),
                      Text("${e['major']}",
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: getSecondaryTextColor(context))),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded,
                color: Colors.red, size: 22),
            onPressed: () => _confirmUnenroll(e),
            tooltip: 'unenroll'.tr(),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'published': return 'published'.tr();
      case 'draft': return 'draft'.tr();
      case 'hidden': return 'hidden'.tr();
      default: return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'published': return Colors.green;
      case 'draft': return Colors.orange;
      case 'hidden': return Colors.grey;
      default: return Colors.grey;
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

  void _showSnack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color));
  }
}

class _AddStudentsSheet extends StatefulWidget {
  final String courseId;
  const _AddStudentsSheet({required this.courseId});

  @override
  State<_AddStudentsSheet> createState() => _AddStudentsSheetState();
}

class _AddStudentsSheetState extends State<_AddStudentsSheet> {
  List<dynamic> _available = [];
  final Set<String> _selected = {};
  bool _loading = true;
  bool _saving = false;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list =
        await ApiService.getStudents(excludeCourseId: widget.courseId);
    if (mounted) setState(() { _available = list; _loading = false; });
  }

  List<dynamic> get _filtered {
    if (_search.isEmpty) return _available;
    final q = _search.toLowerCase();
    return _available.where((s) {
      final name = (s['full_name'] ?? '').toString().toLowerCase();
      final num_ = (s['student_num'] ?? '').toString().toLowerCase();
      final email = (s['email'] ?? '').toString().toLowerCase();
      return name.contains(q) || num_.contains(q) || email.contains(q);
    }).toList();
  }

  Future<void> _enroll() async {
    if (_selected.isEmpty) return;
    setState(() => _saving = true);
    final res = await ApiService.bulkEnroll(
        widget.courseId, _selected.toList());
    if (!mounted) return;
    setState(() => _saving = false);

    if (res['status'] == 'success') {
      final added = res['data']?['added'] ?? _selected.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('students_enrolled'.tr().replaceAll('{n}', '$added')),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(res['message'] ?? 'update_failed'.tr()),
            backgroundColor: Colors.red),
      );
    }
  }

  void _toggleAll() {
    setState(() {
      if (_selected.length == _filtered.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(_filtered.map((s) => s['student_id'].toString()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final allSelected =
        _filtered.isNotEmpty && _selected.length == _filtered.length;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: getCardColor(context),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('select_students'.tr(),
                      style: GoogleFonts.poppins(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (_filtered.isNotEmpty)
                    TextButton(
                      onPressed: _toggleAll,
                      child: Text(allSelected ? 'deselect_all'.tr() : 'select_all'.tr(),
                          style: const TextStyle(color: AppColors.primary)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.15)),
                ),
                child: Row(children: [
                  const Icon(Icons.search_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      style: GoogleFonts.poppins(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'search_by_name_or_id'.tr(),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded,
                                  size: 50,
                                  color: getSecondaryTextColor(context)
                                      .withOpacity(0.3)),
                              const SizedBox(height: 10),
                              Text(
                                  _available.isEmpty
                                      ? 'no_students_to_add'.tr()
                                      : 'no_results'.tr(),
                                  style: GoogleFonts.poppins(
                                      color:
                                          getSecondaryTextColor(context))),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final s = _filtered[i];
                            final id = s['student_id'].toString();
                            final selected = _selected.contains(id);
                            return GestureDetector(
                              onTap: () => setState(() {
                                if (selected) {
                                  _selected.remove(id);
                                } else {
                                  _selected.add(id);
                                }
                              }),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primary.withOpacity(0.08)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.primary
                                        : Colors.grey.withOpacity(0.15),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: selected
                                                ? AppColors.primary
                                                : Colors.grey
                                                    .withOpacity(0.5),
                                            width: 2),
                                      ),
                                      child: selected
                                          ? const Icon(Icons.check,
                                              size: 14, color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor:
                                          AppColors.primary.withOpacity(0.12),
                                      child: Text(
                                        (s['full_name'] ?? '?')
                                                .toString()
                                                .isNotEmpty
                                            ? s['full_name'][0]
                                            : '?',
                                        style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(s['full_name'] ?? '',
                                              style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13)),
                                          if (s['student_num'] != null)
                                            Text("${s['student_num']}",
                                                style: GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    color:
                                                        getSecondaryTextColor(
                                                            context))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
              child: ScaleButton(
                onTap: (_saving || _selected.isEmpty) ? () {} : _enroll,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      _selected.isEmpty
                          ? Colors.grey
                          : AppColors.primary,
                      _selected.isEmpty
                          ? Colors.grey.shade700
                          : AppColors.darkBlue,
                    ]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            _selected.isEmpty
                                ? 'select_students_to_enroll'.tr()
                                : 'enroll_n_students'.tr().replaceAll('{n}', '${_selected.length}'),
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}