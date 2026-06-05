<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: *");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }
header("Content-Type: application/json; charset=UTF-8");
require_once '../config/database.php';
require_once '../helpers/response.php';

$database = new Database();
$db = $database->getConnection();

$lectureId = $_GET['lecture_id'] ?? '';
if (empty($lectureId)) {
    sendError("معرف المحاضرة مطلوب");
}

$stmt = $db->prepare("SELECT is_generated, easy_summary, medium_summary, hard_summary, quiz_json 
                       FROM lecture_ai_content WHERE lecture_id = ?");
$stmt->execute([$lectureId]);
$row = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$row) {
    echo json_encode(["status" => "processing"]);
} elseif ($row['is_generated'] == 1) {
    echo json_encode([
        "status" => "done",
        "data" => [
            "easy_summary"   => $row['easy_summary'],
            "medium_summary" => $row['medium_summary'],
            "hard_summary"   => $row['hard_summary'],
            "quiz_json"      => $row['quiz_json']
        ]
    ]);
} elseif ($row['is_generated'] == -1) {
    echo json_encode(["status" => "error"]);
} else {
    echo json_encode(["status" => "processing"]);
}