<?php
require_once __DIR__ . '/../cors.php';
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
          u.full_name,
          u.email,
          s.student_num,
          s.faculty,
          s.major,
          s.year,
          s.gpa
        FROM enrollments e
        JOIN students s ON s.id = e.student_id
        JOIN users u    ON u.id = s.user_id
        WHERE e.course_id = :cid AND e.is_active = 1
        ORDER BY u.full_name ASC
    ");
    $stmt->execute(['cid' => $courseId]);
    sendSuccess("Students fetched", $stmt->fetchAll(PDO::FETCH_ASSOC));
} catch (Exception $e) {
    sendError("خطأ: " . $e->getMessage());
}