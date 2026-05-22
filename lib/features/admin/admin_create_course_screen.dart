import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';
import 'package:cluster_app/features/admin/admin_course_management_screen.dart';

class AdminCreateCourseScreen extends StatefulWidget {
  const AdminCreateCourseScreen({super.key});
  @override
  State<AdminCreateCourseScreen> createState() => _AdminCreateCourseScreenState();
}

class _AdminCreateCourseScreenState extends State<AdminCreateCourseScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String? _selectedInstructorId;
  String? _selectedSemesterId;
  String _status = 'published';
  String _coverColor = '#00BCD4';

  List<dynamic> _instructors = [];
  List<dynamic> _semesters = [];
  bool _loadingDeps = true;
  bool _saving = false;

  static const List<String> _palette = [
    '#00BCD4', '#AB47BC', '#FF7043', '#0277BD',
    '#D32F2F', '#1976D2', '#7B1FA2', '#388E3C',
    '#F57C00', '#5D4037', '#455A64', '#E91E63',
  ];

  @override
  void initState() {
    super.initState();
    _loadDeps();
  }

  Future<void> _loadDeps() async {
    final results = await Future.wait([
      ApiService.getInstructors(),
      ApiService.getSemesters(),
    ]);
    if (!mounted) return;
    setState(() {
      _instructors = results[0];
      _semesters = results[1];

      final activeIndex = _semesters.indexWhere(
        (s) => s['is_active'].toString() == '1',
      );
      if (activeIndex != -1) {
        _selectedSemesterId = _semesters[activeIndex]['id'].toString();
      }

      _loadingDeps = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_titleController.text.trim().isEmpty) {
      _showSnack('course_name_required'.tr());
      return;
    }
    if (_selectedSemesterId == null) {
      _showSnack('select_semester_required'.tr());
      return;
    }

    setState(() => _saving = true);
    final res = await ApiService.createCourse(
      title: _titleController.text.trim(),
      description:
          _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      instructorId: _selectedInstructorId,
      semesterId: _selectedSemesterId,
      status: _status,
      coverColor: _coverColor,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (res['status'] == 'success') {
      final newCourseId = res['data']?['id']?.toString();
      _showSnack('course_created'.tr(), color: Colors.green);

      if (newCourseId != null) {
        final initialCourse = _buildCoursePreview(newCourseId);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  AdminCourseManagementScreen(course: initialCourse)),
        );
      } else {
        Navigator.pop(context);
      }
    } else {
      _showSnack(res['message'] ?? 'update_failed'.tr(), color: Colors.red);
    }
  }

  Map<String, dynamic> _buildCoursePreview(String id) {
    String? instructorName;
    if (_selectedInstructorId != null) {
      final i = _instructors.firstWhere(
        (e) => e['instructor_id'].toString() == _selectedInstructorId,
        orElse: () => {},
      );
      if (i is Map && i['full_name'] != null) instructorName = i['full_name'];
    }

    String? semesterName;
    final s = _semesters.firstWhere(
      (e) => e['id'].toString() == _selectedSemesterId,
      orElse: () => {},
    );
    if (s is Map && s['name'] != null) semesterName = s['name'];

    return {
      'id': id,
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'cover_color': _coverColor,
      'status': _status,
      'instructor_id': _selectedInstructorId,
      'semester_id': _selectedSemesterId,
      'instructor_name': instructorName,
      'semester_name': semesterName,
      'enrollments_count': 0,
      'lectures_count': 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loadingDeps
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        FadeInSlide(
                          delay: 0.1,
                          child: _input(_titleController,
                              "${'course_name'.tr()} *",
                              'example_dart_flutter'.tr(),
                              Icons.book_rounded),
                        ),
                        const SizedBox(height: 16),
                        FadeInSlide(
                          delay: 0.15,
                          child: _input(_descController,
                              'course_description'.tr(),
                              'brief_description_optional'.tr(),
                              Icons.description_rounded,
                              maxLines: 3),
                        ),
                        const SizedBox(height: 18),
                        FadeInSlide(delay: 0.2, child: _semesterPicker()),
                        const SizedBox(height: 18),
                        FadeInSlide(delay: 0.25, child: _instructorPicker()),
                        const SizedBox(height: 18),
                        FadeInSlide(delay: 0.3, child: _statusPicker()),
                        const SizedBox(height: 18),
                        FadeInSlide(delay: 0.35, child: _colorPicker()),
                        const SizedBox(height: 30),
                        FadeInSlide(delay: 0.4, child: _submitButton()),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 25),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)]),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
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
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 15),
          Text('new_course'.tr(),
              style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _semesterPicker() {
    return _section(
      label: "${'semester'.tr()} *",
      icon: Icons.event_note_rounded,
      child: _semesters.isEmpty
          ? _emptyHint('no_semesters_create_first'.tr())
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: _fieldDecoration(),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSemesterId,
                  isExpanded: true,
                  hint: Text('select_semester'.tr(),
                      style: GoogleFonts.poppins(
                          color: getSecondaryTextColor(context))),
                  dropdownColor: getCardColor(context),
                  items: _semesters.map((s) {
                    final isActive = s['is_active'].toString() == '1';
                    return DropdownMenuItem<String>(
                      value: s['id'].toString(),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              s['name'] ?? '',
                              style: GoogleFonts.poppins(
                                  color: getTextColor(context), fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('current_semester_marker'.tr(),
                                  style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedSemesterId = v),
                ),
              ),
            ),
    );
  }

  Widget _instructorPicker() {
    return _section(
      label: 'responsible_instructor'.tr(),
      icon: Icons.person_pin_rounded,
      child: _instructors.isEmpty
          ? _emptyHint('no_instructors_yet'.tr())
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: _fieldDecoration(),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedInstructorId,
                  isExpanded: true,
                  hint: Text('select_instructor_optional'.tr(),
                      style: GoogleFonts.poppins(
                          color: getSecondaryTextColor(context))),
                  dropdownColor: getCardColor(context),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('no_instructor'.tr(),
                          style: GoogleFonts.poppins(
                              color: getSecondaryTextColor(context),
                              fontStyle: FontStyle.italic,
                              fontSize: 13)),
                    ),
                    ..._instructors.map((i) => DropdownMenuItem<String?>(
                          value: i['instructor_id'].toString(),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  i['full_name'] ?? '',
                                  style: GoogleFonts.poppins(
                                      color: getTextColor(context),
                                      fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (i['employee_num'] != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  "(${i['employee_num']})",
                                  style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: getSecondaryTextColor(context)),
                                ),
                              ],
                            ],
                          ),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedInstructorId = v),
                ),
              ),
            ),
    );
  }

  Widget _statusPicker() {
    return _section(
      label: 'course_status'.tr(),
      icon: Icons.toggle_on_rounded,
      child: Row(
        children: [
          _statusOption('published', 'published'.tr(), Colors.green),
          const SizedBox(width: 8),
          _statusOption('draft', 'draft'.tr(), Colors.orange),
          const SizedBox(width: 8),
          _statusOption('hidden', 'hidden'.tr(), Colors.grey),
        ],
      ),
    );
  }

  Widget _statusOption(String value, String label, Color color) {
    final selected = _status == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _status = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(selected ? 1 : 0.3)),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                  color: selected ? Colors.white : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                )),
          ),
        ),
      ),
    );
  }

  Widget _colorPicker() {
    return _section(
      label: 'cover_color'.tr(),
      icon: Icons.palette_rounded,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _palette.map((hex) {
          final color = _parseHex(hex);
          final selected = _coverColor == hex;
          return GestureDetector(
            onTap: () => setState(() => _coverColor = hex),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(selected ? 0.6 : 0.2),
                    blurRadius: selected ? 12 : 4,
                    spreadRadius: selected ? 2 : 0,
                  ),
                ],
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _submitButton() {
    return ScaleButton(
      onTap: _saving ? () {} : _create,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_saving)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            else
              const Icon(Icons.add_circle_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Text(_saving ? 'creating_course'.tr() : 'create_course'.tr(),
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, String label, String hint, IconData icon,
      {int maxLines = 1}) {
    return _section(
      label: label,
      icon: icon,
      child: Container(
        decoration: _fieldDecoration(),
        child: TextField(
          controller: c,
          maxLines: maxLines,
          style: GoogleFonts.poppins(color: getTextColor(context), fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
                color: getSecondaryTextColor(context), fontSize: 12),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _section({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF6C63FF)),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: getSecondaryTextColor(context))),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _emptyHint(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  BoxDecoration _fieldDecoration() {
    return BoxDecoration(
      color: getCardColor(context),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.withOpacity(0.2)),
    );
  }

  Color _parseHex(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xff')));
  }

  void _showSnack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color));
  }
}