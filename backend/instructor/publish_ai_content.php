<?php
set_time_limit(0);
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: *");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }
header("Content-Type: application/json; charset=UTF-8");
require_once '../config/database.php';
require_once '../helpers/response.php';

$database = new Database();
$db = $database->getConnection();
$data = json_decode(file_get_contents("php://input"));

if (!empty($data->lecture_id)) {
    $query = "UPDATE lecture_ai_content SET is_published = 1 WHERE lecture_id = :id";
    $stmt = $db->prepare($query);
    $stmt->bindParam(':id', $data->lecture_id);
    $stmt->execute();
    sendSuccess("تم النشر بنجاح");
} else {
    sendError("معرف المحاضرة مطلوب");
}