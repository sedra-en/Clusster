<?php
require_once __DIR__ . '/../cors.php';
require_once '../config/database.php';
require_once '../helpers/response.php';

$db = (new Database())->getConnection();

$courseId = $_GET['course_id'] ?? null;
if (!$courseId) sendError("course_id مطلوب");

try {
    
    $courseStmt = $db->prepare("SELECT id, title FROM courses WHERE id = ? LIMIT 1");
    $courseStmt->execute([$courseId]);
    $course = $courseStmt->fetch(PDO::FETCH_ASSOC);
    if (!$course) sendError("المقرر غير موجود", 404);

    
    $enrolledStmt = $db->prepare("
        SELECT COUNT(*) AS total
        FROM enrollments
        WHERE course_id = ? AND is_active = 1
    ");
    $enrolledStmt->execute([$courseId]);
    $totalEnrolled = (int)$enrolledStmt->fetchColumn();


    $statsStmt = $db->prepare("
        SELECT
            l.id    AS lecture_id,
            l.title AS lecture_title,
            COUNT(DISTINCT qa.student_id) AS students_attempted
        FROM lectures l
        LEFT JOIN quiz_attempts qa ON qa.lecture_id = l.id
        WHERE l.course_id = ?
        GROUP BY l.id, l.title
        HAVING students_attempted > 0
        ORDER BY l.order_num ASC, l.id ASC
    ");
    $statsStmt->execute([$courseId]);
    $lectures = $statsStmt->fetchAll(PDO::FETCH_ASSOC);

    
    foreach ($lectures as &$lec) {
        $lec['lecture_id']         = (int)$lec['lecture_id'];
        $lec['students_attempted'] = (int)$lec['students_attempted'];
    }
    unset($lec);

    
    $uniqueStmt = $db->prepare("
        SELECT COUNT(DISTINCT qa.student_id) AS total
        FROM quiz_attempts qa
        INNER JOIN lectures l ON l.id = qa.lecture_id
        WHERE l.course_id = ?
    ");
    $uniqueStmt->execute([$courseId]);
    $uniqueParticipants = (int)$uniqueStmt->fetchColumn();

    
    sendSuccess("Quiz stats fetched", [
        'course_id'           => (int)$course['id'],
        'course_title'        => $course['title'],
        'total_enrolled'      => $totalEnrolled,
        'unique_participants' => $uniqueParticipants,
        'lectures_with_quiz'  => count($lectures),
        'lectures'            => $lectures,
    ]);

} catch (Exception $e) {
    sendError("خطأ: " . $e->getMessage());
}