<?php
require_once __DIR__ . '/_helpers.php';

$courseId     = (int)getParam('course_id', 0);
$instructorId = (int)getParam('user_id', 0);

if ($courseId <= 0 || $instructorId <= 0) sendError('معطيات ناقصة');

if (!isCourseInstructor($pdo, $instructorId, $courseId)) {
    sendError('فقط دكتور المقرر', 403);
}

$stmt = $pdo->prepare("
    SELECT m.id, m.student_user_id, m.reason, m.muted_at,
           u.full_name, u.email
    FROM course_chat_muted m
    INNER JOIN users u ON m.student_user_id = u.id
    WHERE m.course_id = :cid
    ORDER BY m.muted_at DESC
");
$stmt->execute([':cid' => $courseId]);
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

$list = [];
foreach ($rows as $row) {
    $list[] = [
        'id'              => (int)$row['id'],
        'student_user_id' => (int)$row['student_user_id'],
        'full_name'       => $row['full_name'],
        'email'           => $row['email'],
        'reason'          => $row['reason'],
        'muted_at'        => $row['muted_at'],
    ];
}

sendSuccess($list, 'قائمة المكتومين');