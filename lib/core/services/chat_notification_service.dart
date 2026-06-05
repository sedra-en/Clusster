import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cluster_app/core/app_keys.dart';
import 'package:cluster_app/core/api/api_service.dart';
import 'package:cluster_app/core/api/chat_api.dart';
import 'package:cluster_app/features/chat/course_chat_screen.dart';

class ChatNotificationService {
  ChatNotificationService._();

  static Timer? _timer;
  static int? _userId;
  static String? _userName;
  static String? _userRole;
  static bool _running = false;
  static bool _paused = false;
  static Map<String, int> _lastCounts = {};
  static List<Map<String, dynamic>> _courses = [];

  static OverlayEntry? _overlayEntry;
  static Timer? _overlayTimer;

  static Future<void> start({
    required String userId,
    required String userName,
    required String userRole,
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    final uid = int.tryParse(userId) ?? 0;
    if (uid == 0) return;

    if (_running && _userId == uid) {
      print(' Already running for user $userId — skip');
      return;
    }

    if (_running) {
      _timer?.cancel();
      _timer = null;
      _running = false;
    }

    _userId = uid;
    _userName = userName;
    _userRole = userRole;
    _running = true;
    _paused = false;
    _lastCounts = {};

    print('▶️ ChatNotification started for user $userId ($userRole)');

    await _loadCourses();
    await _snapCurrentCounts();

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_paused) _check();
    });
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
    _userId = null;
    _courses = [];
    _lastCounts = {};
    _removeOverlay();
    print(' ChatNotification stopped');
  }

  static void pauseForChat() {
    _paused = true;
    _removeOverlay();
    print(' ChatNotification paused');
  }

  static void resumeFromChat() {
    _paused = false;
    Future.delayed(const Duration(milliseconds: 500), _snapCurrentCounts);
    print(' ChatNotification resumed');
  }

  static Future<void> _loadCourses() async {
    if (_userId == null) return;
    try {
      List<dynamic> raw = [];
      if (_userRole == 'student') {
        raw = await ApiService.getStudentEnrolledCourses(_userId.toString());
      } else {
        raw = await ApiService.getInstructorCoursesByUser(_userId.toString());
      }
      _courses =
          raw
              .map(
                (c) => {
                  'id': int.tryParse(c['id'].toString()) ?? 0,
                  'title': c['title']?.toString() ?? '',
                  'color': c['cover_color']?.toString() ?? '#6C63FF',
                },
              )
              .where((c) => c['id'] != 0)
              .toList();
      print(' Loaded ${_courses.length} courses');
    } catch (e) {
      print(' _loadCourses: $e');
    }
  }

  static Future<void> _snapCurrentCounts() async {
    if (_userId == null) return;
    try {
      final data = await ChatApi.getUnreadCounts(_userId!);
      final perCourse = data['per_course'];
      if (perCourse is Map) {
        perCourse.forEach((k, v) {
          _lastCounts[k.toString()] =
              (v is int) ? v : int.tryParse(v.toString()) ?? 0;
        });
      }
      print(' Snapshot: $_lastCounts');
    } catch (e) {
      print(' _snap: $e');
    }
  }

  static Future<void> _check() async {
    if (!_running || _userId == null || _paused) return;
    try {
      final data = await ChatApi.getUnreadCounts(_userId!);
      final perCourse = data['per_course'];
      if (perCourse is! Map || perCourse.isEmpty) return;

      perCourse.forEach((courseIdRaw, countRaw) {
        final courseIdStr = courseIdRaw.toString();
        final newCount =
            (countRaw is int)
                ? countRaw
                : int.tryParse(countRaw.toString()) ?? 0;
        final oldCount = _lastCounts[courseIdStr] ?? 0;

        if (newCount > oldCount) {
          final diff = newCount - oldCount;
          print(' New in course $courseIdStr: +$diff');
          _lastCounts[courseIdStr] = newCount;
          _fetchAndShow(int.tryParse(courseIdStr) ?? 0, diff);
        }
      });
    } catch (e) {
      print(' _check: $e');
    }
  }

  static Future<void> _fetchAndShow(int courseId, int count) async {
    if (courseId == 0) return;
    try {
      final messages = await ChatApi.getMessages(
        courseId: courseId,
        userId: _userId!,
        limit: 1,
      );
      if (messages.isEmpty) return;

      final msg = messages.last;
      final senderId = msg['sender_id'];
      if (senderId == _userId || senderId.toString() == _userId.toString())
        return;

      final course = _courses.firstWhere(
        (c) => c['id'] == courseId,
        orElse: () => {'id': courseId, 'title': 'المقرر', 'color': '#6C63FF'},
      );

      _showOverlay(msg, course, count);
    } catch (e) {
      print(' _fetchAndShow: $e');
    }
  }

  static void _removeOverlay() {
    _overlayTimer?.cancel();
    _overlayTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  static void _showOverlay(
    Map<String, dynamic> msg,
    Map<String, dynamic> course,
    int count,
  ) {
    // احصل على الـ overlay من الـ navigator مباشرة
    final overlay = appNavigatorKey.currentState?.overlay;
    if (overlay == null) {
      print(' No overlay available');
      return;
    }

    final senderName = msg['sender_name']?.toString() ?? 'مستخدم';
    final isInstructor = msg['sender_role']?.toString() == 'instructor';
    final courseTitle = course['title']?.toString() ?? '';
    final courseId = course['id'] as int;
    final color = _parseColor(course['color']?.toString());
    final type = msg['message_type']?.toString() ?? 'text';
    final content = msg['content']?.toString() ?? '';
    final preview =
        type == 'image'
            ? ' صورة'
            : content.length > 55
            ? '${content.substring(0, 55)}...'
            : content;
    final countLabel = count > 1 ? ' (+$count)' : '';

    print(' Showing overlay: $senderName → $courseTitle');

    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder:
          (context) => _NotificationOverlay(
            senderName: '$senderName$countLabel',
            courseTitle: courseTitle,
            preview: preview,
            color: color,
            isInstructor: isInstructor,
            onTap: () {
              _removeOverlay();
              _openChat(courseId, courseTitle, color);
            },
            onClose: _removeOverlay,
          ),
    );

    overlay.insert(_overlayEntry!);
    print(' Overlay shown!');

    _overlayTimer = Timer(const Duration(seconds: 5), _removeOverlay);
  }

  static void _openChat(int courseId, String courseTitle, Color color) {
    if (_userId == null) return;
    appNavigatorKey.currentState?.push(
      MaterialPageRoute(
        builder:
            (_) => CourseChatScreen(
              courseId: courseId,
              userId: _userId!,
              userName: _userName ?? 'User',
              userRole: _userRole ?? 'student',
              courseTitle: courseTitle,
              color: color,
            ),
      ),
    );
  }

  static Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF6C63FF);
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xff')));
    } catch (_) {
      return const Color(0xFF6C63FF);
    }
  }
}

class _NotificationOverlay extends StatefulWidget {
  final String senderName;
  final String courseTitle;
  final String preview;
  final Color color;
  final bool isInstructor;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _NotificationOverlay({
    required this.senderName,
    required this.courseTitle,
    required this.preview,
    required this.color,
    required this.isInstructor,
    required this.onTap,
    required this.onClose,
  });

  @override
  State<_NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<_NotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      left: 12,
      right: 12,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.color, widget.color.withOpacity(0.85)],
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // أيقونة
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/icons/icons8-message.gif',
                          width: 28,
                          height: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // النص
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              if (widget.isInstructor) ...[
                                const Icon(
                                  Icons.school_rounded,
                                  color: Colors.white,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Flexible(
                                child: Text(
                                  widget.senderName,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ' ${widget.courseTitle}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.preview,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // زر إغلاق
                    GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
