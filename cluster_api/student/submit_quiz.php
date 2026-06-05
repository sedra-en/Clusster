<?php
require_once __DIR__ . '/../cors.php';
require_once '../config/database.php';
require_once '../helpers/response.php';
 
$db = (new Database())->getConnection();
$data = json_decode(file_get_contents("php://input"), true);
 
if (empty($data['student_id']) || empty($data['lecture_id']) || empty($data['answers'])) {
    sendError("بيانات ناقصة");
}
 
$studentId = (int)$data['student_id'];
$lectureId = (int)$data['lecture_id'];
$answers   = $data['answers'];
 
if (!is_array($answers) || empty($answers)) {
    sendError("الإجابات يجب أن تكون مصفوفة غير فارغة");
}
 
try {
    $stmt = $db->prepare("
        SELECT lac.quiz_json
        FROM lecture_ai_content lac
        WHERE lac.lecture_id = ? AND lac.is_generated = 1
        LIMIT 1
    ");
    $stmt->execute([$lectureId]);
    $aiRow = $stmt->fetch(PDO::FETCH_ASSOC);
 
    if (!$aiRow) sendError("المحاضرة لا تحتوي على اختبار", 404);
 
    $quizData = json_decode($aiRow['quiz_json'], true);
    $serverQuestions = [];
    if (isset($quizData['questions']) && is_array($quizData['questions'])) {
        $serverQuestions = $quizData['questions'];
    } elseif (is_array($quizData)) {
        $serverQuestions = $quizData;
    }
 
    if (empty($serverQuestions)) sendError("لا توجد أسئلة في الاختبار", 404);
 
    $totalQ   = count($serverQuestions);
    $correctQ = 0;
 
    
    foreach ($answers as $idx => $a) {
        if (!is_array($a)) continue;
        $selected = trim($a['selected'] ?? '');
        $serverQ  = $serverQuestions[$idx] ?? null;
        if (!$serverQ) continue;
 
        $correct = trim($serverQ['answer'] ?? ($serverQ['correct'] ?? ''));
        if ($correct === '') continue;
 
        
        $isCorrect = $correct === $selected;
 
        
        if (!$isCorrect && isset($serverQ['choices'])) {
            $choices = $serverQ['choices'];
            if (is_string($choices)) {
                $choices = json_decode($choices, true) ?? [];
            }
            if (is_array($choices)) {
                foreach ($choices as $key => $value) {
                    if (trim((string)$value) === $selected && trim((string)$key) === $correct) {
                        $isCorrect = true;
                        break;
                    }
                }
            }
        }
 
        if ($isCorrect) $correctQ++;
    }
 
    $percentage = $totalQ > 0 ? round(($correctQ / $totalQ) * 100, 2) : 0;
    $passed     = $percentage >= 60 ? 1 : 0;
    $score      = $percentage;
 
    
    $insert = $db->prepare("
        INSERT INTO quiz_attempts
          (student_id, lecture_id, score, total_q, correct_q, answers_json, passed, attempted_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, NOW())
    ");
    $insert->execute([
        $studentId,
        $lectureId,
        $score,
        $totalQ,
        $correctQ,
        json_encode($answers, JSON_UNESCAPED_UNICODE),
        $passed,
    ]);
 
    sendSuccess("تم إرسال الاختبار", [
        "attempt_id" => $db->lastInsertId(),
        "score"      => $score,
        "total"      => $totalQ,
        "correct"    => $correctQ,
        "percentage" => $percentage,
        "passed"     => (bool)$passed,
    ]);
} catch (Exception $e) {
    sendError("خطأ: " . $e->getMessage());
}