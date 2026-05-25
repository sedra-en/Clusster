<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: *");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }
header("Content-Type: application/json; charset=UTF-8");
require_once '../config/database.php';
require_once '../helpers/response.php';

$db = (new Database())->getConnection();
$data = json_decode(file_get_contents("php://input"), true);

if (empty($data['lecture_id'])) sendError("lecture_id مطلوب");

$fields = [];
$params = ['lid' => $data['lecture_id']];

if (isset($data['easy_summary']))   { $fields[] = 'easy_summary = :easy';   $params['easy'] = $data['easy_summary']; }
if (isset($data['medium_summary'])) { $fields[] = 'medium_summary = :med';  $params['med']  = $data['medium_summary']; }
if (isset($data['hard_summary']))   { $fields[] = 'hard_summary = :hard';   $params['hard'] = $data['hard_summary']; }
if (isset($data['quiz_json']))      { $fields[] = 'quiz_json = :quiz';       $params['quiz'] = json_encode($data['quiz_json'], JSON_UNESCAPED_UNICODE); }

if (empty($fields)) sendError("لا يوجد بيانات للتحديث");

$query = "UPDATE lecture_ai_content SET " . implode(', ', $fields) . " WHERE lecture_id = :lid";
$stmt = $db->prepare($query);
$stmt->execute($params);

sendSuccess("Edited");