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

if (empty($data->id)) sendError("id المقرر مطلوب");

// نبني الاستعلام ديناميكياً حسب الحقول الممرّرة
$fields = [];
$params = ['id' => (int)$data->id];

if (isset($data->title) && $data->title !== '') {
    $fields[] = "title = :title";
    $params['title'] = $data->title;
}
if (property_exists($data, 'description')) {
    $fields[] = "description = :description";
    $params['description'] = $data->description;
}
if (property_exists($data, 'instructor_id')) {
    $fields[] = "instructor_id = :instructor_id";
    $params['instructor_id'] = $data->instructor_id ? (int)$data->instructor_id : null;
}
if (property_exists($data, 'semester_id')) {
    $fields[] = "semester_id = :semester_id";
    $params['semester_id'] = $data->semester_id ? (int)$data->semester_id : null;
}
if (isset($data->status)) {
    if (!in_array($data->status, ['draft','published','hidden'], true)) {
        sendError("status غير صالح");
    }
    $fields[] = "status = :status";
    $params['status'] = $data->status;
}
if (isset($data->cover_color)) {
    if (!preg_match('/^#[0-9A-Fa-f]{6}$/', $data->cover_color)) {
        sendError("لون الغلاف غير صالح");
    }
    $fields[] = "cover_color = :cover_color";
    $params['cover_color'] = $data->cover_color;
}

if (empty($fields)) sendError("لا يوجد بيانات لتحديثها");

try {
    $sql = "UPDATE courses SET " . implode(', ', $fields) . " WHERE id = :id";
    $stmt = $db->prepare($sql);
    $stmt->execute($params);

    if ($stmt->rowCount() === 0) {
        // قد يكون المقرر موجود لكن القيم نفسها — نتأكد من وجوده
        $check = $db->prepare("SELECT id FROM courses WHERE id = ?");
        $check->execute([$data->id]);
        if (!$check->fetch()) sendError("المقرر غير موجود", 404);
    }

    sendSuccess("تم تحديث المقرر");
} catch (Exception $e) {
    sendError("خطأ: " . $e->getMessage());
}
