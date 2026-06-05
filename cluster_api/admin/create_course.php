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

if (empty($data->title)) {
    sendError("اسم المقرر مطلوب");
}


$semesterId = !empty($data->semester_id) ? (int)$data->semester_id : null;
if ($semesterId === null) {
    $row = $db->query("SELECT id FROM semesters WHERE is_active = 1 LIMIT 1")
              ->fetch(PDO::FETCH_ASSOC);
    if ($row) $semesterId = (int)$row['id'];
}

$status     = !empty($data->status)       ? $data->status       : 'draft';
$coverColor = !empty($data->cover_color)  ? $data->cover_color  : '#00BCD4';
$instructor = !empty($data->instructor_id)? (int)$data->instructor_id : null;
$desc       = $data->description ?? null;


if (!in_array($status, ['draft','published','hidden'], true)) {
    sendError("status غير صالح");
}
if (!preg_match('/^#[0-9A-Fa-f]{6}$/', $coverColor)) {
    sendError("لون الغلاف غير صالح (HEX مطلوب)");
}

try {
    
    if ($instructor !== null) {
        $check = $db->prepare("SELECT id FROM instructors WHERE id = ?");
        $check->execute([$instructor]);
        if (!$check->fetch()) sendError("الدكتور غير موجود", 404);
    }
    if ($semesterId !== null) {
        $check = $db->prepare("SELECT id FROM semesters WHERE id = ?");
        $check->execute([$semesterId]);
        if (!$check->fetch()) sendError("الفصل غير موجود", 404);
    }

    $stmt = $db->prepare("
        INSERT INTO courses (title, description, instructor_id, semester_id, status, cover_color)
        VALUES (:t, :d, :ins, :sem, :st, :col)
    ");
    $stmt->execute([
        't'   => $data->title,
        'd'   => $desc,
        'ins' => $instructor,
        'sem' => $semesterId,
        'st'  => $status,
        'col' => $coverColor,
    ]);
    sendSuccess("تم إنشاء المقرر", ["id" => (int)$db->lastInsertId()]);
} catch (Exception $e) {
    sendError("خطأ: " . $e->getMessage());
}
