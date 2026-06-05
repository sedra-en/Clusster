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

if (empty($data->user_id) || empty($data->status)) {
    sendError("user_id و status مطلوبين");
}


$allowed = ['active', 'pending', 'blocked'];
if (!in_array($data->status, $allowed, true)) {
    sendError("status غير صالح. القيم المسموحة: active, pending, blocked");
}

try {
    
    $check = $db->prepare("SELECT role FROM users WHERE id = ?");
    $check->execute([$data->user_id]);
    $row = $check->fetch(PDO::FETCH_ASSOC);

    if (!$row) sendError("المستخدم غير موجود", 404);
    if ($row['role'] === 'admin') sendError("لا يمكن تعديل حالة حساب الأدمن");

    $stmt = $db->prepare("UPDATE users SET status = :st, updated_at = NOW() WHERE id = :id");
    $stmt->execute(['st' => $data->status, 'id' => $data->user_id]);

    sendSuccess("تم تحديث حالة المستخدم", [
        "user_id" => (int)$data->user_id,
        "status"  => $data->status
    ]);
} catch (Exception $e) {
    sendError("خطأ: " . $e->getMessage());
}
