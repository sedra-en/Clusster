<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once '../config/database.php';
require_once '../helpers/response.php';

$db = (new Database())->getConnection();

try {
    //  المستخدمون 
    $userStats = $db->query("
        SELECT
          SUM(role = 'student')                  AS students,
          SUM(role = 'instructor')               AS instructors,
          SUM(role != 'admin' AND status = 'active')  AS active_users,
          SUM(role != 'admin' AND status = 'pending') AS pending_users,
          SUM(role != 'admin' AND status = 'blocked') AS blocked_users
        FROM users
    ")->fetch(PDO::FETCH_ASSOC);

    // المقررات 
    $courseStats = $db->query("
        SELECT
          COUNT(*) AS total,
          SUM(status = 'published') AS published,
          SUM(status = 'draft')     AS draft,
          SUM(status = 'hidden')    AS hidden
        FROM courses
    ")->fetch(PDO::FETCH_ASSOC);

    // المحاضرات والمحتوى الذكي 
    $lecturesCount = (int)$db->query("SELECT COUNT(*) FROM lectures")->fetchColumn();
    $aiContentCount = (int)$db->query("
        SELECT COUNT(*) FROM lecture_ai_content WHERE is_generated = 1
    ")->fetchColumn();

    //  التسجيلات والكويزات 
    $enrollmentsCount = (int)$db->query("
        SELECT COUNT(*) FROM enrollments WHERE is_active = 1
    ")->fetchColumn();
    $quizAttempts = (int)$db->query("SELECT COUNT(*) FROM quiz_attempts")->fetchColumn();

    //  الفصول 
    
    $semesterCount = 0;
    $activeSemester = null;
    try {
        $semesterCount = (int)$db->query("SELECT COUNT(*) FROM semesters")->fetchColumn();
        $activeSemester = $db->query("
            SELECT id, name, code FROM semesters WHERE is_active = 1 LIMIT 1
        ")->fetch(PDO::FETCH_ASSOC) ?: null;
    } catch (Exception $e) {
        
    }

    //  أحدث 5 مستخدمين 
    $recentUsers = $db->query("
        SELECT id, full_name, email, role, status, is_activated, created_at
        FROM users
        WHERE role != 'admin'
        ORDER BY created_at DESC
        LIMIT 5
    ")->fetchAll(PDO::FETCH_ASSOC);

    sendSuccess("Stats fetched", [
        "users" => [
            "students"       => (int)$userStats['students'],
            "instructors"    => (int)$userStats['instructors'],
            "active"         => (int)$userStats['active_users'],
            "pending"        => (int)$userStats['pending_users'],
            "blocked"        => (int)$userStats['blocked_users'],
        ],
        "courses" => [
            "total"     => (int)$courseStats['total'],
            "published" => (int)$courseStats['published'],
            "draft"     => (int)$courseStats['draft'],
            "hidden"    => (int)$courseStats['hidden'],
        ],
        "lectures" => [
            "total"        => $lecturesCount,
            "ai_generated" => $aiContentCount,
        ],
        "engagement" => [
            "enrollments"   => $enrollmentsCount,
            "quiz_attempts" => $quizAttempts,
        ],
        "semesters" => [
            "count"  => $semesterCount,
            "active" => $activeSemester,
        ],
        "recent_users" => $recentUsers,
    ]);
} catch (Exception $e) {
    sendError("خطأ: " . $e->getMessage());
}
