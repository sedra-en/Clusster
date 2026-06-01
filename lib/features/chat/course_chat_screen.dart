import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cluster_app/shared/shared_ui.dart';
import 'package:cluster_app/core/api/chat_api.dart';
import 'package:cluster_app/core/constants/app_icons.dart';
import 'package:cluster_app/core/services/chat_notification_service.dart';
import 'package:cluster_app/features/chat/muted_students_screen.dart';

class CourseChatScreen extends StatefulWidget {
  final int courseId;
  final int userId;
  final String userName;
  final String userRole;
  final String courseTitle;
  final Color color;

  const CourseChatScreen({
    super.key,
    required this.courseId,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.courseTitle,
    required this.color,
  });

  @override
  State<CourseChatScreen> createState() => _CourseChatScreenState();
}

class _CourseChatScreenState extends State<CourseChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  List<dynamic> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _muted = false;
  int _lastMessageId = 0;

  http.Client? _sseClient;
  StreamSubscription? _sseSubscription;
  bool _sseConnected = false;
  Timer? _pollingFallbackTimer;
  String _sseBuffer = '';

  // ✅ علامة للتحقق هل الـ widget لسا حي
  bool _isDisposed = false;

  bool get _isInstructor => widget.userRole == 'instructor';

  @override
  void initState() {
    super.initState();
    ChatNotificationService.pauseForChat();
    _loadInitialMessages();
    _markAsRead();
  }

  @override
  void dispose() {
    _isDisposed = true; // ✅ نضع العلامة قبل أي شي
    _sseSubscription?.cancel();
    _sseSubscription = null;
    _sseClient?.close();
    _sseClient = null;
    _pollingFallbackTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    ChatNotificationService.resumeFromChat();
    super.dispose();
  }

  // ✅ helper آمن للـ setState
  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  Future<void> _loadInitialMessages() async {
    _safeSetState(() => _loading = true);
    final messages = await ChatApi.getMessages(
      courseId: widget.courseId,
      userId: widget.userId,
    );
    if (_isDisposed || !mounted) return;
    _safeSetState(() {
      _messages = messages;
      _loading = false;
      if (messages.isNotEmpty) {
        _lastMessageId = messages.last['id'];
      }
    });
    _scrollToBottom();
    _connectSSE();
  }

  Future<void> _connectSSE() async {
    if (_isDisposed) return;
    _disconnectSSE();
    try {
      _sseClient = http.Client();
      final uri = Uri.parse(ChatApi.streamUrl(
        courseId: widget.courseId,
        userId: widget.userId,
        lastId: _lastMessageId,
      ));

      final request = http.Request('GET', uri);
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      final response = await _sseClient!.send(request);
      if (_isDisposed) return;

      _sseSubscription = response.stream.transform(utf8.decoder).listen(
        _onSSEData,
        onError: (e) {
          print('🔴 SSE Error: $e');
          if (!_isDisposed) _activatePollingFallback();
        },
        onDone: () {
          if (!_isDisposed && mounted) {
            Future.delayed(const Duration(seconds: 2), () {
              if (!_isDisposed && mounted) _connectSSE();
            });
          }
        },
        cancelOnError: false,
      );

      _safeSetState(() => _sseConnected = true);
      _pollingFallbackTimer?.cancel();
    } catch (e) {
      if (!_isDisposed) _activatePollingFallback();
    }
  }

  // ✅ بدون setState — للاستخدام داخل dispose
  void _disconnectSSE() {
    _sseSubscription?.cancel();
    _sseSubscription = null;
    _sseClient?.close();
    _sseClient = null;
    _safeSetState(() => _sseConnected = false);
  }

  void _onSSEData(String chunk) {
    if (_isDisposed) return;
    _sseBuffer += chunk;
    final events = _sseBuffer.split('\n\n');
    _sseBuffer = events.removeLast();
    for (final raw in events) {
      _parseSSEEvent(raw);
    }
  }

  void _parseSSEEvent(String raw) {
    String? eventType;
    String? data;
    for (final line in raw.split('\n')) {
      if (line.startsWith('event:')) eventType = line.substring(6).trim();
      if (line.startsWith('data:')) data = line.substring(5).trim();
    }
    if (eventType == null || data == null) return;
    try {
      final parsed = json.decode(data);
      switch (eventType) {
        case 'message':
          _handleNewMessage(parsed);
          break;
        case 'timeout':
          _connectSSE();
          break;
      }
    } catch (_) {}
  }

  void _handleNewMessage(dynamic msg) {
    if (_isDisposed || !mounted) return;
    final msgId = msg['id'] as int;
    final existingIndex = _messages.indexWhere((m) => m['id'] == msgId);

    _safeSetState(() {
      if (existingIndex >= 0) {
        _messages[existingIndex] = msg;
      } else {
        _messages.add(msg);
      }
      if (msgId > _lastMessageId) _lastMessageId = msgId;
    });

    _scrollToBottom();
    _markAsRead();
  }

  void _activatePollingFallback() {
    if (_isDisposed) return;
    _pollingFallbackTimer?.cancel();
    _pollingFallbackTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_isDisposed) _pollNewMessages();
    });
  }

  Future<void> _pollNewMessages() async {
    if (_isDisposed || _lastMessageId == 0) return;
    try {
      final newMsgs = await ChatApi.getMessages(
        courseId: widget.courseId,
        userId: widget.userId,
        afterId: _lastMessageId,
      );
      if (_isDisposed || !mounted || newMsgs.isEmpty) return;
      for (final msg in newMsgs) {
        _handleNewMessage(msg);
      }
    } catch (_) {}
  }

  Future<void> _markAsRead() async {
    if (_isDisposed) return;
    await ChatApi.markAsRead(
      courseId: widget.courseId,
      userId: widget.userId,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed) return;
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendText() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _safeSetState(() => _sending = true);
    _msgCtrl.clear();

    final result = await ChatApi.sendMessage(
      courseId: widget.courseId,
      senderId: widget.userId,
      content: text,
    );

    if (_isDisposed || !mounted) return;
    _safeSetState(() => _sending = false);

    if (result['status'] == 'success') {
      _handleNewMessage(result['data']);
    } else {
      final msg = result['message']?.toString() ?? 'فشل الإرسال';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
      if (msg.contains('كتم') || msg.contains('🚫')) {
        _safeSetState(() => _muted = true);
      }
    }
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 80,
    );
    if (file == null) return;

    _safeSetState(() => _sending = true);
    final bytes = await file.readAsBytes();
    final result = await ChatApi.sendImage(
      courseId: widget.courseId,
      senderId: widget.userId,
      fileBytes: bytes,
      fileName: file.name,
    );

    if (_isDisposed || !mounted) return;
    _safeSetState(() => _sending = false);

    if (result['status'] == 'success') {
      _handleNewMessage(result['data']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'فشل الإرسال')),
      );
    }
  }

  Future<void> _deleteMessage(dynamic msg) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          AppIconImage(AppIcons.delete, size: 24),
          const SizedBox(width: 8),
          Text('delete_message'.tr()),
        ]),
        content: Text('delete_message_confirm'.tr()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('cancel'.tr())),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('delete'.tr(),
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await ChatApi.deleteMessage(
        messageId: msg['id'], userId: widget.userId);
    if (_isDisposed || !mounted) return;

    if (result['status'] == 'success') {
      final idx = _messages.indexWhere((m) => m['id'] == msg['id']);
      if (idx >= 0) {
        _safeSetState(() {
          _messages[idx] = Map<String, dynamic>.from(_messages[idx])
            ..['is_deleted'] = true
            ..['content'] = null
            ..['file_path'] = null
            ..['deleted_by_role'] = result['data']['deleted_by_role'];
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'فشل الحذف')),
      );
    }
  }

  Future<void> _muteStudent(dynamic msg) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          AppIconImage(AppIcons.warning, size: 24),
          const SizedBox(width: 8),
          Text('mute_student'.tr()),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('mute_student_confirm'
              .tr()
              .replaceAll('{name}', msg['sender_name'] ?? '')),
          const SizedBox(height: 12),
          TextField(
            controller: reasonCtrl,
            decoration: InputDecoration(
              hintText: 'reason_optional'.tr(),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 2,
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('cancel'.tr())),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('mute'.tr(),
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await ChatApi.muteStudent(
      courseId: widget.courseId,
      instructorUserId: widget.userId,
      studentUserId: msg['sender_id'],
      reason: reasonCtrl.text.trim(),
    );
    if (_isDisposed || !mounted) return;

    if (result['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('🚫 ${'student_muted'.tr()}'),
            backgroundColor: Colors.orange),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'فشل')),
      );
    }
  }

  void _openMutedList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MutedStudentsScreen(
          courseId: widget.courseId,
          instructorUserId: widget.userId,
          color: widget.color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(child: _buildMessagesList()),
          _buildInputBar(),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [widget.color, widget.color.withOpacity(0.75)]),
        boxShadow: [
          BoxShadow(
              color: widget.color.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 16),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10)),
          child: Image.asset('assets/icons/icons8-message.gif',
              width: 26, height: 26, fit: BoxFit.contain),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.courseTitle,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Row(children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                    color: _sseConnected
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                    shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(_sseConnected ? 'live'.tr() : 'syncing'.tr(),
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 10)),
            ]),
          ]),
        ),
        if (_isInstructor)
          GestureDetector(
            onTap: _openMutedList,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle),
              child: AppIconImage(AppIcons.warning, size: 18),
            ),
          ),
      ]),
    );
  }

  Widget _buildMessagesList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_messages.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Image.asset('assets/icons/icons8-message.gif', width: 80, height: 80),
          const SizedBox(height: 12),
          Text(
            _isInstructor
                ? 'no_messages_yet_instructor'.tr()
                : 'no_messages_yet_student'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ]),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(12),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg = _messages[i];
        final showDate = i == 0 ||
            !_isSameDay(_messages[i - 1]['created_at'], msg['created_at']);
        return Column(children: [
          if (showDate) _buildDateSeparator(msg['created_at']),
          _buildMessageBubble(msg),
        ]);
      },
    );
  }

  Widget _buildMessageBubble(dynamic msg) {
    final isMine = msg['is_mine'] == true;
    final isInstructorMsg = msg['sender_role'] == 'instructor';
    final isDeleted = msg['is_deleted'] == true;
    final type = msg['message_type'] ?? 'text';

    Color bubbleColor;
    if (isMine) {
      bubbleColor = const Color(0xFFDCF8C6);
    } else if (isInstructorMsg) {
      bubbleColor = widget.color.withOpacity(0.15);
    } else {
      bubbleColor = Colors.white;
    }

    return Align(
      alignment: isMine ? Alignment.centerLeft : Alignment.centerRight,
      child: GestureDetector(
        onLongPress: isDeleted ? null : () => _showMessageActions(msg),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(isMine ? 2 : 14),
              bottomRight: Radius.circular(isMine ? 14 : 2),
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1))
            ],
            border: isInstructorMsg && !isMine
                ? Border.all(color: widget.color.withOpacity(0.3))
                : null,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (!isMine) ...[
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (isInstructorMsg) AppIconImage(AppIcons.teacher, size: 13),
                if (isInstructorMsg) const SizedBox(width: 3),
                Text(msg['sender_name'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color:
                          isInstructorMsg ? widget.color : Colors.grey[700],
                    )),
              ]),
              const SizedBox(height: 3),
            ],
            if (isDeleted)
              _buildDeletedContent(msg)
            else if (type == 'image')
              _buildImageContent(msg)
            else
              Text(msg['content'] ?? '', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 3),
            Row(mainAxisSize: MainAxisSize.min, children: [
              if (msg['is_edited'] == true && !isDeleted) ...[
                Text('edited'.tr(),
                    style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic)),
                const SizedBox(width: 4),
              ],
              Text(_formatTime(msg['created_at']),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600])),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildDeletedContent(dynamic msg) {
    final by = msg['deleted_by_role'];
    final text = by == 'instructor'
        ? '🗑️ ${'msg_deleted_by_instructor'.tr()}'
        : '🗑️ ${'msg_deleted'.tr()}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(text,
          style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: Colors.grey[600])),
    );
  }

  Widget _buildImageContent(dynamic msg) {
    final filePath = msg['file_path'];
    if (filePath == null) return const SizedBox.shrink();
    final url = ChatApi.imageUrl(filePath);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(url, width: 220, fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
            width: 220,
            height: 180,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()));
      }, errorBuilder: (_, __, ___) => Container(
              width: 220,
              height: 180,
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image,
                  size: 40, color: Colors.grey))),
    );
  }

  Widget _buildDateSeparator(dynamic timestamp) {
    final label = _formatDateLabel(timestamp);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12)),
      child:
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
    );
  }

  Widget _buildInputBar() {
    if (_muted) {
      return Container(
        padding: const EdgeInsets.all(12),
        color: Colors.red.withOpacity(0.08),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          AppIconImage(AppIcons.warning, size: 20),
          const SizedBox(width: 8),
          Text('🚫 ${'you_are_muted'.tr()}',
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold)),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(children: [
        GestureDetector(
          onTap: _sending ? null : _sendImage,
          child: Container(
              padding: const EdgeInsets.all(8),
              child: AppIconImage(AppIcons.upload, size: 22)),
        ),
        Expanded(
          child: TextField(
            controller: _msgCtrl,
            maxLines: null,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: 'type_message'.tr(),
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: _sending ? null : _sendText,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: widget.color.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
            ),
            child: _sending
                ? const Center(
                    child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)))
                : const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }

  void _showMessageActions(dynamic msg) {
    final isMine = msg['is_mine'] == true;
    final isStudentMsg = msg['sender_role'] == 'student';
    final canDelete = isMine || (_isInstructor && isStudentMsg);
    final canMute = _isInstructor && isStudentMsg && !isMine;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
                color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          if (canDelete)
            ListTile(
              leading: AppIconImage(AppIcons.delete, size: 24),
              title: Text('delete'.tr()),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(msg);
              },
            ),
          if (canMute)
            ListTile(
              leading: AppIconImage(AppIcons.warning, size: 24),
              title: Text('mute_this_student'.tr()),
              onTap: () {
                Navigator.pop(context);
                _muteStudent(msg);
              },
            ),
          if (!canDelete && !canMute)
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.grey),
              title: Text('no_actions_available'.tr()),
              onTap: () => Navigator.pop(context),
            ),
        ]),
      ),
    );
  }

  bool _isSameDay(dynamic t1, dynamic t2) {
    try {
      final d1 = DateTime.parse(t1.toString()).toLocal();
      final d2 = DateTime.parse(t2.toString()).toLocal();
      return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
    } catch (_) {
      return false;
    }
  }

  String _formatTime(dynamic timestamp) {
    try {
      final dt = DateTime.parse(timestamp.toString()).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  String _formatDateLabel(dynamic timestamp) {
    try {
      final dt = DateTime.parse(timestamp.toString()).toLocal();
      final now = DateTime.now();
      if (_isSameDay(now.toIso8601String(), timestamp)) return 'today'.tr();
      if (now.difference(dt).inDays == 1) return 'yesterday'.tr();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}