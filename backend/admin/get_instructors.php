<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once '../config/database.php';
require_once '../helpers/response.php';

$db = (new Database())->getConnection();

try {
    // ملاحظة مهمة: المعرف هنا هو instructors.id (وليس users.id)
    // لأن جدول courses يربط بـ instructors.id
    $stmt = $db->query("
        SELECT
          i.id              AS instructor_id,
          i.user_id,
          u.full_name,
          u.email,
          u.status,
          i.employee_num,
          i.department,
          i.specialization,
          i.experience_years,
          (SELECT COUNT(*) FROM courses c WHERE c.instructor_id = i.id) AS courses_count
        FROM instructors i
        JOIN users u ON u.id = i.user_id
        WHERE u.role = 'instructor'
        ORDER BY u.full_name ASC
    ");
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    sendSuccess("Instructors fetched", $rows);
} catch (Exception $e) {
    sendError("خطأ: " . $e->getMessage());
}
