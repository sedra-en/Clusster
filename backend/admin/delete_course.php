<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { exit; }

require_once '../config/database.php';
require_once '../helpers/response.php';

$db   = (new Database())->getConnection();
$data = json_decode(file_get_contents("php://input"));

if (empty($data->id)) sendError("id مطلوب");

try {
    $db->beginTransaction();

    // نحذف بترتيب: محاولات الكويز → AI content → enrollments → lectures → الكورس
    $cid = (int)$data->id;

    $db->prepare("
        DELETE qa FROM quiz_attempts qa
        JOIN lectures l ON l.id = qa.lecture_id
        WHERE l.course_id = ?
    ")->execute([$cid]);

    $db->prepare("
        DELETE ai FROM lecture_ai_content ai
        JOIN lectures l ON l.id = ai.lecture_id
        WHERE l.course_id = ?
    ")->execute([$cid]);

    $db->prepare("DELETE FROM enrollments WHERE course_id = ?")->execute([$cid]);
    $db->prepare("DELETE FROM lectures    WHERE course_id = ?")->execute([$cid]);

    $stmt = $db->prepare("DELETE FROM courses WHERE id = ?");
    $stmt->execute([$cid]);

    if ($stmt->rowCount() === 0) {
        $db->rollBack();
        sendError("المقرر غير موجود", 404);
    }

    $db->commit();
    sendSuccess("تم حذف المقرر وكل بياناته المرتبطة");
} catch (Exception $e) {
    $db->rollBack();
    sendError("خطأ: " . $e->getMessage());
}
