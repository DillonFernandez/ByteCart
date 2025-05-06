<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">
    <title>Navbar</title>
    <style>
        nav ul li a {
            display: inline-block;
            padding: 0.5rem 1rem;
            line-height: 1.5;
            vertical-align: middle;
        }

        nav ul {
            display: flex;
            align-items: center;
        }

        .dropbtn {
            background-color: inherit;
            color: white;
            padding: 0.5rem 1rem;
            font-size: 16px;
            border: none;
            cursor: pointer;
            line-height: 1.5;
        }

        .dropdown-content {
            display: none;
            position: absolute;
            background-color: #0D1117;
            min-width: 200px;
            box-shadow: 0px 8px 16px rgba(0, 0, 0, 0.2);
            z-index: 1;
            border-radius: 8px;
            margin-top: 0.5rem;
        }

        .dropdown-content a {
            color: white;
            padding: 12px 16px;
            text-decoration: none;
            display: block;
            text-align: left;
        }

        .dropdown-content a:hover {
            color: #007BFF;
        }

        .show {
            display: block;
        }

        .overlay {
            height: 100%;
            width: 100%;
            display: none;
            position: fixed;
            z-index: 1;
            top: 0;
            left: 0;
            background-color: rgba(0, 0, 0, 0.9);
            overflow-y: auto;
        }

        .overlay-content {
            position: relative;
            top: 25%;
            width: 100%;
            text-align: center;
            margin-top: 30px;
            padding-bottom: 20px;
        }

        .overlay a {
            padding: 8px;
            text-decoration: none;
            font-size: 24px;
            color: #818181;
            display: block;
        }

        .overlay a:hover, .overlay a:focus {
            color: #007BFF;
        }

        .overlay .closebtn {
            position: absolute;
            top: 20px;
            right: 45px;
            font-size: 40px;
            color: white;
        }

        .mobile-dropdown-content {
            display: none;
            list-style: none;
            padding: 0;
            margin: 0;
            text-align: center;
            background-color: rgba(0, 0, 0, 0.9);
            border-radius: 8px;
        }

        .mobile-dropdown-content li a {
            padding: 12px 16px;
            text-decoration: none;
            font-size: 20px;
            color: #818181;
            background-color: transparent;
            display: block;
        }

        .mobile-dropdown-content li a:hover {
            color: #007BFF;
            background-color: transparent;
        }

        .mobile-dropdown-content.show {
            display: block;
        }

        .mobile-dropdown {
            margin-bottom: 10px;
        }

        .dropbtn-mobile {
            background-color: transparent;
            color: #818181;
            font-size: 24px;
            border: none;
            cursor: pointer;
            text-align: center;
            padding: 8px;
        }

        .dropbtn-mobile:hover, .dropbtn-mobile:focus {
            color: #007BFF;
        }

        nav ul li a:hover,
        nav ul li a:focus,
        .dropbtn:hover,
        .dropbtn:focus,
        .dropbtn-mobile:hover,
        .dropbtn-mobile:focus {
            color: #007BFF;
        }
    </style>
