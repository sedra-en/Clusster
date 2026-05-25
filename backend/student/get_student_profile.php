<?php
require_once __DIR__ . '/../cors.php';
require_once '../config/database.php';
require_once '../helpers/response.php';

$db = (new Database())->getConnection();

$userId = $_GET['user_id'] ?? null;
$studentId = $_GET['student_id'] ?? null;

if (!$userId && !$studentId) {
    sendError("user_id أو student_id مطلوب");
}

try {
    if ($userId) {
        $stmt = $db->prepare("
            SELECT
              s.id            AS student_id,
              s.user_id,
              u.full_name, u.email, u.status, u.is_activated, u.created_at,
              s.student_num, s.faculty, s.major, s.year, s.gpa,
              (SELECT COUNT(*) FROM enrollments e
                WHERE e.student_id = s.id AND e.is_active = 1) AS enrolled_count,
              (SELECT COUNT(*) FROM quiz_attempts qa
                WHERE qa.student_id = s.id) AS quiz_attempts_count
            FROM students s
            JOIN users u ON u.id = s.user_id
            WHERE u.id = :uid
            LIMIT 1
        ");
        $stmt->execute(['uid' => $userId]);
    } else {
        $stmt = $db->prepare("
            SELECT
              s.id            AS student_id,
              s.user_id,
              u.full_name, u.email, u.status, u.is_activated, u.created_at,
              s.student_num, s.faculty, s.major, s.year, s.gpa,
              (SELECT COUNT(*) FROM enrollments e
                WHERE e.student_id = s.id AND e.is_active = 1) AS enrolled_count,
              (SELECT COUNT(*) FROM quiz_attempts qa
                WHERE qa.student_id = s.id) AS quiz_attempts_count
            FROM students s
            JOIN users u ON u.id = s.user_id
            WHERE s.id = :sid
            LIMIT 1
        ");
        $stmt->execute(['sid' => $studentId]);
    }
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$row) sendError("الطالب غير موجود", 404);
    sendSuccess("Profile fetched", $row);
} catch (Exception $e) {
    sendError("خطأ: " . $e->getMessage());
}