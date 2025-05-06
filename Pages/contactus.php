<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" type="image/x-icon" href="../Images/Logo 2.png">
    <title>ByteCart | Contact Us</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100">
    <header><?php include '../components/navbar.php'; ?></header>

    <!-- Contact Information -->
    <div class="bg-gray-100 py-5 md:py-10">
        <div class="container mx-auto px-4 sm:px-6 lg:px-8 max-w-7xl">
            <h1 class="text-4xl font-bold text-center text-gray-800 mb-10">Contact Information</h1>
            
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
                <div class="bg-white p-4 rounded-lg shadow-md text-center">
                    <img src="../Images/Icons/Email.png" alt="Email Icon" class="w-10 h-10 mx-auto mb-2">
                    <p class="text-gray-800 font-medium text-sm">bytecart@gmail.com</p>
                </div>
                <div class="bg-white p-4 rounded-lg shadow-md text-center">
                    <img src="../Images/Icons/Location.png" alt="Location Icon" class="w-10 h-10 mx-auto mb-2">
                    <p class="text-gray-800 font-medium text-sm">45, Lake View Road, Nugegoda, Sri Lanka</p>
                </div>
                <div class="bg-white p-4 rounded-lg shadow-md text-center">
                    <img src="../Images/Icons/Phone.png" alt="Phone Icon" class="w-10 h-10 mx-auto mb-2">
                    <p class="text-gray-800 font-medium text-sm">+94 76 123 4567</p>
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <!-- Contact Form -->
                <div class="bg-white p-4 rounded-lg shadow-md">
                    <h2 class="text-2xl font-bold text-gray-800 mb-4">Get in Touch</h2>
                    <p class="text-gray-600 mb-4">We would love to hear from you</p>
                    <form action="submit_contact.php" method="POST" class="space-y-3">
                        <div>
                            <input type="text" id="name" name="name" class="border border-gray-300 rounded-lg p-2 w-full focus:ring-2 focus:ring-blue-500" placeholder="Name*" required>
                        </div>
                        <div>
                            <input type="email" id="email" name="email" class="border border-gray-300 rounded-lg p-2 w-full focus:ring-2 focus:ring-blue-500" placeholder="Email*" required>
                        </div>
                        <div>
                            <input type="text" id="subject" name="subject" class="border border-gray-300 rounded-lg p-2 w-full focus:ring-2 focus:ring-blue-500" placeholder="Subject*" required>
                        </div>
                        <div>
                            <textarea id="message" name="message" rows="3" class="border border-gray-300 rounded-lg p-2 w-full focus:ring-2 focus:ring-blue-500" placeholder="Message*" required></textarea>
                        </div>
                        <button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white font-medium px-4 py-2 rounded-lg w-full transition duration-200">Send Message</button>
                    </form>
                </div>

                <!-- Map -->
                <div class="bg-white rounded-lg shadow-md">
                    <iframe src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3168.935!2d79.900!3d6.867!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x3ae25!2sIbson's%20Choice%20Cafe!5e0!3m2!1sen!2slk!4v1234567890" 
                        style="border:0; width: 100%; height: 100%;" 
                        allowfullscreen="" 
                        loading="lazy" 
                        class="rounded-lg shadow-md">
                    </iframe>
                </div>
            </div>
        </div>
    </div>

    <footer class="mt-5"><?php include '../components/footer.php'; ?></footer>
</body>
</html>