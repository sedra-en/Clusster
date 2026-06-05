<?php
require_once '../config/database.php';
require_once '../helpers/response.php';
$db = (new Database())->getConnection();
$data = json_decode(file_get_contents("php://input"));

if (!empty($data->user_id) && !empty($data->password)) {
    $hashed = password_hash($data->password, PASSWORD_DEFAULT); 
    $stmt = $db->prepare("UPDATE users SET is_activated = 1, status = 'active', password_hash = ? WHERE id = ?");
    if ($stmt->execute([$hashed, $data->user_id])) {
        $db->prepare("UPDATE activation_codes SET is_used = 1 WHERE user_id = ?")->execute([$data->user_id]);
        sendSuccess("Activated");
    }
}