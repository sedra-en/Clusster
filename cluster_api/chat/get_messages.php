<?php
require_once __DIR__ . '/_helpers.php';

$courseId = (int)getParam('course_id', 0);
$userId   = (int)getParam('user_id', 0);
$limit    = (int)getParam('limit', 50);
$beforeId = getParam('before_id') ? (int)getParam('before_id') : null;
$afterId  = getParam('after_id') ? (int)getParam('after_id') : null;

if ($courseId <= 0 || $userId <= 0) {
    sendError('course_id و user_id مطلوبان');
}

if (!canAccessCourseChat($pdo, $userId, $courseId)) {
    sendError('ليس لديك صلاحية الوصول لهذا المقرر', 403);
}

$limit = max(1, min(100, $limit));

$where = "m.course_id = :course_id";
$params = [':course_id' => $courseId];

if ($beforeId !== null) {
    $where .= " AND m.id < :before_id";
    $params[':before_id'] = $beforeId;
}

if ($afterId !== null) {
    $where .= " AND m.id > :after_id";
    $params[':after_id'] = $afterId;
}

$order = ($afterId !== null) ? "ASC" : "DESC";

$sql = "
    SELECT 
        m.id, m.course_id, m.sender_user_id, m.sender_role,
        m.message_type, m.content, m.file_path, m.file_name, m.file_size,
        m.is_edited, m.edited_at, m.is_deleted, m.deleted_by_role,
        m.reply_to_id, m.created_at,
        u.full_name AS sender_name
    FROM course_chat_messages m
    INNER JOIN users u ON m.sender_user_id = u.id
    WHERE {$where}
    ORDER BY m.id {$order}
    LIMIT {$limit}
";

$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

$messages = [];
foreach ($rows as $row) {
    $messages[] = formatMessage($row, $userId);
}

if ($order === "DESC") {
    $messages = array_reverse($messages);
}

if (!empty($messages) && $afterId === null) {
    $lastId = end($messages)['id'];
    reset($messages);
    
    $upd = $pdo->prepare("
        INSERT INTO course_chat_reads (course_id, user_id, last_read_message_id)
        VALUES (:cid, :uid, :mid)
        ON DUPLICATE KEY UPDATE 
            last_read_message_id = GREATEST(last_read_message_id, VALUES(last_read_message_id))
    ");
    $upd->execute([':cid' => $courseId, ':uid' => $userId, ':mid' => $lastId]);
}

sendSuccess($messages, 'تم جلب الرسائل');