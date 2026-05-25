<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once '../config/database.php';
require_once '../helpers/response.php';

$db = (new Database())->getConnection();

// فلترة اختيارية
$semesterId = $_GET['semester_id'] ?? null;
$status     = $_GET['status']      ?? null; // draft|published|hidden

$where = [];
$params = [];

if ($semesterId !== null && $semesterId !== '') {
    if ($semesterId === 'active') {
        // semester_id = الفصل الحالي
        $where[] = "c.semester_id = (SELECT id FROM semesters WHERE is_active = 1 LIMIT 1)";
    } else {
        $where[] = "c.semester_id = :sid";
        $params['sid'] = $semesterId;
    }
}
if ($status) {
    $where[] = "c.status = :st";
    $params['st'] = $status;
}

$whereSql = $where ? 'WHERE ' . implode(' AND ', $where) : '';

try {
    $stmt = $db->prepare("
        SELECT
          c.id, c.title, c.description, c.status, c.cover_color,
          c.created_at, c.updated_at,
          c.instructor_id, c.semester_id,
          u.full_name AS instructor_name,
          s.name      AS semester_name,
          s.code      AS semester_code,
          s.is_active AS semester_is_active,
          (SELECT COUNT(*) FROM enrollments e
             WHERE e.course_id = c.id AND e.is_active = 1) AS enrollments_count,
          (SELECT COUNT(*) FROM lectures l
             WHERE l.course_id = c.id) AS lectures_count
        FROM courses c
        LEFT JOIN instructors i ON i.id = c.instructor_id
        LEFT JOIN users u       ON u.id = i.user_id
        LEFT JOIN semesters s   ON s.id = c.semester_id
        $whereSql
        ORDER BY c.created_at DESC
    ");
    $stmt->execute($params);
    sendSuccess("Courses fetched", $stmt->fetchAll(PDO::FETCH_ASSOC));
} catch (Exception $e) {
    sendError("خطأ: " . $e->getMessage());
}
