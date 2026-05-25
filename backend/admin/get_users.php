<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once '../config/database.php';
require_once '../helpers/response.php';

$database = new Database();
$db = $database->getConnection();

try {
    $query = "SELECT id, full_name, email, role, status, is_activated, created_at FROM users WHERE role != 'admin' ORDER BY created_at DESC";
    $stmt = $db->prepare($query);
    $stmt->execute();
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

    sendSuccess("Users list", $users);
} catch (Exception $e) {
    sendError($e->getMessage());
}