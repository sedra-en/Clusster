<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once '../config/database.php';
require_once '../helpers/response.php';

$database = new Database();
$db = $database->getConnection();

$lecture_id = $_GET['lecture_id'] ?? null;

if ($lecture_id) {
    $query = "SELECT * FROM lecture_ai_content WHERE lecture_id = :lid LIMIT 1";
    $stmt = $db->prepare($query);
    $stmt->execute(['lid' => $lecture_id]);
    $content = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($content) {
        // فك تشفير الـ JSON الخاص بالاختبار قبل إرساله
        $content['quiz_json'] = json_decode($content['quiz_json']);
        sendSuccess("AI Content fetched", $content);
    } else {
        sendError("No AI content found for this lecture");
    }
} else {
    sendError("Lecture ID is required");
}