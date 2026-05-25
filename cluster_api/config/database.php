<?php
class Database {
    private $host = "localhost";
    private $db_name = "cluster_academy";
    private $username = "root";
    private $password = "";
    public $conn;

    public function getConnection() {
        $this->conn = null;
        try {
            // استخدام PDO للاتصال
            $this->conn = new PDO("mysql:host=" . $this->host . ";dbname=" . $this->db_name, $this->username, $this->password);
            $this->conn->exec("set names utf8");
            // تفعيل إظهار الأخطاء للتصحيح
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch(PDOException $exception) {
            echo "خطأ في الاتصال: " . $exception->getMessage();
        }
        return $this->conn;
    }
}
?>