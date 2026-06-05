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

if (empty($data->lecture_id)) {
    sendError("معرف المحاضرة مطلوب");
}

try {
    // تحقق إذا المحتوى موجود مسبقاً
    $checkStmt = $db->prepare("SELECT is_generated FROM lecture_ai_content WHERE lecture_id = ?");
    $checkStmt->execute([$data->lecture_id]);
    $existing = $checkStmt->fetch(PDO::FETCH_ASSOC);
    if ($existing && $existing['is_generated'] == 1) {
        sendSuccess("المحتوى موجود مسبقاً");
        exit();
    }

    // جلب بيانات المحاضرة
    $stmt = $db->prepare("SELECT title, file_path, audio_path FROM lectures WHERE id = ?");
    $stmt->execute([$data->lecture_id]);
    $lecture = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$lecture) sendError("المحاضرة غير موجودة");

    // حفظ status = processing في الداتا بيز
    $db->prepare("INSERT INTO lecture_ai_content (lecture_id, is_generated) VALUES (?, 0)
                  ON DUPLICATE KEY UPDATE is_generated = 0")->execute([$data->lecture_id]);

    // رجع job_id فوراً للتطبيق
    $jobId = uniqid('job_', true);
    echo json_encode(["status" => "processing", "job_id" => $jobId]);
    
    // إغلاق الاتصال مع Flutter وكمّل الشغل
    if (function_exists('fastcgi_finish_request')) {
        fastcgi_finish_request();
    } else {
        ob_end_flush();
        flush();
    }

    // شغّل الـ AI بالخلفية
    $uploadsDir = realpath("../uploads/") . DIRECTORY_SEPARATOR;
    $fileExt = pathinfo($lecture['file_path'] ?? '', PATHINFO_EXTENSION);
    $audioExts = ['ogg', 'mp3', 'wav', 'm4a', 'aac'];

    if (in_array(strtolower($fileExt), $audioExts)) {
        $filePath = null;
        $audioPath = $uploadsDir . $lecture['file_path'];
    } else {
        $filePath = $lecture['file_path'] ? $uploadsDir . $lecture['file_path'] : null;
        $audioPath = $lecture['audio_path'] ? $uploadsDir . $lecture['audio_path'] : null;
    }

    $aiResponse = callOurAPI($filePath, $audioPath);

    // حفظ النتائج
    $db->prepare("INSERT INTO lecture_ai_content 
                  (lecture_id, easy_summary, medium_summary, hard_summary, quiz_json, is_generated, generated_at) 
                  VALUES (?, ?, ?, ?, ?, 1, NOW())
                  ON DUPLICATE KEY UPDATE 
                  easy_summary = VALUES(easy_summary),
                  medium_summary = VALUES(medium_summary),
                  hard_summary = VALUES(hard_summary),
                  quiz_json = VALUES(quiz_json),
                  is_generated = 1,
                  generated_at = NOW()")
        ->execute([
            $data->lecture_id,
            $aiResponse['easy'],
            $aiResponse['medium'],
            $aiResponse['hard'],
            json_encode($aiResponse['quiz'], JSON_UNESCAPED_UNICODE)
        ]);

} catch (Exception $e) {
    // حفظ الخطأ
    try {
        $db->prepare("UPDATE lecture_ai_content SET is_generated = -1 WHERE lecture_id = ?")
           ->execute([$data->lecture_id]);
    } catch (Exception $e2) {}
}

function callOurAPI($filePath, $audioPath = null) {
    $apiUrl = "https://believable-balance-production-b275.up.railway.app/process";
    // للمحلي:
    /// $apiUrl = "http://127.0.0.1:8000/process";

    $postFields = [];
    if ($filePath && file_exists($filePath)) {
        $postFields['image'] = new CURLFile($filePath, 'application/pdf', basename($filePath));
    }
    if ($audioPath && file_exists($audioPath)) {
        $postFields['audio'] = new CURLFile($audioPath, 'audio/ogg', basename($audioPath));
    }
    if (empty($postFields)) throw new Exception("لا يوجد ملف PDF أو صوت");

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
