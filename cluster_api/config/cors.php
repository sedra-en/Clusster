<?php
// =====================================================
// config/cors.php
// إعدادات CORS للسماح لـ Flutter بالاتصال
// =====================================================

// ✅ السماح لأي جهاز بالوصول (للتطوير فقط)
header("Access-Control-Allow-Origin: *");

// ✅ السماح بهذه الأساليب
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");

// ✅ السماح بهذه الترويسات
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

// ✅ نوع المحتوى JSON
header("Content-Type: application/json; charset=UTF-8");

// ✅ التعامل مع طلبات OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}
?>