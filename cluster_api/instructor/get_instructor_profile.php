<?php
require_once __DIR__ . '/../cors.php';
require_once '../config/database.php';
require_once '../helpers/response.php';

$db = (new Database())->getConnection();

$userId = $_GET['user_id'] ?? null;
$instructorId = $_GET['instructor_id'] ?? null;

if (!$userId && !$instructorId) {
    sendError("user_id أو instructor_id مطلوب");
}

try {
    if ($userId) {
        $stmt = $db->prepare("
            SELECT
              i.id            AS instructor_id,
              i.user_id,
              u.full_name, u.email, u.status, u.is_activated, u.created_at,
              i.employee_num, i.department, i.specialization,
              i.experience_years,
              (SELECT COUNT(*) FROM courses c WHERE c.instructor_id = i.id) AS courses_count,
              (SELECT COUNT(*) FROM lectures l
                 JOIN courses c ON c.id = l.course_id
                 WHERE c.instructor_id = i.id) AS lectures_count
            FROM instructors i
            JOIN users u ON u.id = i.user_id
            WHERE u.id = :uid
            LIMIT 1
        ");
        $stmt->execute(['uid' => $userId]);
    } else {
        $stmt = $db->prepare("
            SELECT
              i.id            AS instructor_id,
              i.user_id,
              u.full_name, u.email, u.status, u.is_activated, u.created_at,
              i.employee_num, i.department, i.specialization,
              i.experience_years,
              (SELECT COUNT(*) FROM courses c WHERE c.instructor_id = i.id) AS courses_count,
              (SELECT COUNT(*) FROM lectures l
                 JOIN courses c ON c.id = l.course_id
                 WHERE c.instructor_id = i.id) AS lectures_count
            FROM instructors i
            JOIN users u ON u.id = i.user_id
            WHERE i.id = :iid
            LIMIT 1
        ");
        $stmt->execute(['iid' => $instructorId]);
    }
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$row) sendError("الدكتور غير موجود", 404);
    sendSuccess("Profile fetched", $row);
} catch (Exception $e) {
    sendError("خطأ: " . $e->getMessage());
}