<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once '../config/database.php';
require_once '../helpers/response.php';

$db = (new Database())->getConnection();

try {
    $stmt = $db->query("
        SELECT
          s.id, s.name, s.code, s.start_date, s.end_date, s.is_active, s.created_at,
          (SELECT COUNT(*) FROM courses c WHERE c.semester_id = s.id) AS courses_count
        FROM semesters s
        ORDER BY s.is_active DESC, s.start_date DESC
    ");
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    sendSuccess("Semesters fetched", $rows);
} catch (Exception $e) {
    sendError("خطأ: " . $e->getMessage());
}
