<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once '../config/database.php';
require_once '../helpers/response.php';

$database = new Database();
$db = $database->getConnection();

try {
    // عدد الطلاب
    $stmt = $db->query("SELECT COUNT(*) as count FROM users WHERE role = 'student'");
    $studentsCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];

    // عدد المدرسين
    $stmt = $db->query("SELECT COUNT(*) as count FROM users WHERE role = 'instructor'");
    $instructorsCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];

    // عدد الكورسات
    $stmt = $db->query("SELECT COUNT(*) as count FROM courses");
    $coursesCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];

    sendSuccess("Dashboard stats fetched", [
        "students" => (int)$studentsCount,
        "instructors" => (int)$instructorsCount,
        "courses" => (int)$coursesCount
    ]);

} catch (Exception $e) {
    sendError($e->getMessage());
}