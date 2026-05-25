<?php
require_once __DIR__ . '/../cors.php';
require_once '../config/database.php';
require_once '../helpers/response.php';

$db = (new Database())->getConnection();
$instructorId = $_GET['instructor_id'] ?? null;
$userId = $_GET['user_id'] ?? null;

if (!$instructorId && !$userId) sendError("instructor_id أو user_id مطلوب");

try {
    if ($userId && !$instructorId) {
        $s = $db->prepare("SELECT id FROM instructors WHERE user_id = ? LIMIT 1");
        $s->execute([$userId]);
        $row = $s->fetch(PDO::FETCH_ASSOC);
        if (!$row) sendError("الدكتور غير موجود", 404);
        $instructorId = $row['id'];
    }

    $stmt = $db->prepare("
        SELECT
          c.id, c.title, c.description, c.status, c.cover_color,
          c.created_at, c.semester_id,
          s.name AS semester_name, s.is_active AS semester_active,
          (SELECT COUNT(*) FROM lectures l
            WHERE l.course_id = c.id) AS lectures_count,
          (SELECT COUNT(*) FROM enrollments e
            WHERE e.course_id = c.id AND e.is_active = 1) AS students_count,
          (SELECT COUNT(*) FROM lecture_ai_content lac
            JOIN lectures l ON l.id = lac.lecture_id
            WHERE l.course_id = c.id AND lac.is_generated = 1) AS ai_count
        FROM courses c
        LEFT JOIN semesters s ON s.id = c.semester_id
        WHERE c.instructor_id = :id
        ORDER BY c.created_at DESC
    ");
    $stmt->execute(['id' => $instructorId]);
    sendSuccess("Courses fetched", $stmt->fetchAll(PDO::FETCH_ASSOC));
} catch (Exception $e) {
    sendError("خطأ: " . $e->getMessage());
}