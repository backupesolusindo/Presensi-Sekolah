<?php
// Include configuration file
$config = require('config.php');

// Konfigurasi FTP dari config.php
$ftp_server = $config['ftp_server'];
$ftp_username = $config['ftp_username'];
$ftp_password = $config['ftp_password'];
$ftp_path = $config['ftp_path'];

// Koneksi ke FTP
$conn_id = ftp_connect($ftp_server);
$login_result = ftp_login($conn_id, $ftp_username, $ftp_password);

if (!$conn_id || !$login_result) {
    echo json_encode(["status" => "error", "message" => "FTP connection failed"]);
    exit;
}

// Daftar file di folder
$files = ftp_nlist($conn_id, $ftp_path);
$file_data = [];

foreach ($files as $file) {
    if ($file !== $ftp_path) {
        // Ambil isi file
        $remote_file = $file;
        $file_name = basename($remote_file);
        $local_file = tempnam(sys_get_temp_dir(), 'ftp');
        
        if (ftp_get($conn_id, $local_file, $remote_file, FTP_BINARY)) {
            $file_content = file_get_contents($local_file);
            $file_data[] = [
                "name" => $file_name,
                "content" => base64_encode($file_content) // Encode content as base64
            ];
            unlink($local_file);
        }
    }
}

echo json_encode($file_data);

// Tutup koneksi FTP
ftp_close($conn_id);














// include 'config.php';

// header('Content-Type: application/json');

// $stmt = $pdo->query("SELECT * FROM users");
// $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

// echo json_encode($users);
?>
