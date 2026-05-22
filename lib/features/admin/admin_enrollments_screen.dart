import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminEnrollmentsScreen extends StatefulWidget {
  const AdminEnrollmentsScreen({super.key});
  @override
  State<AdminEnrollmentsScreen> createState() => _AdminEnrollmentsScreenState();
}

class _AdminEnrollmentsScreenState extends State<AdminEnrollmentsScreen> {
  String? _selectedStudent;
  String? _selectedCourse;
  List<dynamic> _students = [];
  List<dynamic> _courses = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    try {
      final users = await ApiService.getUsers();
      final coursesRes = await http.get(Uri.parse('${ApiService.baseUrl}/admin/get_courses.php'));
      final coursesData = json.decode(coursesRes.body)['data'];
      setState(() {
        _students = users.where((u) => u['role'] == 'student').toList();
        _courses = coursesData;
        _isLoading = false;
      });
    } catch (e) { setState(() => _isLoading = false); }
  }

  Future<void> _handleEnroll() async {
    if (_selectedStudent == null || _selectedCourse == null) return;
    setState(() => _isSubmitting = true);
    final res = await ApiService.enrollStudent(_selectedStudent!, _selectedCourse!);
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("تسجيل الطلاب", style: GoogleFonts.poppins())),
      body: AppBackground(
        child: _isLoading ? const Center(child: CircularProgressIndicator()) : Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            _buildDropdown(_students, _selectedStudent, "اختر الطالب", (v) => setState(() => _selectedStudent = v)),
            const SizedBox(height: 20),
            _buildDropdown(_courses, _selectedCourse, "اختر المادة", (v) => setState(() => _selectedCourse = v)),
            const Spacer(),
            ScaleButton(
              onTap: _isSubmitting ? () {} : _handleEnroll,
              child: Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.darkBlue]), borderRadius: BorderRadius.circular(15)),
                child: Center(child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text("إتمام التسجيل", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildDropdown(List items, String? val, String hint, Function(String?) onChange) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: getCardColor(context), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.withOpacity(0.2))),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: val, isExpanded: true, hint: Text(hint), items: items.map((i) => DropdownMenuItem<String>(value: i['id'].toString(), child: Text(i['full_name'] ?? i['title']))).toList(), onChanged: onChange)));
  }
}