</head>
<body class="bg-white">
    <nav class="bg-[#0D1117] text-white">
        <div class="hidden md:flex justify-between items-center px-6 py-4">
            <div class="flex items-center space-x-6">
                <img src="../Images/Logo 1.png" alt="ByteCart Logo" class="h-10">
                <ul class="flex space-x-2">
                    <li><a href="../Pages/index.php" class="hover:text-blue-500">Home</a></li>
                    <li class="dropdown">
                        <button class="dropbtn hover:text-blue-500 focus:outline-none" onclick="toggleDropdown()">Products
                            <i class="fa fa-caret-down ml-1"></i>
                        </button>
                        <ul id="productsDropdown" class="dropdown-content">
                            <li><a href="#">Smartphones & Accessories</a></li>
                            <li><a href="#">Computers & Laptops</a></li>
                            <li><a href="#">Audio & Headphones</a></li>
                            <li><a href="#">Gaming & Entertainment</a></li>
                            <li><a href="#">Cameras & Photography</a></li>
                            <li><a href="#">Smart Home & Security</a></li>
                            <li><a href="#">Home Appliances</a></li>
                            <li><a href="#">Wearable Tech</a></li>
                        </ul>
                    </li>
                    <li><a href="#" class="hover:text-blue-500">Offers</a></li>
                    <li><a href="../Pages/contactus.php" class="hover:text-blue-500">Contact Us</a></li>
                </ul>
            </div>
            <div class="flex items-center">
                <div class="relative">
                    <input type="text" placeholder="Search products…" class="bg-[#0D1117] border border-white rounded-[10px] px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-600 text-white">
                    <svg xmlns="http://www.w3.org/2000/svg" class="absolute top-2 right-3 h-5 w-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-4.35-4.35M16.5 10.5a6 6 0 11-12 0 6 6 0 0112 0z" />
                    </svg>
                </div>
                <img src="../Images/Icons/Cart.png" alt="Cart" class="h-6 ml-2">
                <a href="../Pages/account.php">
                    <img src="../Images/Icons/Account.png" alt="Account" class="h-6 ml-2">
                </a>
            </div>
        </div>

        <div id="mobile-menu-overlay" class="overlay">
            <a href="javascript:void(0)" class="closebtn" onclick="closeMobileMenu()">&times;</a>
            <div class="overlay-content">
                <a href="../Pages/index.php">Home</a>
                <div class="mobile-dropdown">
                    <button class="dropbtn-mobile" onclick="toggleMobileDropdown()">Products
                        <i class="fa fa-caret-down ml-1"></i>
                    </button>
                    <ul id="mobileProductsDropdown" class="mobile-dropdown-content">
                        <li><a href="#">Smartphones & Accessories</a></li>
                        <li><a href="#">Computers & Laptops</a></li>
                        <li><a href="#">Audio & Headphones</a></li>
                        <li><a href="#">Gaming & Entertainment</a></li>
                        <li><a href="#">Cameras & Photography</a></li>
                        <li><a href="#">Smart Home & Security</a></li>
                        <li><a href="#">Home Appliances</a></li>
                        <li><a href="#">Wearable Tech</a></li>
                    </ul>
                </div>
                <a href="#">Offers</a>
                <a href="../Pages/contactus.php">Contact Us</a>
            </div>
        </div>

        <div class="md:hidden flex justify-between items-center px-4 py-4">
            <button id="menu-toggle" class="text-blue-500" onclick="openMobileMenu()">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16m-7 6h7" />
                </svg>
            </button>
            <img src="../Images/Logo 1.png" alt="ByteCart Logo" class="h-10">
            <div class="flex items-center space-x-2">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-8 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-4.35-4.35M16.5 10.5a6 6 0 11-12 0 6 6 0 0112 0z" />
                </svg>
                <img src="../Images/Icons/Cart.png" alt="Cart" class="h-6">
                <a href="../Pages/account.php">
                    <img src="../Images/Icons/Account.png" alt="Account" class="h-6">
                </a>
            </div>
        </div>
    </nav>

    <script>
        function toggleDropdown() {
            const dropdown = document.getElementById("productsDropdown");
            dropdown.classList.toggle("show");
        }

        function toggleMobileDropdown() {
            const dropdown = document.getElementById("mobileProductsDropdown");
            dropdown.classList.toggle("show");
        }

        function openMobileMenu() {
            document.getElementById("mobile-menu-overlay").style.display = "block";
        }

        function closeMobileMenu() {
            document.getElementById("mobile-menu-overlay").style.display = "none";
        }

        window.onclick = function (e) {
            if (!e.target.matches('.dropbtn')) {
                const dropdown = document.getElementById("productsDropdown");
                if (dropdown && dropdown.classList.contains('show')) {
                    dropdown.classList.remove('show');
                }
            }
        };
    </script>
</body>
</html>
