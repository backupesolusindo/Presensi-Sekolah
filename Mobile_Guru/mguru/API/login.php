<?php
// Database connection
$servername = "localhost";
$username = "root"; // Update this if necessary
$password = ""; // Update this if necessary
$dbname = "smp1"; // Update this if necessary

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    error_log("Connection failed: " . $conn->connect_error);
    die(json_encode(['success' => false, 'error' => 'Database connection failed']));
}

// Read and log the JSON body
$rawData = file_get_contents("php://input");
error_log("Raw data: " . $rawData);

$data = json_decode($rawData, true);

// Check if data is not null and has required fields
if ($data && isset($data['nip']) && isset($data['password'])) {
    $nip = $conn->real_escape_string($data['nip']);
    $password = $conn->real_escape_string($data['password']); // Escape password input

    // Query to check if NIP exists
    $stmt = $conn->prepare("SELECT * FROM guru WHERE nip = ?");
    if (!$stmt) {
        error_log("Prepare statement failed: " . $conn->error);
        die(json_encode(['success' => false, 'error' => 'Internal server error']));
    }

    $stmt->bind_param("s", $nip);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        // NIP exists
        $user = $result->fetch_assoc();

        // Verify password directly (without hash)
        if ($password === $user['password']) {
            // Fetch subjects for the user
            $subjectSql = "SELECT name FROM mapel WHERE guru_id = ?";
            $subjectStmt = $conn->prepare($subjectSql);
            if (!$subjectStmt) {
                error_log("Prepare subject statement failed: " . $conn->error);
                die(json_encode(['success' => false, 'error' => 'Internal server error']));
            }

            $subjectStmt->bind_param("i", $user['id']);
            $subjectStmt->execute();
            $subjectResult = $subjectStmt->get_result();

            $subjects = [];
            while ($row = $subjectResult->fetch_assoc()) {
                $subjects[] = $row['name'];
            }

            echo json_encode([
                'success' => true,
                'name' => $user['nama'],
                'subjects' => $subjects
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'error' => 'Invalid NIP or password'
            ]);
        }
    } else {
        echo json_encode([
            'success' => false,
            'error' => 'NIP not found'
        ]);
    }

    $stmt->close();
} else {
    echo json_encode([
        'success' => false,
        'error' => 'NIP and password required'
    ]);
}

// Close connection
$conn->close();
?>
