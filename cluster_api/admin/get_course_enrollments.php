<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once '../config/database.php';
require_once '../helpers/response.php';

$db = (new Database())->getConnection();
$courseId = $_GET['course_id'] ?? null;

if (!$courseId) sendError("course_id مطلوب");

try {
    $stmt = $db->prepare("
        SELECT
          e.id          AS enrollment_id,
          e.student_id,
          e.enrolled_at,
          e.is_active,
          u.full_name,
          u.email,
          u.status,
          s.student_num,
          s.faculty,
          s.major,
          s.year,
          s.gpa
        FROM enrollments e
        JOIN students s ON s.id = e.student_id
        JOIN users u    ON u.id = s.user_id
        WHERE e.course_id = :cid
        ORDER BY e.enrolled_at DESC
    ");
    $stmt->execute(['cid' => $courseId]);
    sendSuccess("Enrollments fetched", $stmt->fetchAll(PDO::FETCH_ASSOC));
} catch (Exception $e) {
    sendError("خطأ: " . $e->getMessage());
}
