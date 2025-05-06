<?php
session_start();
include '../database/db_connection.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email = $_POST['email'];
    $password = $_POST['password'];
    $remember_me = isset($_POST['remember']);

    // Prepare the SQL statement to fetch the password
    $stmt = $conn->prepare("SELECT CustomerID, CustomerPW FROM customer WHERE Email = ?");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $stmt->bind_result($customer_id, $stored_password);
    $stmt->fetch();

    // Compare the entered password with the stored password
    if ($stored_password && $password === $stored_password) {
        // Set session variables
        $_SESSION['customer_id'] = $customer_id;

        if ($remember_me) {
            // Set a cookie to remember the user for 30 days
            setcookie("customer_id", $customer_id, time() + (30 * 24 * 60 * 60), "/");
        }

        header("Location: ../Pages/account.php");
        exit();
    } else {
        // Redirect back to login page with an error message
        $error_message = "Invalid email or password.";
        header("Location: ../Pages/login.php?error=" . urlencode($error_message));
        exit();
    }

    $stmt->close();
    $conn->close();
}
?>