import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/models/app_user.dart';
import 'package:cluster_app/core/api/api_service.dart';

class AdminCreateUserScreen extends StatefulWidget {
  final UserRole defaultRole;
  const AdminCreateUserScreen({super.key, required this.defaultRole});

  @override
  State<AdminCreateUserScreen> createState() => _AdminCreateUserScreenState();
}

class _AdminCreateUserScreenState extends State<AdminCreateUserScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _idController = TextEditingController();
  final _facultyController = TextEditingController();

  late UserRole _selectedRole;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.defaultRole;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _idController.dispose();
    _facultyController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateUser() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      _showSnack("يرجى ملء البيانات الأساسية");
      return;
    }

    setState(() => _isLoading = true);

    // تجهيز البيانات للإرسال
    final userData = {
      "full_name": _nameController.text.trim(),
      "email": _emailController.text.trim(),
      "role": _selectedRole.name, // سيُرسل 'student' أو 'instructor'
      "id_num": _idController.text.trim(),
      "faculty": _facultyController.text.trim(),
    };

    try {
      // استدعاء الباك إيند
      final result = await ApiService.createUser(userData);

      if (result['status'] == 'success') {
        // جلب كود التفعيل الحقيقي الذي أنشأه السيرفر
        final realCode = result['data']['activation_code'];
        _showSuccessDialog(realCode);
      } else {
        _showSnack(result['message'] ?? "حدث خطأ أثناء الإنشاء");
      }
    } catch (e) {
      _showSnack("فشل الاتصال بالسيرفر");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("إضافة مستخدم جديد", style: GoogleFonts.poppins()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildRoleSelector(),
                const SizedBox(height: 25),
                _buildForm(),
                const SizedBox(height: 30),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          _roleOption("طالب", UserRole.student),
          _roleOption("مدرس", UserRole.instructor),
        ],
      ),
    );
  }

  Widget _roleOption(String label, UserRole role) {
    bool isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return ProGlassCard(
      child: Column(
        children: [
          _buildField("الاسم الكامل", Icons.person_outline, _nameController),
          const SizedBox(height: 15),
          _buildField(
            "البريد الإلكتروني",
            Icons.email_outlined,
            _emailController,
          ),
          const SizedBox(height: 15),
          _buildField(
            _selectedRole == UserRole.student
                ? "الرقم الجامعي"
                : "الرقم الوظيفي",
            Icons.badge_outlined,
            _idController,
          ),
          const SizedBox(height: 15),
          _buildField(
            _selectedRole == UserRole.student
                ? "الكلية / التخصص"
                : "القسم العلمي",
            Icons.account_balance_outlined,
            _facultyController,
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String hint,
    IconData icon,
    TextEditingController controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: getTextColor(context)),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.primary),
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(15),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ScaleButton(
      onTap: _isLoading ? () {} : _handleCreateUser,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.darkBlue],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child:
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                    "حفظ المستخدم في القاعدة",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
        ),
      ),
    );
  }

  void _showSuccessDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            title: const Text("تم الحفظ في MySQL"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 50),
                const SizedBox(height: 10),
                Text("تم إضافة المستخدم بنجاح. كود التفعيل هو:"),
                const SizedBox(height: 10),
                Text(
                  code,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text("إغلاق"),
              ),
            ],
          ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
