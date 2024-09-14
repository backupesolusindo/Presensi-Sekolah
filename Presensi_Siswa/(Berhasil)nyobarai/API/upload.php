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

// Cek jika file di-upload
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['file'])) {
    $local_file = $_FILES['file']['tmp_name'];
    $remote_file = $ftp_path . basename($_FILES['file']['name']);

    // Upload file ke FTP
    if (ftp_put($conn_id, $remote_file, $local_file, FTP_BINARY)) {
        echo json_encode(["status" => "success", "message" => "File uploaded successfully"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Failed to upload file"]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "No file uploaded"]);
}

// Tutup koneksi FTP
ftp_close($conn_id);




















// include 'config.php';

// header('Content-Type: application/json');
// $data = json_decode(file_get_contents('php://input'), true);

// if (isset($data['name'], $data['nis'], $data['kelas'], $data['embedding'])) {
//     $name = $data['name'];
//     $nis = $data['nis'];
//     $kelas = $data['kelas'];
//     $embedding = $data['embedding'];

//     $stmt = $pdo->prepare("INSERT INTO users (name, nis, kelas, embedding) VALUES (?, ?, ?, ?)");
//     try {
//         $stmt->execute([$name, $nis, $kelas, $embedding]);
//         echo json_encode(['message' => 'Data uploaded successfully']);
//     } catch (PDOException $e) {
//         echo json_encode(['error' => 'Failed to upload data: ' . $e->getMessage()]);
//     }
// } else {
//     echo json_encode(['error' => 'Invalid input']);
// }
?>
