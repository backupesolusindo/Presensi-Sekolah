<?php
include 'config.php';

header('Content-Type: application/json');
$data = json_decode(file_get_contents('php://input'), true);

if (isset($data['name'], $data['nis'], $data['kelas'], $data['embedding'])) {
    $name = $data['name'];
    $nis = $data['nis'];
    $kelas = $data['kelas'];
    $embedding = $data['embedding'];

    $stmt = $pdo->prepare("INSERT INTO users (name, nis, kelas, embedding) VALUES (?, ?, ?, ?)");
    try {
        $stmt->execute([$name, $nis, $kelas, $embedding]);
        echo json_encode(['message' => 'Data uploaded successfully']);
    } catch (PDOException $e) {
        echo json_encode(['error' => 'Failed to upload data: ' . $e->getMessage()]);
    }
} else {
    echo json_encode(['error' => 'Invalid input']);
}
?>
