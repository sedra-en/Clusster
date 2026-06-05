<?php
require_once __DIR__ . '/../cors.php';
require_once '../config/database.php';
require_once '../helpers/response.php';
 
$db = (new Database())->getConnection();
$courseId = $_GET['course_id'] ?? null;
if (!$courseId) sendError("course_id مطلوب");
 
try {
    $studentsStmt = $db->prepare("
        SELECT u.id AS user_id, s.id AS student_id, u.full_name, u.email
        FROM enrollments e
        JOIN students s ON s.id = e.student_id
        JOIN users u ON u.id = s.user_id
        WHERE e.course_id = ? AND e.is_active = 1
        ORDER BY u.full_name ASC
    ");
    $studentsStmt->execute([$courseId]);
    $students = $studentsStmt->fetchAll(PDO::FETCH_ASSOC);
 
    $lecturesStmt = $db->prepare("
        SELECT l.id, l.title
        FROM lectures l
        WHERE l.course_id = ?
        ORDER BY l.created_at ASC
    ");
    $lecturesStmt->execute([$courseId]);
    $lectures = $lecturesStmt->fetchAll(PDO::FETCH_ASSOC);
 
    
    $scoresStmt = $db->prepare("
        SELECT student_id, lecture_id, score, correct_q, total_q, passed, attempted_at
        FROM quiz_attempts
        WHERE lecture_id IN (SELECT id FROM lectures WHERE course_id = ?)
        ORDER BY attempted_at ASC
    ");
    $scoresStmt->execute([$courseId]);
    $scores = $scoresStmt->fetchAll(PDO::FETCH_ASSOC);
 
    
    $scoresMap = [];
    foreach ($scores as $s) {
        $scoresMap[$s['student_id']][$s['lecture_id']][] = $s;
    }
 
    sendSuccess("data fetched", [
        "students" => $students,
        "lectures" => $lectures,
        "scores"   => $scoresMap,
    ]);
} catch (Exception $e) {
    sendError("خطأ: " . $e->getMessage());
}
 