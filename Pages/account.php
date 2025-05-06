<?php
session_start();
include '../database/db_connection.php';

if (!isset($_SESSION['customer_id'])) {
    header("Location: login.php");
    exit();
}

$customer_id = $_SESSION['customer_id'];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Retrieve and sanitize input values
    $fullname = htmlspecialchars($_POST['fullname']);
    $email = htmlspecialchars($_POST['email']);
    $phone = htmlspecialchars($_POST['phone']);
    $billingStreet = htmlspecialchars($_POST['billingStreet']);
    $billingSuite = htmlspecialchars($_POST['billingSuite']);
    $billingCity = htmlspecialchars($_POST['billingCity']);
    $billingDistrict = htmlspecialchars($_POST['billingDistrict']);
    $billingZip = htmlspecialchars($_POST['billingZip']);
    $shippingStreet = htmlspecialchars($_POST['shippingStreet']);
    $shippingSuite = htmlspecialchars($_POST['shippingSuite']);
    $shippingCity = htmlspecialchars($_POST['shippingCity']);
    $shippingDistrict = htmlspecialchars($_POST['shippingDistrict']);
    $shippingZip = htmlspecialchars($_POST['shippingZip']);
    $isShippingSame = isset($_POST['isShippingSame']) ? 1 : 0;

    // Update the database
    $stmt = $conn->prepare("UPDATE customer SET FullName = ?, Email = ?, PhoneNumber = ?, BillingStreetAddress = ?, BillingApartmentSuite = ?, BillingCity = ?, BillingDistrict = ?, BillingZipCode = ?, ShippingStreetAddress = ?, ShippingApartmentSuite = ?, ShippingCity = ?, ShippingDistrict = ?, ShippingZipCode = ?, IsShippingSameAsBilling = ? WHERE CustomerID = ?");
    $stmt->bind_param("ssssssssssssiii", $fullname, $email, $phone, $billingStreet, $billingSuite, $billingCity, $billingDistrict, $billingZip, $shippingStreet, $shippingSuite, $shippingCity, $shippingDistrict, $shippingZip, $isShippingSame, $customer_id);
    $stmt->execute();
    $stmt->close();

    // Redirect to the same page to reflect changes
    header("Location: account.php");
    exit();
}

// Fetch current data
$stmt = $conn->prepare("SELECT FullName, Email, PhoneNumber, BillingStreetAddress, BillingApartmentSuite, BillingCity, BillingDistrict, BillingZipCode, ShippingStreetAddress, ShippingApartmentSuite, ShippingCity, ShippingDistrict, ShippingZipCode, IsShippingSameAsBilling FROM customer WHERE CustomerID = ?");
$stmt->bind_param("i", $customer_id);
$stmt->execute();
$stmt->bind_result($fullname, $email, $phone, $billingStreet, $billingSuite, $billingCity, $billingDistrict, $billingZip, $shippingStreet, $shippingSuite, $shippingCity, $shippingDistrict, $shippingZip, $isShippingSame);
$stmt->fetch();
$stmt->close();
$conn->close();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" type="image/x-icon" href="../Images/Logo 2.png">
    <title>ByteCart | Edit Account</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        function toggleShippingAddress(checkbox) {
            const billingFields = ['billingStreet', 'billingSuite', 'billingCity', 'billingDistrict', 'billingZip'];
            const shippingFields = ['shippingStreet', 'shippingSuite', 'shippingCity', 'shippingDistrict', 'shippingZip'];

            if (checkbox.checked) {
                billingFields.forEach((field, index) => {
                    document.getElementsByName(shippingFields[index])[0].value = document.getElementsByName(field)[0].value;
                    document.getElementsByName(shippingFields[index])[0].setAttribute('readonly', true);
                });
            } else {
                shippingFields.forEach(field => {
                    document.getElementsByName(field)[0].value = '';
                    document.getElementsByName(field)[0].removeAttribute('readonly');
                });
            }
        }
    </script>
