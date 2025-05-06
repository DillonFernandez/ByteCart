<?php
session_start();
if (isset($_COOKIE['customer_id']) && !isset($_SESSION['customer_id'])) {
    $_SESSION['customer_id'] = $_COOKIE['customer_id'];
    header("Location: account.php");
    exit();
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" type="image/x-icon" href="../Images/Logo 2.png">
    <title>ByteCart | Login</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100">
    <header class="mb-8"><?php include '../components/navbar.php'; ?></header>

    <div class="flex flex-col min-h-screen">
        <div class="flex-grow flex items-center justify-center px-4 sm:px-6 lg:px-8">
            <div class="bg-white shadow-md rounded-lg p-8 w-full max-w-md">
                <h2 class="text-2xl font-bold text-center mb-6">Login</h2>
                <form action="../handlers/login_handler.php" method="POST" class="space-y-4">
                    <div>
                        <label for="email" class="block text-sm font-medium text-gray-700">Email address</label>
                        <input type="email" id="email" name="email" required 
                            class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                    </div>
                    <div>
                        <label for="password" class="block text-sm font-medium text-gray-700">Password</label>
                        <input type="password" id="password" name="password" required 
                            class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                    </div>
                    <div class="flex items-center justify-between">
                        <div class="flex items-center">
                            <input id="remember" name="remember" type="checkbox" 
                                class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded">
                            <label for="remember" class="ml-2 block text-sm text-gray-900">Remember me</label>
                        </div>
                        <div>
                            <a href="#" class="text-sm text-blue-600 hover:underline">Forgot password?</a>
                        </div>
                    </div>
                    <button type="submit" 
                        class="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
                        Login
                    </button>
                </form>
                <p class="mt-4 text-center text-sm text-gray-600"> 
                    Don't have an account? <a href="register.php" class="text-blue-600 hover:underline">Sign up</a>
                </p>
            </div>
        </div>
        <footer class="mt-8"><?php include '../components/footer.php'; ?></footer>
    </div>

    <?php
    if (isset($_GET['error'])) {
        $error_message = htmlspecialchars($_GET['error']);
        echo "<script>
            alert('$error_message');
            // Remove the error parameter from the URL
            const url = new URL(window.location.href);
            url.searchParams.delete('error');
            window.history.replaceState({}, document.title, url.toString());
        </script>";
    }
    ?>
</body>
</html>