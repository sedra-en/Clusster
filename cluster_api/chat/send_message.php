<?php
require_once __DIR__ . '/_helpers.php';

$courseId  = (int)($_POST['course_id']  ?? getParam('course_id', 0));
$senderId  = (int)($_POST['sender_id']  ?? getParam('sender_id', 0));
$content   = trim((string)($_POST['content'] ?? getParam('content', '')));
$replyTo   = ($_POST['reply_to_id'] ?? getParam('reply_to_id'));
$replyTo   = $replyTo ? (int)$replyTo : null;

if ($courseId <= 0 || $senderId <= 0) {
    sendError('course_id و sender_id مطلوبان');
}

if (!canAccessCourseChat($pdo, $senderId, $courseId)) {
    sendError('ليس لديك صلاحية الإرسال في هذا المقرر', 403);
}

$senderRole = getUserRole($pdo, $senderId);
if (!$senderRole) sendError('مستخدم غير صالح', 404);

if ($senderRole === 'student' && isStudentMuted($pdo, $senderId, $courseId)) {
    sendError(' لقد تم كتمك في هذه الغرفة', 403);
}

if ($replyTo !== null) {
    $check = $pdo->prepare("
        SELECT id FROM course_chat_messages 
        WHERE id = :id AND course_id = :cid AND is_deleted = 0 LIMIT 1
    ");
    $check->execute([':id' => $replyTo, ':cid' => $courseId]);
    if ($check->fetch(PDO::FETCH_ASSOC) === false) {
        $replyTo = null;
    }
}

$messageType = 'text';
$filePath = null;
$fileName = null;
$fileSize = null;

if (isset($_FILES['file']) && $_FILES['file']['error'] !== UPLOAD_ERR_NO_FILE) {
    [$ok, $extOrErr] = validateImageUpload($_FILES['file'], 10);
    if (!$ok) sendError($extOrErr);
    
    $uploadDir = __DIR__ . '/../uploads/chat/';
    if (!is_dir($uploadDir)) {
        if (!mkdir($uploadDir, 0777, true)) {
            sendError('فشل إنشاء مجلد الرفع', 500);
        }
    }
    
    $newName = generateUniqueFilename($extOrErr, 'chat');
    $dest = $uploadDir . $newName;
    
    if (!move_uploaded_file($_FILES['file']['tmp_name'], $dest)) {
        sendError('فشل حفظ الصورة', 500);
    }
    
    $messageType = 'image';
    $filePath = $newName;
    $fileName = $_FILES['file']['name'];
    $fileSize = (int)$_FILES['file']['size'];
}

if ($messageType === 'text' && $content === '') {
    sendError('لا يمكن إرسال رسالة فارغة');
}

$pdo->beginTransaction();
try {
    $stmt = $pdo->prepare("
        INSERT INTO course_chat_messages 
        (course_id, sender_user_id, sender_role, message_type, content, 
         file_path, file_name, file_size, reply_to_id)
        VALUES (:cid, :sid, :srole, :mtype, :content, :fpath, :fname, :fsize, :reply)
    ");
    $stmt->execute([
        ':cid' => $courseId, ':sid' => $senderId, ':srole' => $senderRole,
        ':mtype' => $messageType, ':content' => $content,
        ':fpath' => $filePath, ':fname' => $fileName, ':fsize' => $fileSize,
        ':reply' => $replyTo,
    ]);
    $messageId = (int)$pdo->lastInsertId();
    
    $upd = $pdo->prepare("
        INSERT INTO course_chat_reads (course_id, user_id, last_read_message_id)
        VALUES (:cid, :uid, :mid)
        ON DUPLICATE KEY UPDATE last_read_message_id = VALUES(last_read_message_id)
    ");
    $upd->execute([':cid' => $courseId, ':uid' => $senderId, ':mid' => $messageId]);
    
    $pdo->commit();
} catch (Exception $e) {
    $pdo->rollBack();
    sendError('فشل إرسال الرسالة: ' . $e->getMessage(), 500);
}

// إشعار SSE
$signalDir = __DIR__ . '/../uploads/chat_signals/';
if (!is_dir($signalDir)) mkdir($signalDir, 0777, true);
file_put_contents($signalDir . "course_{$courseId}.txt", $messageId);

$q = $pdo->prepare("
    SELECT m.*, u.full_name AS sender_name
    FROM course_chat_messages m
    INNER JOIN users u ON m.sender_user_id = u.id
    WHERE m.id = :id
");
$q->execute([':id' => $messageId]);
$row = $q->fetch(PDO::FETCH_ASSOC);

sendSuccess(formatMessage($row, $senderId), 'تم الإرسال');