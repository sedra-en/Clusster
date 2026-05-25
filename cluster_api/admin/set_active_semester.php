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

if (empty($data->semester_id)) {
    sendError("semester_id مطلوب");
}

try {
    $db->beginTransaction();
    $db->exec("UPDATE semesters SET is_active = 0");
    $stmt = $db->prepare("UPDATE semesters SET is_active = 1 WHERE id = ?");
    $stmt->execute([$data->semester_id]);

    if ($stmt->rowCount() === 0) {
        $db->rollBack();
        sendError("الفصل غير موجود", 404);
    }

    $db->commit();
    sendSuccess("تم تعيين الفصل الحالي");
} catch (Exception $e) {
    $db->rollBack();
    sendError("خطأ: " . $e->getMessage());
}
