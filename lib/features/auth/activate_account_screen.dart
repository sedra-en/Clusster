import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';

class ActivateAccountScreen extends StatefulWidget {
  const ActivateAccountScreen({super.key});

  @override
  State<ActivateAccountScreen> createState() => _ActivateAccountScreenState();
}

class _ActivateAccountScreenState extends State<ActivateAccountScreen> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isVerified = false;
  Map<String, dynamic>? _verifiedUserData;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_emailCtrl.text.isEmpty || _codeCtrl.text.isEmpty) {
      _snack('fill_all_fields'.tr());
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.verifyCode(
        _emailCtrl.text.trim(),
        _codeCtrl.text.trim().toUpperCase(),
      );
      if (response['status'] == 'success') {
        setState(() {
          _isVerified = true;
          _verifiedUserData = response['data'];
        });
      } else {
        _snack(response['message']);
      }
    } catch (e) {
      _snack('server_connection_failed'.tr());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _activate() async {
    if (_passCtrl.text.length < 6) {
      _snack('password_min_length'.tr());
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      _snack('passwords_dont_match'.tr());
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.activateAccount(
        _verifiedUserData!['id'].toString(),
        _passCtrl.text,
      );
      if (response['status'] == 'success') {
        _successDialog();
      } else {
        _snack(response['message']);
      }
    } catch (e) {
      _snack('activation_failed'.tr());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleBack() {
    if (_isVerified) {
      setState(() {
        _isVerified = false;
        _verifiedUserData = null;
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // زر الرجوع في الأعلى
              Padding(
                padding: const EdgeInsets.only(top: 10, left: 10),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: _handleBack,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      FadeInSlide(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.darkBlue,
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.vpn_key_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'activate_account'.tr(),
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: getTextColor(context),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isVerified
                                  ? 'hello_name_set_password'.tr(
                                    namedArgs: {
                                      'name': _verifiedUserData!['full_name'],
                                    },
                                  )
                                  : 'enter_activation_details'.tr(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: getSecondaryTextColor(context),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 35),
                      _steps(),
                      const SizedBox(height: 30),
                      ProGlassCard(
                        child: _isVerified ? _passForm() : _verifyForm(),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _steps() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _step(1, 'step_verify'.tr(), true),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.only(bottom: 20, left: 5, right: 5),
            color:
                _isVerified ? AppColors.primary : Colors.grey.withOpacity(0.3),
          ),
        ),
        _step(2, 'step_password'.tr(), _isVerified),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.only(bottom: 20, left: 5, right: 5),
            color: Colors.grey.withOpacity(0.3),
          ),
        ),
        _step(3, 'step_done'.tr(), false),
      ],
    );
  }

  Widget _step(int n, String label, bool active) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.grey.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              "$n",
              style: GoogleFonts.poppins(
                color: active ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: active ? AppColors.primary : Colors.grey,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _verifyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'step_1_verify'.tr(),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: getTextColor(context),
          ),
        ),
        const SizedBox(height: 20),
        _field(
          'email'.tr(),
          'given_email'.tr(),
          Icons.email_outlined,
          _emailCtrl,
        ),
        const SizedBox(height: 15),
        _field(
          'activation_code'.tr(),
          'example_code'.tr(),
          Icons.key_rounded,
          _codeCtrl,
        ),
        const SizedBox(height: 25),
        ScaleButton(
          onTap: _isLoading ? () {} : _verify,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
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
                      : Text(
                        'verify_btn'.tr(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _passForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'step_2_password'.tr(),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: getTextColor(context),
          ),
        ),
        const SizedBox(height: 20),
        _field(
          'new_password'.tr(),
          'min_6_chars'.tr(),
          Icons.lock_outline_rounded,
          _passCtrl,
          isPass: true,
        ),
        const SizedBox(height: 15),
        _field(
          'confirm_password'.tr(),
          're_enter'.tr(),
          Icons.lock_rounded,
          _confirmCtrl,
          isPass: true,
        ),
        const SizedBox(height: 25),
        ScaleButton(
          onTap: _isLoading ? () {} : _activate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.green, Color(0xFF2E7D32)],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child:
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                        'activate_btn'.tr(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    String hint,
    IconData icon,
    TextEditingController c, {
    bool isPass = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: getSecondaryTextColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: getCardColor(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: TextField(
            controller: c,
            obscureText: isPass,
            style: GoogleFonts.poppins(color: getTextColor(context)),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.primary),
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                color: getSecondaryTextColor(context),
                fontSize: 13,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _successDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'activated_success'.tr(),
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'login_now_msg'.tr(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 25),
                ScaleButton(
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.darkBlue],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'login_btn'.tr(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
