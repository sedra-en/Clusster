<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once '../config/database.php';
require_once '../helpers/response.php';

$db = (new Database())->getConnection();

// إذا تم تمرير course_id، نستثني الطلاب المسجلين فيه أصلاً
$excludeCourseId = $_GET['exclude_course_id'] ?? null;

try {
    if ($excludeCourseId) {
        $stmt = $db->prepare("
            SELECT
              s.id           AS student_id,
              s.user_id,
              u.full_name,
              u.email,
              u.status,
              s.student_num,
              s.faculty,
              s.major,
              s.year,
              s.gpa
            FROM students s
            JOIN users u ON u.id = s.user_id
            WHERE u.role = 'student'
              AND s.id NOT IN (
                SELECT student_id FROM enrollments
                WHERE course_id = :cid AND is_active = 1
              )
            ORDER BY u.full_name ASC
        ");
        $stmt->execute(['cid' => $excludeCourseId]);
    } else {
        $stmt = $db->query("
            SELECT
              s.id           AS student_id,
              s.user_id,
              u.full_name,
              u.email,
              u.status,
              s.student_num,
              s.faculty,
              s.major,
              s.year,
              s.gpa
            FROM students s
            JOIN users u ON u.id = s.user_id
            WHERE u.role = 'student'
            ORDER BY u.full_name ASC
        ");
    }
    sendSuccess("Students fetched", $stmt->fetchAll(PDO::FETCH_ASSOC));
} catch (Exception $e) {
    sendError("خطأ: " . $e->getMessage());
}
