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

if (empty($data->course_id) || empty($data->student_ids) || !is_array($data->student_ids)) {
    sendError("course_id و student_ids (مصفوفة) مطلوبين");
}

$courseId   = (int)$data->course_id;
$studentIds = array_map('intval', $data->student_ids);

try {
    // نتأكد إن المقرر موجود
    $check = $db->prepare("SELECT id FROM courses WHERE id = ?");
    $check->execute([$courseId]);
    if (!$check->fetch()) sendError("المقرر غير موجود", 404);

    $db->beginTransaction();

    $stmt = $db->prepare("
        INSERT INTO enrollments (student_id, course_id, enrolled_at, is_active)
        VALUES (?, ?, NOW(), 1)
        ON DUPLICATE KEY UPDATE is_active = 1, enrolled_at = NOW()
    ");

    $inserted = 0;
    foreach ($studentIds as $sid) {
        $stmt->execute([$sid, $courseId]);
        if ($stmt->rowCount() > 0) $inserted++;
    }

    $db->commit();
    sendSuccess("تم تسجيل الطلاب", [
        "course_id" => $courseId,
        "added"     => $inserted,
        "total_requested" => count($studentIds),
    ]);
} catch (Exception $e) {
    $db->rollBack();
    sendError("خطأ: " . $e->getMessage());
}
