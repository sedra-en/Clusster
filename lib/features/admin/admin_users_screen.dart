import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/api_service.dart';
import 'package:cluster_app/models/app_user.dart';
import 'package:cluster_app/features/admin/admin_user_details_screen.dart';
import 'package:cluster_app/features/admin/admin_create_user_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<AppUser> _all = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.getUsers();
      if (mounted) {
        setState(() {
          _all = list.map((u) => AppUser.fromMap(u)).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<AppUser> get _filtered {
    switch (_filter) {
      case 'student':
        return _all.where((u) => u.role == UserRole.student).toList();
      case 'instructor':
        return _all.where((u) => u.role == UserRole.instructor).toList();
      case 'active':
        return _all.where((u) => u.status == UserStatus.active).toList();
      case 'pending':
        return _all.where((u) => u.status == UserStatus.pending).toList();
      case 'blocked':
        return _all.where((u) => u.status == UserStatus.blocked).toList();
      default:
        return _all;
    }
  }

  Future<void> _quickToggle(AppUser user) async {
    final newStatus = user.status == UserStatus.active ? 'blocked' : 'active';
    final res = await ApiService.updateUserStatus(user.id, newStatus);
    if (!mounted) return;
    if (res['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus == 'active' ? 'user_activated'.tr() : 'user_blocked'.tr()),
          backgroundColor: newStatus == 'active' ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'update_failed'.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('manage_users'.tr(), style: GoogleFonts.poppins()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildFilterBar(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: _filtered.isEmpty
                            ? _emptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 5, 20, 90),
                                itemCount: _filtered.length,
                                itemBuilder: (_, i) => _userCard(_filtered[i]),
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const AdminCreateUserScreen(defaultRole: UserRole.student)),
        ).then((_) => _load()),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      ('all', 'all'.tr(), _all.length),
      ('student', 'students'.tr(), _all.where((u) => u.role == UserRole.student).length),
      ('instructor', 'instructors'.tr(), _all.where((u) => u.role == UserRole.instructor).length),
      ('active', 'active'.tr(), _all.where((u) => u.status == UserStatus.active).length),
      ('pending', 'pending'.tr(), _all.where((u) => u.status == UserStatus.pending).length),
      ('blocked', 'blocked'.tr(), _all.where((u) => u.status == UserStatus.blocked).length),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: filters.map((f) {
          final selected = _filter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filter = f.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(selected ? 1 : 0.2)),
                ),
                child: Text(
                  "${f.$2} (${f.$3})",
                  style: GoogleFonts.poppins(
                    color: selected ? Colors.white : AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _emptyState() {
    return ListView(children: [
      const SizedBox(height: 100),
      Icon(Icons.people_outline,
          size: 80, color: getSecondaryTextColor(context).withOpacity(0.3)),
      const SizedBox(height: 15),
      Center(
        child: Text('no_users_filter'.tr(),
            style: GoogleFonts.poppins(color: getSecondaryTextColor(context))),
      ),
    ]);
  }

  Widget _userCard(AppUser user) {
    final roleColor = user.role == UserRole.student ? AppColors.primary : AppColors.purple;
    final (statusColor, statusLabel) = _statusInfo(user.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: roleColor.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AdminUserDetailsScreen(user: user)),
          ).then((_) => _load()),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: roleColor.withOpacity(0.12),
                  child: Text(
                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : "?",
                    style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 3),
                      Text(user.email,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: getSecondaryTextColor(context))),
                      const SizedBox(height: 6),
                      Row(children: [
                        _chip(
                          user.role == UserRole.student ? 'student'.tr() : 'instructor'.tr(),
                          roleColor,
                        ),
                        const SizedBox(width: 6),
                        _chip(statusLabel, statusColor),
                      ]),
                    ],
                  ),
                ),
                _toggleButton(user),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggleButton(AppUser user) {
    final isActive = user.status == UserStatus.active;
    return GestureDetector(
      onTap: () => _confirmToggle(user),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isActive ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? Icons.block_rounded : Icons.check_circle_rounded,
                size: 14, color: isActive ? Colors.red : Colors.green),
            const SizedBox(width: 4),
            Text(isActive ? 'block'.tr() : 'activate'.tr(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.red : Colors.green,
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmToggle(AppUser user) async {
    final isActive = user.status == UserStatus.active;
    final confirmKey = isActive ? 'block_user_confirm' : 'activate_user_confirm';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isActive ? 'block'.tr() : 'activate'.tr()),
        content: Text("${user.fullName} — ${confirmKey.tr()}"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('cancel'.tr())),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isActive ? 'block'.tr() : 'activate'.tr(),
                style: TextStyle(color: isActive ? Colors.red : Colors.green)),
          ),
        ],
      ),
    );
    if (ok == true) _quickToggle(user);
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  (Color, String) _statusInfo(UserStatus s) {
    switch (s) {
      case UserStatus.active:
        return (Colors.green, 'active'.tr());
      case UserStatus.pending:
        return (Colors.orange, 'pending'.tr());
      case UserStatus.blocked:
        return (Colors.red, 'blocked'.tr());
    }
  }
}