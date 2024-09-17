<?php
header('Content-Type: application/json');

// Database connection
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "smp1";

$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    echo json_encode(['success' => false, 'error' => 'Database connection failed']);
    exit();
}

// Get POST data
$data = json_decode(file_get_contents('php://input'), true);

// Check if data is not null and has required fields
if (isset($data['name']) && isset($data['guru_id'])) {
    $name = $data['name'];
    $guru_id = $data['guru_id'];

    // Prepare and execute query
    $stmt = $conn->prepare("INSERT INTO mapel (name, guru_id) VALUES (?, ?)");
    if (!$stmt) {
        echo json_encode(['success' => false, 'error' => 'Failed to prepare statement']);
        exit();
    }

    $stmt->bind_param("si", $name, $guru_id);

    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Subject added successfully']);
    } else {
        echo json_encode(['success' => false, 'error' => 'Failed to add subject']);
    }

    $stmt->close();
} else {
    echo json_encode(['success' => false, 'error' => 'Name and guru_id are required']);
}

$conn->close();
?>
