import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppIcons {
  AppIcons._();

  static const String _base = 'assets/icons/';

  // Navigation & Header
  static const String profile = '${_base}profile.png';
  static const String user = '${_base}user.png';
  static const String settings = '${_base}settings.png';
  static const String logout = '${_base}logout.png';
  static const String notification = '${_base}notification-bell.png';
  static const String search = '${_base}search.png';

  // Dashboard & Statistics
  static const String dashboard = '${_base}dashboard.png';
  static const String book = '${_base}book.png';
  static const String education = '${_base}education.png';
  static const String business = '${_base}business.png';
  static const String event = '${_base}event.png';

  // AI & Lectures
  static const String microchip = '${_base}microchip.png';
  static const String pdf = '${_base}pdf.png';
  static const String upload = '${_base}upload.png';

  // Quiz & Results
  static const String checkMark = '${_base}check-mark.png';
  static const String warning = '${_base}warning.png';

  // Users & Roles
  static const String teacher = '${_base}teacher.png';
  static const String community = '${_base}community.png';
  static const String deskChair = '${_base}desk-chair.png';

  // Actions
  static const String delete = '${_base}delete.png';
}

class AppIconImage extends StatelessWidget {
  final String path;
  final double size;
  final Color? color;

  const AppIconImage(this.path, {super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    if (color != null) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
        child: Image.asset(
          path,
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      );
    }
    return Image.asset(path, width: size, height: size, fit: BoxFit.contain);
  }
}

class AppIconButton3D extends StatelessWidget {
  final String iconPath;
  final Color bgColor;
  final VoidCallback onTap;
  final double iconSize;
  final double padding;

  const AppIconButton3D({
    super.key,
    required this.iconPath,
    required this.bgColor,
    required this.onTap,
    this.iconSize = 26,
    this.padding = 8,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: bgColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: bgColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AppIconImage(iconPath, size: iconSize),
      ),
    );
  }
}

class AppStatCard3D extends StatelessWidget {
  final String value;
  final String label;
  final String iconPath;
  final Color color;
  final bool centerAlign;
  final double iconSize;

  const AppStatCard3D({
    super.key,
    required this.value,
    required this.label,
    required this.iconPath,
    required this.color,
    this.centerAlign = false,
    this.iconSize = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.14), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            centerAlign ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppIconImage(iconPath, size: iconSize),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: centerAlign ? TextAlign.center : TextAlign.start,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class AppMiniBadge3D extends StatelessWidget {
  final String label;
  final String iconPath;
  final Color color;
  final double iconSize;
  final double fontSize;

  const AppMiniBadge3D({
    super.key,
    required this.label,
    required this.iconPath,
    required this.color,
    this.iconSize = 13,
    this.fontSize = 9.5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconImage(iconPath, size: iconSize),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  final String iconPath;
  final String title;
  final Color color;
  final Widget? trailing;

  const AppSectionHeader({
    super.key,
    required this.iconPath,
    required this.title,
    required this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: AppIconImage(iconPath, size: 22),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class AppLogoutDialog {
  AppLogoutDialog._();

  static void show(
    BuildContext context, {
    required VoidCallback onConfirm,
    String title = 'تسجيل الخروج',
    String message = 'هل أنت متأكد من الخروج؟',
    String cancelText = 'إلغاء',
    String confirmText = 'خروج',
  }) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                AppIconImage(AppIcons.logout, size: 28),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(message, style: GoogleFonts.poppins(fontSize: 14)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(cancelText),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm();
                },
                child: Text(
                  confirmText,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}

class AppActionCard3D extends StatelessWidget {
  final String label;
  final String iconPath;
  final Color color;
  final VoidCallback onTap;

  const AppActionCard3D({
    super.key,
    required this.label,
    required this.iconPath,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: AppIconImage(iconPath, size: 38),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
