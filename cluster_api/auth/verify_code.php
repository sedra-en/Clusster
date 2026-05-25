<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");

require_once '../config/database.php';
require_once '../helpers/response.php';

$database = new Database();
$db = $database->getConnection();
$data = json_decode(file_get_contents("php://input"));

if (!empty($data->email) && !empty($data->code)) {
    $query = "SELECT u.id, u.full_name, u.is_activated FROM users u 
              JOIN activation_codes ac ON u.id = ac.user_id 
              WHERE u.email = :email AND ac.code = :code AND ac.is_used = 0 LIMIT 1";
    $stmt = $db->prepare($query);
    $stmt->execute(['email' => $data->email, 'code' => $data->code]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($user) {
        if ($user['is_activated']) {
            sendError("الحساب مفعّل مسبقاً");
        }
        sendSuccess("Code verified", $user);
    } else {
        sendError("البريد أو الكود غير صحيح");
    }
} else {
    sendError("بيانات ناقصة");
}