import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';
import 'package:cluster_app/features/student/dashboard_screen.dart';
import 'package:cluster_app/features/instructor/instructor_dashboard.dart';
import 'package:cluster_app/features/admin/admin_dashboard_screen.dart';
import 'package:cluster_app/features/auth/activate_account_screen.dart';

class UnifiedLoginScreen extends StatefulWidget {
  const UnifiedLoginScreen({super.key});

  @override
  State<UnifiedLoginScreen> createState() => _UnifiedLoginScreenState();
}

class _UnifiedLoginScreenState extends State<UnifiedLoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePass = true;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final pass = _passController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      _showSnack('fill_fields'.tr());
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.login(email, pass);

      if (response['status'] == 'success') {
        final userData = response['data'];
        final String role = userData['role'];
        final String userId = userData['id'].toString();

        if (mounted) {
          Widget next;

          if (role == 'admin') {
            next = const AdminDashboardScreen();
          } else if (role == 'instructor') {
            next = InstructorDashboard(userId: userId);
          } else {
            next = DashboardScreen(userId: userId);
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => next),
          );
        }
      } else {
        _showSnack('invalid_auth'.tr());
      }
    } catch (e) {
      _showSnack("connection_error".tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AppBackground(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const FadeInSlide(
                  delay: 0.0,
                  child: Hero(tag: 'logo', child: HeroLogo(size: 250)),
                ),
                const SizedBox(height: 40),
                FadeInSlide(
                  delay: 0.2,
                  child: ProGlassCard(
                    width: size.width > 500 ? 420 : size.width * 0.9,
                    child: Column(
                      children: [
                        _buildEmailField(),

                        const SizedBox(height: 15),

                        _buildPasswordField(),

                        const SizedBox(height: 25),

                        _buildLoginButton(),

                        const SizedBox(height: 20),

                        _buildActivateButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: _inputDecoration(),
      child: TextField(
        controller: _emailController,
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: Image.asset(
              "assets/icons/icons8-email-100.png",
              width: 22,
              height: 22,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          hintText: 'email'.tr(),
          hintStyle: GoogleFonts.poppins(fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(15),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: _inputDecoration(),
      child: TextField(
        controller: _passController,
        obscureText: _obscurePass,
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: Image.asset(
              "assets/icons/icons8-password-50.png",
              width: 22,
              height: 22,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePass
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: AppColors.primary,
            ),
            onPressed: () => setState(() => _obscurePass = !_obscurePass),
          ),
          hintText: 'password'.tr(),
          hintStyle: GoogleFonts.poppins(fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(15),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return ScaleButton(
      onTap: _isLoading ? () {} : _login,
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.darkBlue],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child:
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                    'login'.tr(),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildActivateButton() {
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ActivateAccountScreen()),
          ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              'activate_new_account'.tr(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _inputDecoration() {
    return BoxDecoration(
      color: getCardColor(context),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.grey.withOpacity(0.2)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
