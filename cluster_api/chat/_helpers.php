<?php

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

require_once __DIR__ . '/../config/database.php';

$db = new Database();
$pdo = $db->getConnection();

if (!$pdo) {
    http_response_code(500);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'status' => 'error',
        'message' => 'فشل الاتصال بقاعدة البيانات',
        'data' => null
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

function sendSuccess($data = null, $message = 'success') {
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'status'  => 'success',
        'message' => $message,
        'data'    => $data,
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

function sendError($message = 'error', $code = 400) {
    http_response_code($code);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'status'  => 'error',
        'message' => $message,
        'data'    => null,
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

function getBody() {
    $body = file_get_contents('php://input');
    $json = json_decode($body, true);
    return is_array($json) ? $json : $_POST;
}

function getParam($key, $default = null) {
    $body = getBody();
    if (isset($body[$key])) return $body[$key];
    if (isset($_GET[$key])) return $_GET[$key];
    if (isset($_POST[$key])) return $_POST[$key];
    return $default;
}

function canAccessCourseChat($pdo, $userId, $courseId) {
    $userId = (int)$userId;
    $courseId = (int)$courseId;
    
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
            WHERE e.course_id = :cid AND s.user_id = :uid AND e.is_active = 1
            LIMIT 1
        ");
        $q->execute([':cid' => $courseId, ':uid' => $userId]);
        return $q->fetch(PDO::FETCH_ASSOC) !== false;
    }
    
    return false;
}

function isCourseInstructor($pdo, $userId, $courseId) {
    $stmt = $pdo->prepare("
        SELECT c.id FROM courses c
        INNER JOIN instructors i ON c.instructor_id = i.id
        INNER JOIN users u ON i.user_id = u.id
        WHERE c.id = :cid AND u.id = :uid AND u.role = 'instructor' LIMIT 1
    ");
    $stmt->execute([':cid' => (int)$courseId, ':uid' => (int)$userId]);
    return $stmt->fetch(PDO::FETCH_ASSOC) !== false;
}

function isStudentMuted($pdo, $userId, $courseId) {
    $stmt = $pdo->prepare("
        SELECT id FROM course_chat_muted 
        WHERE course_id = :cid AND student_user_id = :uid LIMIT 1
    ");
    $stmt->execute([':cid' => (int)$courseId, ':uid' => (int)$userId]);
    return $stmt->fetch(PDO::FETCH_ASSOC) !== false;
}

function getUserRole($pdo, $userId) {
    $stmt = $pdo->prepare("SELECT role FROM users WHERE id = :id LIMIT 1");
    $stmt->execute([':id' => (int)$userId]);
    $r = $stmt->fetch(PDO::FETCH_ASSOC);
    return $r ? $r['role'] : null;
}

function formatMessage($row, $currentUserId) {
    $isDeleted = (bool)$row['is_deleted'];
    $isMine = ((int)$row['sender_user_id'] === (int)$currentUserId);
    
    return [
        'id'              => (int)$row['id'],
        'course_id'       => (int)$row['course_id'],
        'sender_id'       => (int)$row['sender_user_id'],
        'sender_name'     => $row['sender_name'] ?? 'مستخدم',
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

function validateImageUpload($file, $maxSizeMB = 10) {
    if (!isset($file) || $file['error'] !== UPLOAD_ERR_OK) {
        return [false, 'فشل رفع الملف'];
    }
    $maxBytes = $maxSizeMB * 1024 * 1024;
    if ($file['size'] > $maxBytes) return [false, "الحجم الأقصى {$maxSizeMB}MB"];
    
    $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    $allowed = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
    if (!in_array($ext, $allowed)) return [false, 'صيغة الصورة غير مدعومة'];
    
    return [true, $ext];
}

function generateUniqueFilename($ext, $prefix = 'chat') {
    return $prefix . '_' . time() . '_' . uniqid() . '.' . $ext;
}