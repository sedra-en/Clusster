import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/models/app_user.dart';
import 'package:cluster_app/core/api/api_service.dart';

class AdminUserDetailsScreen extends StatefulWidget {
  final AppUser user;
  const AdminUserDetailsScreen({super.key, required this.user});

  @override
  State<AdminUserDetailsScreen> createState() => _AdminUserDetailsScreenState();
}

class _AdminUserDetailsScreenState extends State<AdminUserDetailsScreen> {
  late AppUser _user;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  Future<void> _updateStatus(UserStatus newStatus) async {
    setState(() => _isUpdating = true);
    final res = await ApiService.updateUserStatus(_user.id, newStatus.name);
    if (!mounted) return;

    if (res['status'] == 'success') {
      setState(() {
        _user = AppUser(
          id: _user.id,
          fullName: _user.fullName,
          email: _user.email,
          role: _user.role,
          status: newStatus,
          isActivated: _user.isActivated,
          createdAt: _user.createdAt,
          activationCode: _user.activationCode,
          studentId: _user.studentId,
          employeeId: _user.employeeId,
        );
        _isUpdating = false;
      });
      _showSnack('status_updated'.tr(), color: Colors.green);
    } else {
      setState(() => _isUpdating = false);
      _showSnack(res['message'] ?? 'update_failed'.tr(), color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('user_profile'.tr(), style: GoogleFonts.poppins()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 25),
                _buildInfoCard(),
                const SizedBox(height: 25),
                if (!_user.isActivated && _user.activationCode != null)
                  _buildActivationSection(),
                const SizedBox(height: 30),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final color = _user.role == UserRole.student ? AppColors.primary : AppColors.purple;
    final (statusColor, statusIcon) = _statusVisuals(_user.status);
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 55,
              backgroundColor: color.withOpacity(0.1),
              child: Text(
                _user.fullName.isNotEmpty ? _user.fullName[0].toUpperCase() : "?",
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: color),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(statusIcon, color: statusColor, size: 26),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(_user.fullName,
            style: GoogleFonts.poppins(
                fontSize: 22, fontWeight: FontWeight.bold, color: getTextColor(context))),
        Text(_user.email,
            style: GoogleFonts.poppins(
                fontSize: 14, color: getSecondaryTextColor(context))),
      ],
    );
  }

  Widget _buildInfoCard() {
    return ProGlassCard(
      child: Column(
        children: [
          _infoRow(Icons.badge_outlined, 'account_type'.tr(),
              _user.role == UserRole.student ? 'student'.tr() : 'instructor'.tr()),
          _infoRow(Icons.info_outline, 'current_status'.tr(), _statusLabel(_user.status)),
          _infoRow(Icons.verified_outlined, 'self_activated'.tr(),
              _user.isActivated ? 'yes'.tr() : 'no'.tr()),
          _infoRow(Icons.calendar_today_outlined, 'join_date'.tr(),
              "${_user.createdAt.year}-${_user.createdAt.month.toString().padLeft(2, '0')}-${_user.createdAt.day.toString().padLeft(2, '0')}"),
        ],
      ),
    );
  }

  Widget _buildActivationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.vpn_key_outlined, color: Colors.orange),
              const SizedBox(width: 10),
              Text('activation_code'.tr(),
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_user.activationCode ?? "---",
                  style: GoogleFonts.poppins(
                      fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 3)),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: Colors.orange),
                onPressed: () {
                  if (_user.activationCode != null) {
                    Clipboard.setData(ClipboardData(text: _user.activationCode!));
                    _showSnack('code_copied'.tr());
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isActive = _user.status == UserStatus.active;
    final isBlocked = _user.status == UserStatus.blocked;

    return Column(
      children: [
        if (_isUpdating)
          const Padding(
            padding: EdgeInsets.all(8),
            child: LinearProgressIndicator(),
          ),
        Row(
          children: [
            Expanded(
              child: _statusButton(
                label: 'block'.tr(),
                icon: Icons.block_rounded,
                color: Colors.red,
                isCurrent: isBlocked,
                onTap: () => _updateStatus(UserStatus.blocked),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statusButton(
                label: 'pending'.tr(),
                icon: Icons.pause_circle_outline_rounded,
                color: Colors.orange,
                isCurrent: _user.status == UserStatus.pending,
                onTap: () => _updateStatus(UserStatus.pending),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statusButton(
                label: 'activate'.tr(),
                icon: Icons.check_circle_rounded,
                color: Colors.green,
                isCurrent: isActive,
                onTap: () => _updateStatus(UserStatus.active),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isCurrent,
    required VoidCallback onTap,
  }) {
    return ScaleButton(
      onTap: (_isUpdating || isCurrent) ? () {} : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isCurrent ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(isCurrent ? 1 : 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isCurrent ? Colors.white : color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isCurrent ? Colors.white : color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 15),
          Text(label, style: GoogleFonts.poppins(color: getSecondaryTextColor(context))),
          const Spacer(),
          Text(value,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, color: getTextColor(context))),
        ],
      ),
    );
  }

  String _statusLabel(UserStatus s) {
    switch (s) {
      case UserStatus.active:  return 'active'.tr();
      case UserStatus.pending: return 'pending'.tr();
      case UserStatus.blocked: return 'blocked'.tr();
    }
  }

  (Color, IconData) _statusVisuals(UserStatus s) {
    switch (s) {
      case UserStatus.active:  return (Colors.green,  Icons.check_circle);
      case UserStatus.pending: return (Colors.orange, Icons.pause_circle_filled);
      case UserStatus.blocked: return (Colors.red,    Icons.block);
    }
  }

  void _showSnack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
      ),
    );
  }
}