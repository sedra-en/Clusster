<?php
set_time_limit(0);
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: *");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }
header("Content-Type: application/json; charset=UTF-8");
require_once '../config/database.php';
require_once '../helpers/response.php';
 
$database = new Database();
$db = $database->getConnection();
$data = json_decode(file_get_contents("php://input"));
 
if (!empty($data->lecture_id)) {
    try {
        // ✅ تحقق إذا المحتوى موجود مسبقاً — منع التوليد المزدوج
        $checkStmt = $db->prepare("SELECT is_generated FROM lecture_ai_content WHERE lecture_id = ?");
        $checkStmt->execute([$data->lecture_id]);
        $existing = $checkStmt->fetch(PDO::FETCH_ASSOC);
        if ($existing && $existing['is_generated'] == 1) {
            sendSuccess("المحتوى موجود مسبقاً");
            exit();
        }
 
        // 1. جلب بيانات المحاضرة
        $query = "SELECT title, file_path, audio_path FROM lectures WHERE id = :id";
        $stmt  = $db->prepare($query);
        $stmt->bindParam(':id', $data->lecture_id);
        $stmt->execute();
        $lecture = $stmt->fetch(PDO::FETCH_ASSOC);
 
        if (!$lecture) sendError("المحاضرة غير موجودة");
 
        // 2. تحديد نوع الملف
        $uploadsDir = realpath("../uploads/") . DIRECTORY_SEPARATOR;
        $fileExt    = pathinfo($lecture['file_path'] ?? '', PATHINFO_EXTENSION);
        $audioExts  = ['ogg', 'mp3', 'wav', 'm4a', 'aac'];
 
        if (in_array(strtolower($fileExt), $audioExts)) {
            $filePath  = null;
            $audioPath = $uploadsDir . $lecture['file_path'];
        } else {
            $filePath  = $lecture['file_path']  ? $uploadsDir . $lecture['file_path']  : null;
            $audioPath = $lecture['audio_path'] ? $uploadsDir . $lecture['audio_path'] : null;
        }
 
        // 3. استدعاء main.py
        $aiResponse = callOurAPI($filePath, $audioPath);
 
        // 4. حفظ النتائج
        $insertQuery = "INSERT INTO lecture_ai_content 
                        (lecture_id, easy_summary, medium_summary, hard_summary, quiz_json, is_generated, generated_at) 
                        VALUES (:lid, :easy, :med, :hard, :quiz, 1, NOW())
                        ON DUPLICATE KEY UPDATE 
                        easy_summary   = VALUES(easy_summary),
                        medium_summary = VALUES(medium_summary),
                        hard_summary   = VALUES(hard_summary),
                        quiz_json      = VALUES(quiz_json),
                        is_generated   = 1,
                        generated_at   = NOW()";
 
        $iStmt = $db->prepare($insertQuery);
        $iStmt->execute([
            'lid'  => $data->lecture_id,
            'easy' => $aiResponse['easy'],
            'med'  => $aiResponse['medium'],
            'hard' => $aiResponse['hard'],
            'quiz' => json_encode($aiResponse['quiz'], JSON_UNESCAPED_UNICODE)
        ]);
 
        sendSuccess("تم توليد المحتوى الذكي بنجاح", $aiResponse);
 
    } catch (Exception $e) {
        sendError("خطأ: " . $e->getMessage());
    }
} else {
    sendError("معرف المحاضرة مطلوب");
}
 
function callOurAPI($filePath, $audioPath = null) {
    $apiUrl = "https://believable-balance-production-b275.up.railway.app/process";
    $postFields = [];
 
    if ($filePath && file_exists($filePath)) {
        $postFields['image'] = new CURLFile($filePath, 'application/pdf', basename($filePath));
    }
    if ($audioPath && file_exists($audioPath)) {
        $postFields['audio'] = new CURLFile($audioPath, 'audio/ogg', basename($audioPath));
    }
    if (empty($postFields)) {
        throw new Exception("لا يوجد ملف PDF أو صوت");
    }
 
    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL            => $apiUrl,
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => $postFields,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT        => 7200,
    ]);
 
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
 
    if ($httpCode !== 200) throw new Exception("فشل الاتصال: HTTP $httpCode");
 
    $result = json_decode($response, true);
    if (!$result) throw new Exception("فشل قراءة النتيجة");
 
    return [
        'easy'   => $result['summary']['basic']    ?? '',
        'medium' => $result['summary']['standard']  ?? '',
        'hard'   => $result['summary']['advanced']  ?? '',
        'quiz'   => $result['quiz']                 ?? []
    ];
}
 