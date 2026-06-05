<?php

class Database {

    
    private $host     = "localhost";    // عنوان السيرفر
    private $db_name  = "cluster_academy"; // اسم قاعدة البيانات
    private $username = "root";         // اسم المستخدم في XAMPP
    private $password = "";             // كلمة المرور (فارغة في XAMPP)
    private $conn;

    
    public function connect() {

        $this->conn = null;

        try {
            // إنشاء الاتصال باستخدام PDO
            $this->conn = new PDO(
                "mysql:host=" . $this->host . 
                ";dbname=" . $this->db_name . 
                ";charset=utf8mb4",
                $this->username,
                $this->password
            );

            // إعداد PDO لإظهار الأخطاء
            $this->conn->setAttribute(
                PDO::ATTR_ERRMODE,
                PDO::ERRMODE_EXCEPTION
            );

            // إعداد PDO لإرجاع البيانات كـ Array
            $this->conn->setAttribute(
                PDO::ATTR_DEFAULT_FETCH_MODE,
                PDO::FETCH_ASSOC
            );

        } catch(PDOException $e) {
            echo json_encode([
                "success" => false,
                "message" => "خطأ في الاتصال: " . $e->getMessage()
            ]);
            exit();
        }

        return $this->conn;
    }
}
?>