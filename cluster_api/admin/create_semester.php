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

if (empty($data->name) || empty($data->code)) {
    sendError("الاسم والكود مطلوبين");
}

$setActive = !empty($data->is_active) ? 1 : 0;

try {
    $db->beginTransaction();

    // إذا كان الفصل الجديد active نلغي تفعيل البقية أولاً
    if ($setActive) {
        $db->exec("UPDATE semesters SET is_active = 0");
    }

    $stmt = $db->prepare("
        INSERT INTO semesters (name, code, start_date, end_date, is_active)
        VALUES (:name, :code, :sd, :ed, :act)
    ");
    $stmt->execute([
        'name' => $data->name,
        'code' => $data->code,
        'sd'   => !empty($data->start_date) ? $data->start_date : null,
        'ed'   => !empty($data->end_date)   ? $data->end_date   : null,
        'act'  => $setActive,
    ]);
    $newId = $db->lastInsertId();

    $db->commit();
    sendSuccess("تم إنشاء الفصل", ["id" => (int)$newId]);
} catch (PDOException $e) {
    $db->rollBack();
    if ($e->getCode() === '23000') {
        sendError("كود الفصل مستخدم مسبقاً");
    }
    sendError("خطأ: " . $e->getMessage());
}
