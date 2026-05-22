import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';

class AdminSemestersScreen extends StatefulWidget {
  const AdminSemestersScreen({super.key});
  @override
  State<AdminSemestersScreen> createState() => _AdminSemestersScreenState();
}

class _AdminSemestersScreenState extends State<AdminSemestersScreen> {
  List<dynamic> _semesters = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getSemesters();
    if (mounted) setState(() { _semesters = data; _loading = false; });
  }

  Future<void> _setActive(String id) async {
    final res = await ApiService.setActiveSemester(id);
    if (!mounted) return;
    if (res['status'] == 'success') {
      _showSnack('current_semester_set'.tr(), color: Colors.green);
      _load();
    } else {
      _showSnack(res['message'] ?? 'update_failed'.tr(), color: Colors.red);
    }
  }

  void _openCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateSemesterSheet(onCreated: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('semesters'.tr(), style: GoogleFonts.poppins()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _semesters.isEmpty
                      ? _emptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 5, 20, 90),
                          itemCount: _semesters.length,
                          itemBuilder: (_, i) => _semesterCard(_semesters[i]),
                        ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _openCreateSheet,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('new_semester'.tr(), style: GoogleFonts.poppins(color: Colors.white)),
      ),
    );
  }

  Widget _emptyState() {
    return ListView(children: [
      const SizedBox(height: 100),
      Icon(Icons.event_busy_rounded,
          size: 80, color: getSecondaryTextColor(context).withOpacity(0.3)),
      const SizedBox(height: 15),
      Center(
        child: Text('no_semesters'.tr(),
            style: GoogleFonts.poppins(color: getSecondaryTextColor(context))),
      ),
      const SizedBox(height: 10),
      Center(
        child: Text('press_new_semester'.tr(),
            style: GoogleFonts.poppins(
                fontSize: 12, color: getSecondaryTextColor(context))),
      ),
    ]);
  }

  Widget _semesterCard(dynamic s) {
    final isActive = s['is_active'].toString() == '1';
    final coursesCount = int.tryParse(s['courses_count']?.toString() ?? '0') ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.primary : Colors.grey.withOpacity(0.15),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event_note_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(s['name'] ?? '',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('current_semester'.tr(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                )),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text("${'semester_code'.tr()}: ${s['code']}",
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: getSecondaryTextColor(context))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniInfo(Icons.calendar_today_rounded, 'start_date'.tr(),
                  s['start_date']?.toString() ?? "—"),
              const SizedBox(width: 10),
              _miniInfo(Icons.event_available_rounded, 'end_date'.tr(),
                  s['end_date']?.toString() ?? "—"),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _miniInfo(Icons.menu_book_rounded, 'courses'.tr(), "$coursesCount"),
              const SizedBox(width: 10),
              if (!isActive)
                Expanded(
                  child: ScaleButton(
                    onTap: () => _setActive(s['id'].toString()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.darkBlue]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text('set_as_current'.tr(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text('current_semester_marker'.tr(),
                          style: const TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: getSecondaryTextColor(context)),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.poppins(
                          fontSize: 9, color: getSecondaryTextColor(context))),
                  Text(value,
                      style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color));
  }
}

class _CreateSemesterSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateSemesterSheet({required this.onCreated});

  @override
  State<_CreateSemesterSheet> createState() => _CreateSemesterSheetState();
}

class _CreateSemesterSheetState extends State<_CreateSemesterSheet> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _setActive = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (start) _startDate = picked;
        else _endDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (_name.text.isEmpty || _code.text.isEmpty) {
      _snack('name_code_required'.tr());
      return;
    }
    setState(() => _saving = true);
    final res = await ApiService.createSemester(
      name: _name.text.trim(),
      code: _code.text.trim().toUpperCase(),
      startDate: _startDate?.toIso8601String().split('T').first,
      endDate: _endDate?.toIso8601String().split('T').first,
      isActive: _setActive,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (res['status'] == 'success') {
      Navigator.pop(context);
      widget.onCreated();
    } else {
      _snack(res['message'] ?? 'update_failed'.tr());
    }
  }

  void _snack(String s) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: getCardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('new_semester'.tr(),
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 18),
            _input(_name, 'semester_name'.tr(), '', Icons.label_outline),
            const SizedBox(height: 12),
            _input(_code, 'semester_code'.tr(), '', Icons.tag_rounded),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _dateField('start_date'.tr(), _startDate, () => _pickDate(start: true))),
                const SizedBox(width: 10),
                Expanded(child: _dateField('end_date'.tr(), _endDate, () => _pickDate(start: false))),
              ],
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('set_active'.tr(),
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text('set_active_subtitle'.tr(),
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: getSecondaryTextColor(context))),
              value: _setActive,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _setActive = v),
            ),
            const SizedBox(height: 10),
            ScaleButton(
              onTap: _saving ? () {} : _save,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.darkBlue]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : Text('create_semester'.tr(),
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, String label, String hint, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: TextField(
            controller: c,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                  fontSize: 12, color: getSecondaryTextColor(context)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateField(String label, DateTime? value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Text(
                  value == null
                      ? "—"
                      : "${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}",
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}