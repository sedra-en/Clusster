<?php
set_time_limit(0);
ini_set('output_buffering', 'off');
ini_set('zlib.output_compression', false);

header('Content-Type: text/event-stream; charset=utf-8');
header('Cache-Control: no-cache');
header('Connection: keep-alive');
header('X-Accel-Buffering: no');
header('Access-Control-Allow-Origin: *');

if (function_exists('apache_setenv')) {
    @apache_setenv('no-gzip', 1);
}
@ini_set('zlib.output_compression', 0);
@ini_set('implicit_flush', 1);

while (ob_get_level() > 0) ob_end_flush();
ob_implicit_flush(1);

require_once __DIR__ . '/../config/database.php';
$db = new Database();
$pdo = $db->getConnection();

if (!$pdo) {
    sendSSEEvent('error', ['message' => 'فشل الاتصال بقاعدة البيانات']);
    exit;
}

$courseId = isset($_GET['course_id']) ? (int)$_GET['course_id'] : 0;
$userId   = isset($_GET['user_id'])   ? (int)$_GET['user_id']   : 0;
$lastId   = isset($_GET['last_id'])   ? (int)$_GET['last_id']   : 0;

if ($courseId <= 0 || $userId <= 0) {
    sendSSEEvent('error', ['message' => 'معطيات ناقصة']);
    exit;
}

if (!checkCourseAccess($pdo, $userId, $courseId)) {
    sendSSEEvent('error', ['message' => 'ليس لديك صلاحية']);
    exit;
}

sendSSEEvent('connected', [
    'message'   => ' متصل',
    'course_id' => $courseId,
    'user_id'   => $userId,
]);

$signalFile = __DIR__ . '/../uploads/chat_signals/' . "course_{$courseId}.txt";
$signalDir  = dirname($signalFile);
if (!is_dir($signalDir)) mkdir($signalDir, 0777, true);

$lastSignalMtime = file_exists($signalFile) ? filemtime($signalFile) : 0;
$startTime = time();
$maxDuration = 300;
$heartbeatInterval = 15;
$lastHeartbeat = time();

while (true) {
    if (connection_aborted()) break;
    
    if ((time() - $startTime) > $maxDuration) {
        sendSSEEvent('timeout', ['message' => 'إعادة الاتصال']);
        break;
    }
    
    clearstatcache(true, $signalFile);
    $currentMtime = file_exists($signalFile) ? filemtime($signalFile) : 0;
    
    if ($currentMtime > $lastSignalMtime) {
        $newMessages = fetchNewMessages($pdo, $courseId, $userId, $lastId);
        
        if (!empty($newMessages)) {
            foreach ($newMessages as $msg) {
                sendSSEEvent('message', $msg);
                $lastId = $msg['id'];
            }
        }
        
        $lastSignalMtime = $currentMtime;
    }
    
    if ((time() - $lastHeartbeat) >= $heartbeatInterval) {
        sendSSEEvent('ping', ['t' => time()]);
        $lastHeartbeat = time();
    }
    
    usleep(500000);
}

function sendSSEEvent($event, $data) {
    echo "event: {$event}\n";
    echo "data: " . json_encode($data, JSON_UNESCAPED_UNICODE) . "\n\n";
    @ob_flush();
    @flush();
}

function checkCourseAccess($pdo, $userId, $courseId) {
    $stmt = $pdo->prepare("SELECT role FROM users WHERE id = :id LIMIT 1");
    $stmt->execute([':id' => $userId]);
    $r = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$r) return false;
    if ($r['role'] === 'admin') return true;
    
    if ($r['role'] === 'instructor') {
        $q = $pdo->prepare("
            SELECT c.id FROM courses c
            INNER JOIN instructors i ON c.instructor_id = i.id
            WHERE c.id = :cid AND i.user_id = :uid LIMIT 1
        ");
        $q->execute([':cid' => $courseId, ':uid' => $userId]);
        return $q->fetch(PDO::FETCH_ASSOC) !== false;
    }
    
    if ($r['role'] === 'student') {
        $q = $pdo->prepare("
            SELECT e.id FROM enrollments e
            INNER JOIN students s ON e.student_id = s.id
            WHERE e.course_id = :cid AND s.user_id = :uid AND e.is_active = 1 LIMIT 1
        ");
        $q->execute([':cid' => $courseId, ':uid' => $userId]);
        return $q->fetch(PDO::FETCH_ASSOC) !== false;
    }
    
    return false;
}

function fetchNewMessages($pdo, $courseId, $userId, $afterId) {
    $stmt = $pdo->prepare("
        SELECT m.id, m.course_id, m.sender_user_id, m.sender_role,
               m.message_type, m.content, m.file_path, m.file_name, m.file_size,
               m.is_edited, m.edited_at, m.is_deleted, m.deleted_by_role,
               m.reply_to_id, m.created_at,
               u.full_name AS sender_name
        FROM course_chat_messages m
        INNER JOIN users u ON m.sender_user_id = u.id
        WHERE m.course_id = :cid AND m.id > :after_id
        ORDER BY m.id ASC
        LIMIT 50
    ");
    $stmt->execute([':cid' => $courseId, ':after_id' => $afterId]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $messages = [];
    foreach ($rows as $row) {
        $isMine = ((int)$row['sender_user_id'] === (int)$userId);
        $isDeleted = (bool)$row['is_deleted'];
        
        $messages[] = [
            'id'              => (int)$row['id'],
            'course_id'       => (int)$row['course_id'],
            'sender_id'       => (int)$row['sender_user_id'],
            'sender_name'     => $row['sender_name'],
            'sender_role'     => $row['sender_role'],
            'is_mine'         => $isMine,
            'message_type'    => $row['message_type'],
            'content'         => $isDeleted ? null : $row['content'],
            'file_path'       => $isDeleted ? null : $row['file_path'],
            'file_name'       => $isDeleted ? null : $row['file_name'],
            'file_size'       => $isDeleted ? null : ($row['file_size'] ? (int)$row['file_size'] : null),
            'is_edited'       => (bool)$row['is_edited'],
            'edited_at'       => $row['edited_at'],
            'is_deleted'      => $isDeleted,
            'deleted_by_role' => $row['deleted_by_role'],
            'reply_to_id'     => $row['reply_to_id'] ? (int)$row['reply_to_id'] : null,
            'created_at'      => $row['created_at'],
        ];
    }
    return $messages;
}