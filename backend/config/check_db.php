<?php
require_once 'database.php';
try {
    $db = new Database();
    $conn = $db->getConnection();
    if($conn) {
        echo "✅ الاتصال بقاعدة البيانات ناجح!";
    }
} catch (Exception $e) {
    echo "❌ فشل الاتصال: " . $e->getMessage();
}
?>