import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // للموبايل
  //static const String baseUrl = "http://172.20.10.3/cluster_api";
  // للويب — شيلي التعليق لو بدك تشغلي على Edge
  static const String baseUrl = "http://localhost/cluster_api";

  static Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final url = '$baseUrl/auth/login.php';
    print('LOGIN URL: $url');
    print('LOGIN EMAIL: $email');
    print('LOGIN PASSWORD LENGTH: ${password.length}');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode({"email": email, "password": password}),
      );
      print('LOGIN STATUS: ${res.statusCode}');
      print('LOGIN BODY: ${res.body}');
      return json.decode(res.body);
    } catch (e) {
      print('LOGIN ERROR: $e');
      return {"status": "error", "message": "Connection error: $e"};
    }
  }

  static Future<Map<String, dynamic>> verifyCode(
    String email,
    String code,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/verify_code.php'),
        headers: _headers,
        body: json.encode({"email": email, "code": code}),
      );
      return json.decode(res.body);
    } catch (e) {
      return {"status": "error", "message": "Failed"};
    }
  }

  static Future<Map<String, dynamic>> activateAccount(
    String userId,
    String password,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/activate_account.php'),
        headers: _headers,
        body: json.encode({"user_id": userId, "password": password}),
      );
      return json.decode(res.body);
    } catch (e) {
      return {"status": "error", "message": "Failed"};
    }
  }

  // ============================================================
  // Admin
  // ============================================================
  static Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/admin/get_stats.php'),
        headers: _headers,
      );
      return Map<String, dynamic>.from(json.decode(res.body)['data'] ?? {});
    } catch (_) {
      return {};
    }
  }

  static Future<List<dynamic>> getUsers() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/admin/get_users.php'),
        headers: _headers,
      );
      return json.decode(res.body)['data'] ?? [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> createUser(
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/admin/create_user.php'),
        headers: _headers,
        body: json.encode(data),
      );
      return json.decode(res.body);
    } catch (e) {
      return {"status": "error", "message": "Failed"};
    }
  }

  static Future<Map<String, dynamic>> enrollStudent(
    String studentId,
    String courseId,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/admin/enroll_student.php'),
        headers: _headers,
        body: json.encode({"student_id": studentId, "course_id": courseId}),
      );
      return json.decode(res.body);
    } catch (e) {
      return {"status": "error", "message": "Enrollment failed"};
    }
  }

  static Future<Map<String, dynamic>> updateUserStatus(
    String userId,
    String status,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/admin/update_user_status.php'),
        headers: _headers,
        body: json.encode({"user_id": userId, "status": status}),
      );
      return json.decode(res.body);
    } catch (e) {
      return {"status": "error", "message": "Failed"};
    }
  }

  static Future<List<dynamic>> getInstructors() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/admin/get_instructors.php'),
        headers: _headers,
      );
      return json.decode(res.body)['data'] ?? [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<dynamic>> getStudents({String? excludeCourseId}) async {
    try {
      final url =
          excludeCourseId != null
              ? '$baseUrl/admin/get_students.php?exclude_course_id=$excludeCourseId'
              : '$baseUrl/admin/get_students.php';
      final res = await http.get(Uri.parse(url), headers: _headers);
      return json.decode(res.body)['data'] ?? [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<dynamic>> getSemesters() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/admin/get_semesters.php'),
        headers: _headers,
      );
      return json.decode(res.body)['data'] ?? [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> createSemester({
    required String name,
    required String code,
    String? startDate,
    String? endDate,
    bool isActive = false,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/admin/create_semester.php'),
        headers: _headers,
        body: json.encode({
          "name": name,
          "code": code,
          "start_date": startDate,
          "end_date": endDate,
          "is_active": isActive ? 1 : 0,
        }),
      );
      return json.decode(res.body);
    } catch (e) {
      return {"status": "error", "message": "Failed"};
    }
  }

  static Future<Map<String, dynamic>> setActiveSemester(
    String semesterId,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/admin/set_active_semester.php'),
        headers: _headers,
        body: json.encode({"semester_id": semesterId}),
      );
      return json.decode(res.body);
    } catch (e) {
      return {"status": "error", "message": "Failed"};
    }
  }

  static Future<List<dynamic>> getAdminCourses({
    String? semesterId,
    String? status,
  }) async {
    try {
      final params = <String, String>{};
      if (semesterId != null && semesterId.isNotEmpty)
        params['semester_id'] = semesterId;
      if (status != null && status.isNotEmpty) params['status'] = status;
      final uri = Uri.parse(
        '$baseUrl/admin/get_courses.php',
      ).replace(queryParameters: params.isEmpty ? null : params);
      final res = await http.get(uri, headers: _headers);
      return json.decode(res.body)['data'] ?? [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> createCourse({
    required String title,
    String? description,
    String? instructorId,
    String? semesterId,
    String status = 'draft',
    String coverColor = '#00BCD4',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/admin/create_course.php'),
        headers: _headers,
        body: json.encode({
          "title": title,
          "description": description,
          "instructor_id": instructorId,
          "semester_id": semesterId,
          "status": status,
          "cover_color": coverColor,
        }),
      );
      return json.decode(res.body);
    } catch (e) {
      return {"status": "error", "message": "Failed"};
    }
  }

  static Future<Map<String, dynamic>> updateCourse(
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/admin/update_course.php'),
        headers: _headers,
        body: json.encode(data),
      );
      return json.decode(res.body);
    } catch (e) {
      return {"status": "error", "message": "Failed"};
    }
  }

  static Future<Map<String, dynamic>> deleteCourse(String courseId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/admin/delete_course.php'),
        headers: _headers,
        body: json.encode({"id": courseId}),
      );
      return json.decode(res.body);
    } catch (e) {
      return {"status": "error", "message": "Failed"};
    }
  }

  static Future<List<dynamic>> getCourseEnrollments(String courseId) async {
    try {
      final res = await http.get(
        Uri.parse(
          '$baseUrl/admin/get_course_enrollments.php?course_id=$courseId',
        ),
        headers: _headers,
      );
      return json.decode(res.body)['data'] ?? [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> bulkEnroll(
    String courseId,
    List<String> studentIds,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/admin/bulk_enroll.php'),
        headers: _headers,
        body: json.encode({"course_id": courseId, "student_ids": studentIds}),
      );
      return json.decode(res.body);
    } catch (e) {
      return {"status": "error", "message": "Failed"};
    }
  }

  static Future<Map<String, dynamic>> unenrollStudent({
    String? enrollmentId,
    String? studentId,
    String? courseId,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (enrollmentId != null) body['enrollment_id'] = enrollmentId;
      if (studentId != null) body['student_id'] = studentId;
      if (courseId != null) body['course_id'] = courseId;
      final res = await http.post(
        Uri.parse('$baseUrl/admin/unenroll_student.php'),
        headers: _headers,
        body: json.encode(body),
      );
      return json.decode(res.body);
    } catch (e) {
      return {"status": "error", "message": "Failed"};
    }
  }

  // ============================================================
  // Instructor
  // ============================================================
  static Future<Map<String, dynamic>> getInstructorProfile(
    String userId,
  ) async {
    try {
      final res = await http.get(
        Uri.parse(
          '$baseUrl/instructor/get_instructor_profile.php?user_id=$userId',
        ),
        headers: _headers,
      );
      return Map<String, dynamic>.from(json.decode(res.body)['data'] ?? {});
    } catch (_) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> getInstructorStats(String userId) async {
    try {
      final res = await http.get(
        Uri.parse(
          '$baseUrl/instructor/get_instructor_stats.php?user_id=$userId',
        ),
        headers: _headers,
      );
      return Map<String, dynamic>.from(json.decode(res.body)['data'] ?? {});
    } catch (_) {
      return {};
    }
  }

  static Future<List<dynamic>> getInstructorCoursesByUser(String userId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/instructor/get_my_courses.php?user_id=$userId'),
        headers: _headers,
      );
      return json.decode(res.body)['data'] ?? [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<dynamic>> getInstructorCourses(String instructorId) async {
    try {
      final res = await http.get(
        Uri.parse(
          '$baseUrl/instructor/get_my_courses.php?instructor_id=$instructorId',
        ),
        headers: _headers,
      );
      return json.decode(res.body)['data'] ?? [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<dynamic>> getCourseStudents(String courseId) async {
    try {
      final res = await http.get(
        Uri.parse(
          '$baseUrl/instructor/get_course_students.php?course_id=$courseId',
        ),
        headers: _headers,
      );
      return json.decode(res.body)['data'] ?? [];
    } catch (_) {
      return [];
    }
  }

  // للدكتور — بيبعت role=instructor
  static Future<Map<String, dynamic>> getLectureAIContent(
    String lectureId,
  ) async {
    try {
      final res = await http.get(
        Uri.parse(
          '$baseUrl/instructor/get_lecture_ai_content.php?lecture_id=$lectureId&role=instructor',
        ),
        headers: _headers,
      );
      return Map<String, dynamic>.from(json.decode(res.body)['data'] ?? {});
    } catch (_) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> deleteLecture(String lectureId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/instructor/delete_lecture.php'),
        headers: _headers,
        body: json.encode({"lecture_id": lectureId}),
      );
      return json.decode(res.body);
    } catch (e) {
      return {"status": "error", "message": "Failed"};
    }
  }

  static Future<Map<String, dynamic>> uploadLecture({
    required String courseId,
    required String title,
    List<int>? fileBytes,
    String? fileName,
    List<int>? audioBytes,
    String? audioName,
  }) async {
    try {
      var req = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/instructor/upload_lecture.php'),
      );
      req.fields['course_id'] = courseId;
      req.fields['title'] = title;
      if (fileBytes != null && fileName != null) {
        req.files.add(
          http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
        );
      }
      if (audioBytes != null && audioName != null) {
        req.files.add(
          http.MultipartFile.fromBytes(
            'audio',
            audioBytes,
            filename: audioName,
          ),
        );
      }
      var response = await http.Response.fromStream(await req.send());
      return json.decode(response.body);
    } catch (e) {
      return {"status": "error", "message": "Upload failed"};
    }
  }

  // ✅ timeout رفعناه لـ 120 دقيقة
  static Future<Map<String, dynamic>> generateAIContent(
    String lectureId,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/instructor/generate_ai_content.php'),
            headers: _headers,
            body: json.encode({"lecture_id": lectureId}),
          )
          .timeout(const Duration(minutes: 120));
      return json.decode(res.body);
    } catch (e) {
      return {"status": "error", "message": "AI generation failed"};
    }
  }

  static Future<Map<String, dynamic>> publishAIContent(String lectureId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/instructor/publish_ai_content.php'),
        headers: _headers,
        body: json.encode({"lecture_id": lectureId}),
      );
      return json.decode(res.body);
    } catch (e) {
      return {"status": "error", "message": "Failed"};
    }
  }

  // ============================================================
  // Student
  // ============================================================
  static Future<Map<String, dynamic>> getStudentProfile(String userId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/student/get_student_profile.php?user_id=$userId'),
        headers: _headers,
      );
      return Map<String, dynamic>.from(json.decode(res.body)['data'] ?? {});
    } catch (_) {
      return {};
    }
  }

  static Future<List<dynamic>> getStudentEnrolledCourses(String userId) async {
    try {
      final res = await http.get(
        Uri.parse(
          '$baseUrl/student/get_my_enrolled_courses.php?user_id=$userId',
        ),
        headers: _headers,
      );
      return json.decode(res.body)['data'] ?? [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<dynamic>> getStudentCourses(String studentId) async {
    try {
      final res = await http.get(
        Uri.parse(
          '$baseUrl/student/get_my_enrolled_courses.php?student_id=$studentId',
        ),
        headers: _headers,
      );
      return json.decode(res.body)['data'] ?? [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<dynamic>> getLectures(
    String courseId, {
    String role = 'student',
  }) async {
    try {
      final res = await http.get(
        Uri.parse(
          '$baseUrl/courses/get_lectures.php?course_id=$courseId&role=$role',
        ),
        headers: _headers,
      );
      return json.decode(res.body)['data'] ?? [];
    } catch (_) {
      return [];
    }
  }

  // للطالب — بيبعت role=student
  static Future<Map<String, dynamic>> getAIContent(String lectureId) async {
    try {
      final res = await http.get(
        Uri.parse(
          '$baseUrl/instructor/get_lecture_ai_content.php?lecture_id=$lectureId&role=student',
        ),
        headers: _headers,
      );
      return json.decode(res.body)['data'] ?? {};
    } catch (_) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> submitQuiz(
    Map<String, dynamic> quizData,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/student/submit_quiz.php'),
        headers: _headers,
        body: json.encode(quizData),
      );
      return json.decode(res.body);
    } catch (e) {
      return {"status": "error", "message": "Failed"};
    }
  }

  static Future<Map<String, dynamic>> updateAIContent({
    required String lectureId,
    String? easySummary,
    String? mediumSummary,
    String? hardSummary,
    List<dynamic>? quizJson,
  }) async {
    try {
      final body = <String, dynamic>{'lecture_id': lectureId};
      if (easySummary != null) body['easy_summary'] = easySummary;
      if (mediumSummary != null) body['medium_summary'] = mediumSummary;
      if (hardSummary != null) body['hard_summary'] = hardSummary;
      if (quizJson != null) body['quiz_json'] = quizJson;
      final res = await http.post(
        Uri.parse('$baseUrl/instructor/update_ai_content.php'),
        headers: _headers,
        body: json.encode(body),
      );
      return json.decode(res.body);
    } catch (e) {
      return {"status": "error", "message": "Failed"};
    }
  }

  static Future<Map<String, dynamic>> getCourseStudentsScores(
    String courseId,
  ) async {
    try {
      final res = await http.get(
        Uri.parse(
          '$baseUrl/instructor/get_course_students_scores.php?course_id=$courseId',
        ),
        headers: _headers,
      );
      return json.decode(res.body)['data'] ?? {};
    } catch (_) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> getCourseQuizStats(
    String courseId,
  ) async {
    try {
      final res = await http.get(
        Uri.parse(
          '$baseUrl/instructor/get_course_quiz_stats.php?course_id=$courseId',
        ),
        headers: _headers,
      );
      return Map<String, dynamic>.from(json.decode(res.body)['data'] ?? {});
    } catch (_) {
      return {};
    }
  }
}
