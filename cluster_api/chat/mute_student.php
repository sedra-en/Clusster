<?php
require_once __DIR__ . '/_helpers.php';

$courseId      = (int)getParam('course_id', 0);
$instructorId  = (int)getParam('user_id', 0);
$studentUserId = (int)getParam('student_user_id', 0);
$reason        = trim((string)getParam('reason', ''));

if ($courseId <= 0 || $instructorId <= 0 || $studentUserId <= 0) {
    sendError('معطيات ناقصة');
}

if (!isCourseInstructor($pdo, $instructorId, $courseId)) {
    sendError('فقط دكتور المقرر يقدر يكتم', 403);
}

$role = getUserRole($pdo, $studentUserId);
if ($role !== 'student') sendError('لا يمكن كتم هذا المستخدم');

$stmt = $pdo->prepare("
    INSERT INTO course_chat_muted (course_id, student_user_id, muted_by_user_id, reason)
    VALUES (:cid, :sid, :iid, :reason)
    ON DUPLICATE KEY UPDATE reason = VALUES(reason), muted_at = NOW()
");
$stmt->execute([
    ':cid' => $courseId, ':sid' => $studentUserId,
    ':iid' => $instructorId, ':reason' => $reason,
]);

sendSuccess([
    'course_id' => $courseId,
    'student_user_id' => $studentUserId,
], '🚫 تم كتم الطالب');