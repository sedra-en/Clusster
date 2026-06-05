import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cluster_app/core/app_provider.dart';

class AppColors {
  static const Color primary = Color(0xFF00BCD4);
  static const Color textDark = Color(0xFF00334E);
  static const Color textGrey = Color(0xFF546E7A);
  static const Color accent = Color(0xFF80DEEA);

  static const Color purple = Color(0xFFAB47BC);
  static const Color orange = Color(0xFFFF7043);
  static const Color darkBlue = Color(0xFF0277BD);

  static const Color glassWhite = Color(0xB3FFFFFF);

  static const Color darkBg = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
}

class AppAssets {
  static const String bgImage = 'assets/images/main_bg.jpg.jpeg';
  static const String logo = 'assets/images/logo.png';
}

// --- 🌟 Hero Logo ---
class HeroLogo extends StatelessWidget {
  final double size;
  const HeroLogo({super.key, this.size = 180});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 60,
            spreadRadius: 20,
          ),
        ],
      ),
      child: Image.asset(AppAssets.logo, fit: BoxFit.contain),
    );
  }
}

// --- Background ---
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppProvider>().isDarkMode;

    return Stack(
      children: [
        Positioned.fill(
          child:
              isDark
                  ? Container(color: AppColors.darkBg)
                  : Image.asset(
                    AppAssets.bgImage,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Container(color: Colors.white),
                  ),
        ),
        if (!isDark)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.7),
                    const Color(0xFFE0F7FA).withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),
        SafeArea(child: child),
      ],
    );
  }
}

// --- Glass Card ---
class ProGlassCard extends StatelessWidget {
  final Widget child;
  final double? width, height;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const ProGlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(24),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppProvider>().isDarkMode;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: width,
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color:
                  isDark
                      ? AppColors.darkCard.withOpacity(0.85)
                      : AppColors.glassWhite,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const ScaleButton({super.key, required this.child, required this.onTap});

  @override
  State<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<ScaleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      upperBound: 0.05,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        child: widget.child,
        builder:
            (_, child) => Transform.scale(scale: 1 - _ctrl.value, child: child),
      ),
    );
  }
}

// --- Fade In + Slide ---
class FadeInSlide extends StatelessWidget {
  final Widget child;
  final double delay;
  const FadeInSlide({super.key, required this.child, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (c, v, child) {
        final opacity = (v - delay).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - opacity)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// --- Helper Colors ---
Color getTextColor(BuildContext context) {
  final isDark = context.watch<AppProvider>().isDarkMode;
  return isDark ? Colors.white : AppColors.textDark;
}

Color getSecondaryTextColor(BuildContext context) {
  final isDark = context.watch<AppProvider>().isDarkMode;
  return isDark ? Colors.white70 : AppColors.textGrey;
}

Color getCardColor(BuildContext context) {
  final isDark = context.watch<AppProvider>().isDarkMode;
  return isDark ? AppColors.darkCard : Colors.white;
}
