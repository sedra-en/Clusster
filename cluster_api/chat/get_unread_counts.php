<?php
require_once __DIR__ . '/_helpers.php';

$userId = (int)getParam('user_id', 0);
if ($userId <= 0) sendError('user_id مطلوب');

$role = getUserRole($pdo, $userId);
if (!$role) sendError('مستخدم غير صالح', 404);

$coursesIds = [];

if ($role === 'student') {
    $q = $pdo->prepare("
        SELECT e.course_id FROM enrollments e
        INNER JOIN students s ON e.student_id = s.id
        WHERE s.user_id = :uid AND e.is_active = 1
    ");
    $q->execute([':uid' => $userId]);
    while ($row = $q->fetch(PDO::FETCH_ASSOC)) {
        $coursesIds[] = (int)$row['course_id'];
    }
} elseif ($role === 'instructor') {
    $q = $pdo->prepare("
        SELECT c.id FROM courses c
        INNER JOIN instructors i ON c.instructor_id = i.id
        WHERE i.user_id = :uid
    ");
    $q->execute([':uid' => $userId]);
    while ($row = $q->fetch(PDO::FETCH_ASSOC)) {
        $coursesIds[] = (int)$row['id'];
    }
} else {
    sendSuccess(['per_course' => [], 'total' => 0]);
}

if (empty($coursesIds)) {
    sendSuccess(['per_course' => [], 'total' => 0]);
}

$ids = implode(',', $coursesIds);

$sql = "
    SELECT m.course_id, COUNT(*) AS unread
    FROM course_chat_messages m
    LEFT JOIN course_chat_reads r 
        ON r.course_id = m.course_id AND r.user_id = :uid1
    WHERE m.course_id IN ({$ids})
      AND m.is_deleted = 0
      AND m.sender_user_id != :uid2
      AND m.id > COALESCE(r.last_read_message_id, 0)
    GROUP BY m.course_id
";

$stmt = $pdo->prepare($sql);
$stmt->execute([':uid1' => $userId, ':uid2' => $userId]);
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

$perCourse = [];
$total = 0;
foreach ($rows as $row) {
    $cid = (int)$row['course_id'];
    $count = (int)$row['unread'];
    $perCourse[$cid] = $count;
    $total += $count;
}

sendSuccess(['per_course' => $perCourse, 'total' => $total]);