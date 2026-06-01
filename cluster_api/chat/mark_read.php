<?php
require_once __DIR__ . '/_helpers.php';

$courseId = (int)getParam('course_id', 0);
$userId   = (int)getParam('user_id', 0);

if ($courseId <= 0 || $userId <= 0) sendError('معطيات ناقصة');

if (!canAccessCourseChat($pdo, $userId, $courseId)) {
    sendError('ليس لديك صلاحية', 403);
}

$q = $pdo->prepare("SELECT MAX(id) AS last_id FROM course_chat_messages WHERE course_id = :cid");
$q->execute([':cid' => $courseId]);
$r = $q->fetch(PDO::FETCH_ASSOC);
$lastId = (int)($r['last_id'] ?? 0);

if ($lastId === 0) {
    sendSuccess(['last_read_message_id' => 0], 'لا يوجد رسائل');
}

$upd = $pdo->prepare("
    INSERT INTO course_chat_reads (course_id, user_id, last_read_message_id)
    VALUES (:cid, :uid, :mid)
    ON DUPLICATE KEY UPDATE 
        last_read_message_id = GREATEST(last_read_message_id, VALUES(last_read_message_id))
");
$upd->execute([':cid' => $courseId, ':uid' => $userId, ':mid' => $lastId]);

sendSuccess(['last_read_message_id' => $lastId], '✅ تم التحديد');