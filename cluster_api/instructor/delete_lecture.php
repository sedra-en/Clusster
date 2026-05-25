<?php
require_once __DIR__ . '/../cors.php';
require_once '../config/database.php';
require_once '../helpers/response.php';

$db = (new Database())->getConnection();
$data = json_decode(file_get_contents("php://input"));

if (empty($data->lecture_id)) sendError("lecture_id مطلوب");

try {
    $db->beginTransaction();

    $db->prepare("DELETE FROM quiz_attempts WHERE lecture_id = ?")
       ->execute([$data->lecture_id]);

    $db->prepare("DELETE FROM lecture_ai_content WHERE lecture_id = ?")
       ->execute([$data->lecture_id]);

    $stmt = $db->prepare("SELECT file_path, audio_path FROM lectures WHERE id = ?");
    $stmt->execute([$data->lecture_id]);
    $files = $stmt->fetch(PDO::FETCH_ASSOC);

    $del = $db->prepare("DELETE FROM lectures WHERE id = ?");
    $del->execute([$data->lecture_id]);

    if ($del->rowCount() === 0) {
        $db->rollBack();
        sendError("المحاضرة غير موجودة", 404);
    }

    if ($files) {
        $uploadsDir = __DIR__ . '/../uploads/';
        if (!empty($files['file_path']) && file_exists($uploadsDir . $files['file_path'])) {
            @unlink($uploadsDir . $files['file_path']);
        }
        if (!empty($files['audio_path']) && file_exists($uploadsDir . $files['audio_path'])) {
            @unlink($uploadsDir . $files['audio_path']);
        }
    }

    $db->commit();
    sendSuccess("تم حذف المحاضرة");
} catch (Exception $e) {
    $db->rollBack();
    sendError("خطأ: " . $e->getMessage());
}