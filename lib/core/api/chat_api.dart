import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cluster_app/core/api/api_service.dart';

class ChatApi {
  ChatApi._();

  static String get _base => '${ApiService.baseUrl}/chat';

  static Map<String, String> get _headers => {
        "Content-Type": "application/json",
        "Accept": "application/json",
      };

  // ============================================================
  // 1) جلب الرسائل
  // ============================================================
  static Future<List<dynamic>> getMessages({
    required int courseId,
    required int userId,
    int? beforeId,
    int? afterId,
    int limit = 50,
  }) async {
    try {
      final params = {
        'course_id': courseId.toString(),
        'user_id': userId.toString(),
        'limit': limit.toString(),
      };
      if (beforeId != null) params['before_id'] = beforeId.toString();
      if (afterId != null) params['after_id'] = afterId.toString();

      final uri = Uri.parse('$_base/get_messages.php')
          .replace(queryParameters: params);
      final res = await http.get(uri, headers: _headers);
      final data = json.decode(res.body);
      return data['data'] ?? [];
    } catch (e) {
      print('🔴 CHAT getMessages error: $e');
      return [];
    }
  }

  // ============================================================
  // 2) إرسال رسالة (نص)
  // ============================================================
  static Future<Map<String, dynamic>> sendMessage({
    required int courseId,
    required int senderId,
    required String content,
    int? replyToId,
  }) async {
    try {
      final body = {
        "course_id": courseId,
        "sender_id": senderId,
        "content": content,
      };
      if (replyToId != null) body['reply_to_id'] = replyToId;

      final res = await http.post(
        Uri.parse('$_base/send_message.php'),
        headers: _headers,
        body: json.encode(body),
      );
      return json.decode(res.body);
    } catch (e) {
      return {"status": "error", "message": "Connection error"};
    }
  }

  // ============================================================
  // 3) إرسال صورة
  // ============================================================
  static Future<Map<String, dynamic>> sendImage({
    required int courseId,
    required int senderId,
    required List<int> fileBytes,
    required String fileName,
    String content = '',
  }) async {
    try {
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('$_base/send_message.php'),
      );
      req.fields['course_id'] = courseId.toString();
      req.fields['sender_id'] = senderId.toString();
      req.fields['content'] = content;
      req.files.add(http.MultipartFile.fromBytes('file', fileBytes,
          filename: fileName));

      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      return json.decode(res.body);
    } catch (e) {
      return {"status": "error", "message": "Upload failed"};
    }
  }

  // ============================================================
  // 4) تعديل رسالة
  // ============================================================
  static Future<Map<String, dynamic>> editMessage({
    required int messageId,
    required int userId,
    required String newContent,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/edit_message.php'),
        headers: _headers,
        body: json.encode({
          "message_id": messageId,
          "user_id": userId,
          "content": newContent,
        }),
      );
      return json.decode(res.body);
    } catch (e) {
      return {"status": "error", "message": "Failed"};
    }
  }

  // ============================================================
  // 5) حذف رسالة
  // ============================================================
  static Future<Map<String, dynamic>> deleteMessage({
    required int messageId,
    required int userId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/delete_message.php'),
        headers: _headers,
        body: json.encode({
          "message_id": messageId,
          "user_id": userId,
        }),
      );
      return json.decode(res.body);
    } catch (e) {
      return {"status": "error", "message": "Failed"};
    }
  }

  // ============================================================
  // 6) تحديد كمقروء
  // ============================================================
  static Future<void> markAsRead({
    required int courseId,
    required int userId,
  }) async {
    try {
      await http.post(
        Uri.parse('$_base/mark_read.php'),
        headers: _headers,
        body: json.encode({
          "course_id": courseId,
          "user_id": userId,
        }),
      );
    } catch (_) {}
  }

  // ============================================================
  // 7) عداد غير المقروء — ✅ مُصلح: يتعامل مع List و Map
  // ============================================================
  static Future<Map<String, dynamic>> getUnreadCounts(int userId) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/get_unread_counts.php?user_id=$userId'),
        headers: _headers,
      );
      final body = json.decode(res.body);
      final rawData = body['data'];

      // 🔧 لو data جاء كـ List فاضية [] بدل Map {}
      if (rawData == null || rawData is List) {
        return {'per_course': {}, 'total': 0};
      }

      final data = Map<String, dynamic>.from(rawData);

      // 🔧 لو per_course جاء كـ List فاضية
      final rawPerCourse = data['per_course'];
      if (rawPerCourse is List) {
        data['per_course'] = {};
      }

      return data;
    } catch (e) {
      print('🔴 getUnreadCounts error: $e');
      return {'per_course': {}, 'total': 0};
    }
  }

  // ============================================================
  // 8) كتم طالب
  // ============================================================
  static Future<Map<String, dynamic>> muteStudent({
    required int courseId,
    required int instructorUserId,
    required int studentUserId,
    String reason = '',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/mute_student.php'),
        headers: _headers,
        body: json.encode({
          "course_id": courseId,
          "user_id": instructorUserId,
          "student_user_id": studentUserId,
          "reason": reason,
        }),
      );
      return json.decode(res.body);
    } catch (e) {
      return {"status": "error", "message": "Failed"};
    }
  }

  // ============================================================
  // 9) فك الكتم
  // ============================================================
  static Future<Map<String, dynamic>> unmuteStudent({
    required int courseId,
    required int instructorUserId,
    required int studentUserId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/unmute_student.php'),
        headers: _headers,
        body: json.encode({
          "course_id": courseId,
          "user_id": instructorUserId,
          "student_user_id": studentUserId,
        }),
      );
      return json.decode(res.body);
    } catch (e) {
      return {"status": "error", "message": "Failed"};
    }
  }

  // ============================================================
  // 10) قائمة المكتومين
  // ============================================================
  static Future<List<dynamic>> getMutedList({
    required int courseId,
    required int instructorUserId,
  }) async {
    try {
      final uri = Uri.parse('$_base/get_muted_list.php').replace(
        queryParameters: {
          'course_id': courseId.toString(),
          'user_id': instructorUserId.toString(),
        },
      );
      final res = await http.get(uri, headers: _headers);
      return json.decode(res.body)['data'] ?? [];
    } catch (_) {
      return [];
    }
  }

  // ============================================================
  // 11) URL الـ SSE Stream
  // ============================================================
  static String streamUrl({
    required int courseId,
    required int userId,
    int? lastId,
  }) {
    var url = '$_base/stream.php?course_id=$courseId&user_id=$userId';
    if (lastId != null) url += '&last_id=$lastId';
    return url;
  }

  // ============================================================
  // 12) URL لتحميل صورة
  // ============================================================
  static String imageUrl(String filePath) {
    return '${ApiService.baseUrl}/uploads/chat/$filePath';
  }
}