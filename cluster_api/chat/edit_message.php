<?php
require_once __DIR__ . '/_helpers.php';

$messageId  = (int)getParam('message_id', 0);
$userId     = (int)getParam('user_id', 0);
$newContent = trim((string)getParam('content', ''));

if ($messageId <= 0 || $userId <= 0 || $newContent === '') {
    sendError('معطيات ناقصة');
}

$q = $pdo->prepare("
    SELECT id, course_id, sender_user_id, message_type, is_deleted, created_at
    FROM course_chat_messages WHERE id = :id LIMIT 1
");
$q->execute([':id' => $messageId]);
$msg = $q->fetch(PDO::FETCH_ASSOC);

if (!$msg) sendError('الرسالة غير موجودة', 404);
if ($msg['is_deleted']) sendError('الرسالة محذوفة');
if ((int)$msg['sender_user_id'] !== $userId) sendError('لا يمكنك تعديل رسائل غيرك', 403);
if ($msg['message_type'] !== 'text') sendError('يمكن تعديل النصوص فقط');

$age = time() - strtotime($msg['created_at']);
if ($age > 300) sendError('انتهت مدة التعديل (5 دقائق)');

$stmt = $pdo->prepare("
    UPDATE course_chat_messages 
    SET content = :content, is_edited = 1, edited_at = NOW()
    WHERE id = :id
");
$stmt->execute([':content' => $newContent, ':id' => $messageId]);

$signalFile = __DIR__ . "/../uploads/chat_signals/course_{$msg['course_id']}.txt";
file_put_contents($signalFile, $messageId);

sendSuccess(['id' => $messageId, 'content' => $newContent], 'تم التعديل');