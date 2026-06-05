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
    // إذا تم تمرير user_id، نحوّله إلى student_id
    if ($userId && !$studentId) {
        $s = $db->prepare("SELECT id FROM students WHERE user_id = ? LIMIT 1");
        $s->execute([$userId]);
        $row = $s->fetch(PDO::FETCH_ASSOC);
        if (!$row) sendError("الطالب غير موجود", 404);
        $studentId = $row['id'];
    }

    $stmt = $db->prepare("
        SELECT
          c.id, c.title, c.description, c.cover_color, c.status,
          c.semester_id,
          sem.name AS semester_name,
          sem.is_active AS semester_active,
          u.full_name AS instructor_name,
          (SELECT COUNT(*) FROM lectures l
            WHERE l.course_id = c.id) AS lectures_count,
          (SELECT COUNT(*) FROM lecture_ai_content lac
            JOIN lectures l ON l.id = lac.lecture_id
            WHERE l.course_id = c.id AND lac.is_generated = 1) AS ai_count,
          e.enrolled_at
        FROM enrollments e
        JOIN courses c ON c.id = e.course_id
        LEFT JOIN semesters sem ON sem.id = c.semester_id
        LEFT JOIN instructors i ON i.id = c.instructor_id
        LEFT JOIN users u ON u.id = i.user_id
        WHERE e.student_id = :sid AND e.is_active = 1 AND c.status = 'published'
        ORDER BY e.enrolled_at DESC
    ");
    $stmt->execute(['sid' => $studentId]);
    sendSuccess("Enrolled courses fetched", $stmt->fetchAll(PDO::FETCH_ASSOC));
} catch (Exception $e) {
    sendError("خطأ: " . $e->getMessage());
}