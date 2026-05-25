<?php
require_once __DIR__ . '/../cors.php';
require_once '../config/database.php';
require_once '../helpers/response.php';
 
$db = (new Database())->getConnection();
$lectureId = $_GET['lecture_id'] ?? null;
$role      = $_GET['role'] ?? 'student';
 
if (!$lectureId) sendError("lecture_id مطلوب");
 
try {
    $lectureStmt = $db->prepare("
        SELECT l.id, l.title, l.created_at, l.file_path, l.audio_path,
               c.title AS course_title, c.cover_color
        FROM lectures l
        JOIN courses c ON c.id = l.course_id
        WHERE l.id = ?
    ");
    $lectureStmt->execute([$lectureId]);
    $lecture = $lectureStmt->fetch(PDO::FETCH_ASSOC);
 
    if (!$lecture) sendError("المحاضرة غير موجودة", 404);
 
    $aiStmt = $db->prepare("
        SELECT easy_summary, medium_summary, hard_summary, quiz_json,
               is_generated, is_published, generated_at
        FROM lecture_ai_content
        WHERE lecture_id = ?
    ");
    $aiStmt->execute([$lectureId]);
    $ai = $aiStmt->fetch(PDO::FETCH_ASSOC);
 
    // الطالب يشوف بس المنشور
    if ($role === 'student' && $ai && $ai['is_published'] != 1) {
        $ai = null;
    }
 
    if ($ai && !empty($ai['quiz_json'])) {
        $decoded = json_decode($ai['quiz_json'], true);
        if (json_last_error() === JSON_ERROR_NONE) {
            $ai['quiz_json'] = $decoded;
        }
    }
 
    sendSuccess("AI content fetched", [
        "lecture"    => $lecture,
        "ai_content" => $ai,
    ]);
} catch (Exception $e) {
    sendError("خطأ: " . $e->getMessage());
}