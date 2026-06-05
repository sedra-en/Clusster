<?php
require_once __DIR__ . '/_helpers.php';

$courseId      = (int)getParam('course_id', 0);
$instructorId  = (int)getParam('user_id', 0);
$studentUserId = (int)getParam('student_user_id', 0);

if ($courseId <= 0 || $instructorId <= 0 || $studentUserId <= 0) {
    sendError('معطيات ناقصة');
}

if (!isCourseInstructor($pdo, $instructorId, $courseId)) {
    sendError('فقط دكتور المقرر يقدر يفك الكتم', 403);
}

$stmt = $pdo->prepare("
    DELETE FROM course_chat_muted 
    WHERE course_id = :cid AND student_user_id = :sid
");
$stmt->execute([':cid' => $courseId, ':sid' => $studentUserId]);

if ($stmt->rowCount() === 0) {
    sendError('الطالب ليس مكتوماً');
}

sendSuccess(null, ' تم فك الكتم');