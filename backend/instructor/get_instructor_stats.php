<?php
require_once __DIR__ . '/../cors.php';
require_once '../config/database.php';
require_once '../helpers/response.php';

$db = (new Database())->getConnection();

$userId = $_GET['user_id'] ?? null;
$instructorId = $_GET['instructor_id'] ?? null;

if (!$userId && !$instructorId) sendError("user_id أو instructor_id مطلوب");

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
          (SELECT COUNT(*) FROM courses WHERE instructor_id = :id1)                               AS courses_count,
          (SELECT COUNT(*) FROM courses WHERE instructor_id = :id2 AND status = 'published')      AS published_courses,
          (SELECT COUNT(*) FROM lectures l JOIN courses c ON c.id = l.course_id
            WHERE c.instructor_id = :id3)                                                         AS lectures_count,
          (SELECT COUNT(*) FROM lecture_ai_content lac
            JOIN lectures l ON l.id = lac.lecture_id
            JOIN courses c ON c.id = l.course_id
            WHERE c.instructor_id = :id4 AND lac.is_generated = 1)                                AS ai_generated_count,
          (SELECT COUNT(DISTINCT e.student_id) FROM enrollments e
            JOIN courses c ON c.id = e.course_id
            WHERE c.instructor_id = :id5 AND e.is_active = 1)                                     AS unique_students,
          (SELECT COUNT(*) FROM quiz_attempts qa
            JOIN lectures l ON l.id = qa.lecture_id
            JOIN courses c ON c.id = l.course_id
            WHERE c.instructor_id = :id6)                                                         AS quiz_attempts
    ");
    $stmt->execute([
        'id1' => $instructorId, 'id2' => $instructorId, 'id3' => $instructorId,
        'id4' => $instructorId, 'id5' => $instructorId, 'id6' => $instructorId
    ]);
    $stats = $stmt->fetch(PDO::FETCH_ASSOC);

    $rec = $db->prepare("
        SELECT l.id, l.title, l.created_at, c.title AS course_title, c.cover_color,
               (SELECT is_generated FROM lecture_ai_content WHERE lecture_id = l.id) AS has_ai
        FROM lectures l
        JOIN courses c ON c.id = l.course_id
        WHERE c.instructor_id = ?
        ORDER BY l.created_at DESC
        LIMIT 5
    ");
    $rec->execute([$instructorId]);
    $recent = $rec->fetchAll(PDO::FETCH_ASSOC);

    sendSuccess("Stats fetched", [
        "instructor_id"      => (int)$instructorId,
        "courses_count"      => (int)$stats['courses_count'],
        "published_courses"  => (int)$stats['published_courses'],
        "lectures_count"     => (int)$stats['lectures_count'],
        "ai_generated_count" => (int)$stats['ai_generated_count'],
        "unique_students"    => (int)$stats['unique_students'],
        "quiz_attempts"      => (int)$stats['quiz_attempts'],
        "recent_lectures"    => $recent,
    ]);
} catch (Exception $e) {
    sendError("خطأ: " . $e->getMessage());
}