</head>
<body class="bg-gray-100">
    <header><?php include '../components/navbar.php'; ?></header>

    <div class="container mx-auto px-4 sm:px-6 lg:px-8">
        <form method="POST" action="" class="max-w-4xl mx-auto mt-10 p-6 bg-white rounded-lg shadow-md">
            <h1 class="text-3xl font-bold mb-8 text-center">Edit Account</h1>

            <!-- Personal Information -->
            <div class="mb-6">
                <h2 class="text-lg font-semibold text-gray-800 mb-4">Personal Information</h2>
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <input type="text" name="fullname" class="border border-gray-300 rounded-lg p-2 w-full" placeholder="Full Name" value="<?php echo htmlspecialchars($fullname); ?>">
                    <input type="email" name="email" class="border border-gray-300 rounded-lg p-2 w-full" placeholder="Email Address" value="<?php echo htmlspecialchars($email); ?>">
                    <input type="text" name="phone" class="border border-gray-300 rounded-lg p-2 w-full" placeholder="Phone Number" value="<?php echo htmlspecialchars($phone); ?>">
                </div>
            </div>

            <!-- Billing Address -->
            <div class="mb-6">
                <h2 class="text-lg font-semibold text-gray-800 mb-4">Billing Address</h2>
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <input type="text" name="billingStreet" class="border border-gray-300 rounded-lg p-2 w-full" placeholder="Street Address" value="<?php echo htmlspecialchars($billingStreet); ?>">
                    <input type="text" name="billingSuite" class="border border-gray-300 rounded-lg p-2 w-full" placeholder="Apartment/Suite" value="<?php echo htmlspecialchars($billingSuite); ?>">
                    <input type="text" name="billingCity" class="border border-gray-300 rounded-lg p-2 w-full" placeholder="City" value="<?php echo htmlspecialchars($billingCity); ?>">
                    <input type="text" name="billingDistrict" class="border border-gray-300 rounded-lg p-2 w-full" placeholder="District" value="<?php echo htmlspecialchars($billingDistrict); ?>">
                    <input type="text" name="billingZip" class="border border-gray-300 rounded-lg p-2 w-full" placeholder="ZIP Code" value="<?php echo htmlspecialchars($billingZip); ?>">
                </div>
            </div>

            <!-- Shipping Address -->
            <div class="mb-6">
                <h2 class="text-lg font-semibold text-gray-800 mb-4">Shipping Address</h2>
                <div class="flex items-center mb-4">
                    <input type="checkbox" name="isShippingSame" class="mr-2" <?php echo $isShippingSame ? 'checked' : ''; ?> onclick="toggleShippingAddress(this)">
                    <label class="text-gray-700">Same as billing address</label>
                </div>
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <input type="text" name="shippingStreet" class="border border-gray-300 rounded-lg p-2 w-full" placeholder="Street Address" value="<?php echo htmlspecialchars($shippingStreet); ?>">
                    <input type="text" name="shippingSuite" class="border border-gray-300 rounded-lg p-2 w-full" placeholder="Apartment/Suite" value="<?php echo htmlspecialchars($shippingSuite); ?>">
                    <input type="text" name="shippingCity" class="border border-gray-300 rounded-lg p-2 w-full" placeholder="City" value="<?php echo htmlspecialchars($shippingCity); ?>">
                    <input type="text" name="shippingDistrict" class="border border-gray-300 rounded-lg p-2 w-full" placeholder="District" value="<?php echo htmlspecialchars($shippingDistrict); ?>">
                    <input type="text" name="shippingZip" class="border border-gray-300 rounded-lg p-2 w-full" placeholder="ZIP Code" value="<?php echo htmlspecialchars($shippingZip); ?>">
                </div>
            </div>

            <!-- Buttons -->
            <div class="flex flex-col sm:flex-row justify-end space-y-4 sm:space-y-0 sm:space-x-4">
                <button type="button" class="bg-gray-300 text-gray-800 px-4 py-2 rounded-lg w-full sm:w-auto">Cancel</button>
                <button type="submit" class="bg-blue-500 text-white px-4 py-2 rounded-lg w-full sm:w-auto">Save Changes</button>
            </div>
        </form>
    </div>

    <footer class="mt-10"><?php include '../components/footer.php'; ?></footer>
</body>
</html>