<?php
require_once __DIR__ . '/_helpers.php';

$messageId = (int)getParam('message_id', 0);
$userId    = (int)getParam('user_id', 0);

if ($messageId <= 0 || $userId <= 0) sendError('معطيات ناقصة');

$q = $pdo->prepare("
    SELECT id, course_id, sender_user_id, is_deleted, created_at, file_path
    FROM course_chat_messages WHERE id = :id LIMIT 1
");
$q->execute([':id' => $messageId]);
$msg = $q->fetch(PDO::FETCH_ASSOC);

if (!$msg) sendError('الرسالة غير موجودة', 404);
if ($msg['is_deleted']) sendError('الرسالة محذوفة مسبقاً');

$courseId = (int)$msg['course_id'];
$isMine = ((int)$msg['sender_user_id'] === $userId);
$isInstructor = isCourseInstructor($pdo, $userId, $courseId);

$deletedByRole = null;
if ($isMine) {
    $age = time() - strtotime($msg['created_at']);
    if ($age > 900 && !$isInstructor) {
        sendError('انتهت مدة الحذف (15 دقيقة)');
    }
    $deletedByRole = 'self';
} elseif ($isInstructor) {
    $deletedByRole = 'instructor';
} else {
    sendError('لا يمكنك حذف هذه الرسالة', 403);
}

$stmt = $pdo->prepare("
    UPDATE course_chat_messages 
    SET is_deleted = 1, deleted_at = NOW(), deleted_by_role = :role
    WHERE id = :id
");
$stmt->execute([':role' => $deletedByRole, ':id' => $messageId]);

if ($msg['file_path']) {
    $imgPath = __DIR__ . '/../uploads/chat/' . $msg['file_path'];
    if (file_exists($imgPath)) @unlink($imgPath);
}

$signalFile = __DIR__ . "/../uploads/chat_signals/course_{$courseId}.txt";
file_put_contents($signalFile, $messageId);

sendSuccess(['id' => $messageId, 'deleted_by_role' => $deletedByRole], 'تم الحذف');