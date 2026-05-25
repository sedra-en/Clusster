<?php
require_once __DIR__ . '/../cors.php';
require_once '../config/database.php';
require_once '../helpers/response.php';

$db = (new Database())->getConnection();
$target_dir = __DIR__ . "/../uploads/";

if (!is_dir($target_dir)) mkdir($target_dir, 0777, true);

if (empty($_POST['course_id']) || (empty($_FILES['file']) && empty($_FILES['audio']))) {
    sendError("course_id والملف مطلوبين");
}

$course_id   = $_POST['course_id'];
$title       = $_POST['title'] ?? 'Untitled Lecture';
$file_path   = null;
$audio_path  = null;
$orig_name   = null;
$file_size   = null;
$content_type = 'pdf';

$audio_exts = ['mp3', 'ogg', 'wav', 'm4a', 'aac'];
$image_exts = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

if (!empty($_FILES['file']) && $_FILES['file']['error'] === UPLOAD_ERR_OK) {
    $orig_name = $_FILES["file"]["name"];
    $ext       = strtolower(pathinfo($orig_name, PATHINFO_EXTENSION));
    $file_size = (int)$_FILES['file']['size'];
    $unique    = time() . "_" . uniqid() . "." . $ext;

    if (!move_uploaded_file($_FILES["file"]["tmp_name"], $target_dir . $unique)) {
        sendError("فشل رفع الملف");
    }
    $file_path = $unique;

    if (in_array($ext, $audio_exts, true)) {
        $content_type = 'audio';
    } elseif (in_array($ext, $image_exts, true)) {
        $content_type = 'image';
    } elseif ($ext === 'pdf') {
        $content_type = 'pdf';
    } else {
        $content_type = 'pdf';
    }
}

if (!empty($_FILES['audio']) && $_FILES['audio']['error'] === UPLOAD_ERR_OK) {
    $audio_orig = $_FILES["audio"]["name"];
    $audio_ext  = strtolower(pathinfo($audio_orig, PATHINFO_EXTENSION));
    $audio_unique = time() . "_audio_" . uniqid() . "." . $audio_ext;

    if (!move_uploaded_file($_FILES["audio"]["tmp_name"], $target_dir . $audio_unique)) {
        sendError("فشل رفع الصوت");
    }
    $audio_path = $audio_unique;

    if (!$orig_name) {
        $orig_name = $audio_orig;
        $file_size = (int)$_FILES['audio']['size'];
        $content_type = 'audio';
    }
}

try {
    $stmt = $db->prepare("
        INSERT INTO lectures
            (course_id, title, file_name, file_path, audio_path, content_type, file_size)
        VALUES
            (:cid, :title, :fname, :path, :audio, :type, :size)
    ");
    $stmt->execute([
        'cid'   => $course_id,
        'title' => $title,
        'fname' => $orig_name,
        'path'  => $file_path,
        'audio' => $audio_path,
        'type'  => $content_type,
        'size'  => $file_size,
    ]);

    sendSuccess("Lecture uploaded", [
        "lecture_id"   => (int)$db->lastInsertId(),
        "file_path"    => $file_path,
        "audio_path"   => $audio_path,
        "content_type" => $content_type,
    ]);
} catch (Exception $e) {
    sendError("خطأ DB: " . $e->getMessage());
}