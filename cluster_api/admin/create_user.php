<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");

require_once '../config/database.php';
require_once '../helpers/response.php';

$database = new Database();
$db = $database->getConnection();
$data = json_decode(file_get_contents("php://input"));

if (!empty($data->full_name) && !empty($data->email) && !empty($data->role)) {
    try {
        $db->beginTransaction();

        
        $q1 = "INSERT INTO users (full_name, email, password_hash, role, status, is_activated) 
               VALUES (:name, :email, '123456', :role, 'pending', 0)";
        $stmt1 = $db->prepare($q1);
        $stmt1->execute([
            'name' => $data->full_name,
            'email' => $data->email,
            'role' => $data->role
        ]);
        $userId = $db->lastInsertId();

        
        if ($data->role == 'student') {
            $q2 = "INSERT INTO students (user_id, student_num, faculty) VALUES (:uid, :num, :fac)";
            $stmt2 = $db->prepare($q2);
            $stmt2->execute(['uid' => $userId, 'num' => $data->id_num, 'fac' => $data->faculty]);
        } else {
            $q2 = "INSERT INTO instructors (user_id, employee_num, department) VALUES (:uid, :num, :dept)";
            $stmt2 = $db->prepare($q2);
            $stmt2->execute(['uid' => $userId, 'num' => $data->id_num, 'dept' => $data->faculty]);
        }

        
        $code = substr(str_shuffle("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"), 0, 6);
        $q3 = "INSERT INTO activation_codes (user_id, code, expires_at) VALUES (:uid, :code, DATE_ADD(NOW(), INTERVAL 7 DAY))";
        $stmt3 = $db->prepare($q3);
        $stmt3->execute(['uid' => $userId, 'code' => $code]);

        $db->commit();
        sendSuccess("User created", ["activation_code" => $code]);
    } catch (Exception $e) {
        $db->rollBack();
        sendError($e->getMessage());
    }
} else {
    sendError("Incomplete data");
}