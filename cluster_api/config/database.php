<?php
class Database {
    private $host = "";
    private $port = "";
    private $db_name = "";
    private $username = "";
    private $password = "";
    public $conn;

    public function __construct() {
        $this->host     = getenv('DB_HOST') ?: 'localhost';
        $this->port     = getenv('DB_PORT') ?: '3306';
        $this->db_name  = getenv('DB_NAME') ?: 'cluster_academy';
        $this->username = getenv('DB_USER') ?: 'root';
        $this->password = getenv('DB_PASS') ?: '';
    }

    public function getConnection() {
        $this->conn = null;
        try {
            $dsn = "mysql:host={$this->host};port={$this->port};dbname={$this->db_name};charset=utf8";
            $this->conn = new PDO($dsn, $this->username, $this->password);
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch(PDOException $e) {
            echo json_encode([
                'status' => 'error',
                'message' => 'DB Error: ' . $e->getMessage()
            ]);
        }
        return $this->conn;
    }
}
?>
