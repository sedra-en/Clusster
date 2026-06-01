<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once '../config/database.php';
require_once '../helpers/response.php';

$database = new Database();
$db = $database->getConnection();

$course_id = $_GET['course_id'] ?? null;

if ($course_id) {
    // جلب المحاضرات مع حالة وجود محتوى ذكي (AI)
    $query = "SELECT l.*, 
              (SELECT is_published FROM lecture_ai_content WHERE lecture_id = l.id) as has_ai 
              FROM lectures l 
              WHERE l.course_id = :cid ORDER BY l.created_at DESC";
              
    $stmt = $db->prepare($query);
    $stmt->execute(['cid' => $course_id]);
    $lectures = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    sendSuccess("Lectures fetched", $lectures);
} else {
    sendError("Course ID is required");
}