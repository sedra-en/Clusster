<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
require_once '../config/database.php';
require_once '../helpers/response.php';

$db = (new Database())->getConnection();
$data = json_decode(file_get_contents("php://input"));

if (!empty($data->student_id) && !empty($data->course_id)) {
    // التأكد من عدم التكرار
    $check = $db->prepare("SELECT id FROM enrollments WHERE student_id = ? AND course_id = ?");
    $check->execute([$data->student_id, $data->course_id]);

    if ($check->rowCount() > 0) {
        sendError("الطالب مسجل بالفعل في هذه المادة");
    }

    $query = "INSERT INTO enrollments (student_id, course_id, enrolled_at, is_active) VALUES (?, ?, NOW(), 1)";
    if ($db->prepare($query)->execute([$data->student_id, $data->course_id])) {
        sendSuccess("تم تسجيل الطالب في المادة بنجاح");
    } else {
        sendError("فشل التسجيل");
    }
}