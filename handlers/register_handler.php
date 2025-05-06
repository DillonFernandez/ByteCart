<?php

include '../database/db_connection.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $fullname = $_POST['fullname'];
    $email = $_POST['email'];
    $password = $_POST['password'];
    $confirm_password = $_POST['confirm_password'];

    $errors = [];

    // Check if passwords match
    if ($password !== $confirm_password) {
        $errors[] = "Passwords do not match";
    }

    // Check if email already exists
    $stmt = $conn->prepare("SELECT * FROM customer WHERE Email = ?");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $errors[] = "Email is already registered";
    }

    $stmt->close();

    // If there are errors, redirect back to the register page with errors
    if (!empty($errors)) {
        $error_message = urlencode(implode(" and ", $errors));
        header("Location: ../Pages/register.php?error=$error_message");
        exit();
    }

    $stmt = $conn->prepare("INSERT INTO customer (FullName, Email, CustomerPW) VALUES (?, ?, ?)");
    $stmt->bind_param("sss", $fullname, $email, $password);

    // After successful registration
    if ($stmt->execute()) {
        header("Location: ../Pages/register.php?success=1");
        exit();
    } else {
        echo "Error: " . $stmt->error;
    }

    $stmt->close();
    $conn->close();
}
?>