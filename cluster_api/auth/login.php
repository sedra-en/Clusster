<?php
require_once __DIR__ . '/../cors.php';
require_once '../config/database.php';
require_once '../helpers/response.php';
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// إذا كان الطلب من نوع OPTIONS (Preflight)، قم بإنهاء التنفيذ فوراً
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit;
}

// ... باقي كود الـ PHP الخاص بك ...
$db = (new Database())->getConnection();
$data = json_decode(file_get_contents("php://input"));

if (empty($data->email) || empty($data->password)) {
    sendError("البريد وكلمة المرور مطلوبين");
}

try {
    // 1. نجلب المستخدم بالإيميل فقط
    $stmt = $db->prepare("
        SELECT id, full_name, email, password_hash, role, status, is_activated
        FROM users
        WHERE email = ?
        LIMIT 1
    ");
    $stmt->execute([$data->email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        sendError("البريد الإلكتروني أو كلمة المرور غير صحيحة", 401);
    }

    // 2. نتحقق من الحالة
    if ($user['status'] === 'blocked') {
        sendError("حسابك محظور. تواصل مع الإدارة", 403);
    }

    // 3. التحقق من كلمة المرور
    $stored = $user['password_hash'] ?? '';
    $input  = $data->password;
    $isValid = false;

    // محاولة 1: مقارنة مشفّرة (للحسابات اللي عملت activate)
    if (!empty($stored) && password_verify($input, $stored)) {
        $isValid = true;
    }
    // محاولة 2: مقارنة نص خام (للحسابات الأصلية القديمة)
    elseif ($stored === $input) {
        $isValid = true;
        // نشفّرها للمرة القادمة
        $newHash = password_hash($input, PASSWORD_DEFAULT);
        $upd = $db->prepare("UPDATE users SET password_hash = ? WHERE id = ?");
        $upd->execute([$newHash, $user['id']]);
    }

    if (!$isValid) {
        sendError("البريد الإلكتروني أو كلمة المرور غير صحيحة", 401);
    }

    // 4. نرجع البيانات بدون الباسوورد
    unset($user['password_hash']);
    sendSuccess("تم تسجيل الدخول", $user);

} catch (Exception $e) {
    sendError("خطأ: " . $e->getMessage());
}