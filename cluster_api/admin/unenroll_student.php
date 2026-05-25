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

// نقبل إما enrollment_id مباشرة، أو الزوج (student_id + course_id)
try {
    if (!empty($data->enrollment_id)) {
        $stmt = $db->prepare("DELETE FROM enrollments WHERE id = ?");
        $stmt->execute([(int)$data->enrollment_id]);
    } elseif (!empty($data->student_id) && !empty($data->course_id)) {
        $stmt = $db->prepare("
            DELETE FROM enrollments WHERE student_id = ? AND course_id = ?
        ");
        $stmt->execute([(int)$data->student_id, (int)$data->course_id]);
    } else {
        sendError("enrollment_id أو (student_id + course_id) مطلوبين");
    }

    if ($stmt->rowCount() === 0) sendError("التسجيل غير موجود", 404);
    sendSuccess("تم إلغاء تسجيل الطالب");
} catch (Exception $e) {
    sendError("خطأ: " . $e->getMessage());
}
