<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" type="image/x-icon" href="../Images/Logo 2.png">
    <title>ByteCart | Register</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100">
    <header class="mb-8 md:mb-16"><?php include '../components/navbar.php'; ?></header>

    <div class="flex flex-col min-h-screen">
        <div class="flex-grow flex items-center justify-center px-4 md:px-8">
            <div class="bg-white shadow-md rounded-lg p-8 w-full max-w-md">
                <h2 class="text-2xl font-bold text-center mb-6">Create Account</h2>
                <form action="../handlers/register_handler.php" method="POST" class="space-y-4">
                    <div>
                        <label for="fullname" class="block text-sm font-medium text-gray-700">Full Name</label>
                        <input type="text" id="fullname" name="fullname" placeholder="Enter your Full Name" required
                            class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm">
                    </div>
                    <div>
                        <label for="email" class="block text-sm font-medium text-gray-700">Email Address</label>
                        <input type="email" id="email" name="email" placeholder="Enter your email address" required
                            class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm">
                    </div>
                    <div>
                        <label for="password" class="block text-sm font-medium text-gray-700">Password</label>
                        <input type="password" id="password" name="password" placeholder="Enter your Password" required
                            class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm">
                    </div>
                    <div>
                        <label for="confirm_password" class="block text-sm font-medium text-gray-700">Confirm Password</label>
                        <input type="password" id="confirm_password" name="confirm_password" placeholder="Retype your Password" required
                            class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm">
                    </div>
                    <div class="flex items-center">
                        <input type="checkbox" id="terms" name="terms" required
                            class="h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500">
                        <label for="terms" class="ml-2 block text-sm text-gray-700">
                            I agree to the <a href="#" class="text-blue-600 hover:underline">Terms and Conditions</a>
                        </label>
                    </div>
                    <button type="submit"
                        class="w-full bg-blue-600 text-white py-2 px-4 rounded-md shadow-sm hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
                        Sign Up
                    </button>
                </form>
                <p class="mt-4 text-center text-sm text-gray-600">
                    Already have an account? <a href="login.php" class="text-blue-600 hover:underline">Log in</a>
                </p>
            </div>
        </div>
        <footer class="mt-8 md:mt-16"><?php include '../components/footer.php'; ?></footer>
    </div>

    <?php if (isset($_GET['error'])): ?>
        <script>
            alert("<?php echo htmlspecialchars($_GET['error']); ?>");
            window.history.replaceState({}, document.title, window.location.pathname);
        </script>
    <?php endif; ?>
    <?php if (isset($_GET['success'])): ?>
        <script>
            alert("Registration successful!");
            window.location.href = "login.php";
        </script>
    <?php endif; ?>
</body>
</html>