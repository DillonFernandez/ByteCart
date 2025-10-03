<!-- Footer (Blade)
     Responsive site footer with brand/social, contact info, quick links, customer service, newsletter, and legal/payment sections. -->
<!DOCTYPE html>
<html lang="en">

<head>
    <!-- Head: meta and Tailwind -->
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script src="https://cdn.tailwindcss.com"></script>
</head>

<footer class="bg-[#0D1117] text-white pt-10 pb-6"
    style="box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);">
    <div class="container mx-auto px-5 md:px-10">
        <div class="flex flex-col md:flex-row md:justify-between md:items-start gap-10 border-b border-white/20 pb-8">
            <!-- Section: Brand and social links -->
            <div class="flex-1 min-w-[180px] md:mb-0">
                <img src="{{ asset('logo/logo.webp') }}" alt="ByteCart Logo"
                    class="h-12 mb-4 transition-transform duration-300 hover:scale-105">
                <p class="mb-4 text-base font-medium">Your trusted electronics partner since 2025</p>
                <div class="flex space-x-4">
                    <a class="group">
                        <img src="{{ asset('icons/facebook.webp') }}" alt="Facebook"
                            class="h-7 w-7 rounded-full bg-white/10 p-1 transition-all duration-300 group-hover:bg-[#0479FF] group-hover:scale-110">
                    </a>
                    <a class="group">
                        <img src="{{ asset('icons/x.webp') }}" alt="Twitter"
                            class="h-7 w-7 rounded-full bg-white/10 p-1 transition-all duration-300 group-hover:bg-[#0479FF] group-hover:scale-110">
                    </a>
                    <a class="group">
                        <img src="{{ asset('icons/instagram.webp') }}" alt="Instagram"
                            class="h-7 w-7 rounded-full bg-white/10 p-1 transition-all duration-300 group-hover:bg-[#0479FF] group-hover:scale-110">
                    </a>
                </div>
            </div>

            <!-- Section: Contact info -->
            <div class="flex-1 min-w-[180px] md:mb-0">
                <h3 class="text-lg font-bold mb-4 text-[#0479FF]">Contact Info</h3>
                <ul class="space-y-2 text-base">
                    <li>
                        <div class="flex items-center gap-2">
                            <img src="{{ asset('icons/email f.webp') }}" alt="Email" class="h-5 w-5">
                            <span>bytecart@gmail.com</span>
                        </div>
                    </li>
                    <li>
                        <div class="flex items-center gap-2">
                            <img src="{{ asset('icons/location f.webp') }}" alt="Location" class="h-5 w-5">
                            <span>45, Lake View Dr, Colombo 00500</span>
                        </div>
                    </li>
                    <li>
                        <div class="flex items-center gap-2">
                            <img src="{{ asset('icons/phone f.webp') }}" alt="Phone" class="h-5 w-5">
                            <span>+94 76 123 4567</span>
                        </div>
                    </li>
                </ul>
            </div>

            <!-- Section: Quick links -->
            <div class="flex-1 min-w-[150px] md:mb-0">
                <h3 class="text-lg font-bold mb-4 text-[#0479FF]">Quick Links</h3>
                <ul class="space-y-2">
                    <li><a href="{{ route('about-us') }}" class="hover:text-[#0479FF] transition-colors">About Us</a>
                    </li>
                    <li><a href="{{ route('shop-all') }}" class="hover:text-[#0479FF] transition-colors">Shop All</a>
                    </li>
                    <li><a href="{{ route('shop-all', ['new_stock' => 1]) }}"
                            class="hover:text-[#0479FF] transition-colors">New Products</a></li>
                    <li><a href="{{ route('shop-all', ['discounted' => 1]) }}"
                            class="hover:text-[#0479FF] transition-colors">Discount Products</a></li>
                </ul>
            </div>

            <!-- Section: Customer service -->
            <div class="flex-1 min-w-[150px] md:mb-0">
                <h3 class="text-lg font-bold mb-4 text-[#0479FF]">Customer Service</h3>
                <ul class="space-y-2">
                    <li><a class="hover:text-[#0479FF] transition-colors">FAQ</a></li>
                    <li><a class="hover:text-[#0479FF] transition-colors">Shipping &amp; Returns</a></li>
                    <li><a class="hover:text-[#0479FF] transition-colors">Warranty / Repairs</a></li>
                    <li><a class="hover:text-[#0479FF] transition-colors">Track Order</a></li>
                    <li><a href="{{ route('contact-us') }}"
                            class="hover:text-[#0479FF] transition-colors">Contact Us</a></li>
                </ul>
            </div>

            <!-- Section: Newsletter form and app badges -->
            <div class="flex-1 min-w-[200px] md:mb-0">
                <h3 class="text-lg font-bold mb-4 text-[#0479FF]">Newsletter</h3>
                <p class="mb-4 text-base">Subscribe to get special offers and updates</p>
                <form class="flex items-center h-12" onsubmit="return false">
                    @csrf
                    <input type="email" placeholder="Your email"
                        class="bg-white/90 text-[#0D1117] placeholder-[#0D1117] px-4 py-2 focus:outline-none w-full h-10 border border-[#0479FF] focus:ring-2 focus:ring-[#0479FF] transition-all"
                        style="border-top-left-radius: 9px; border-bottom-left-radius: 9px;">
                    <button type="submit"
                        class="bg-[#0479FF] text-white px-4 h-10 flex items-center justify-center transition-colors hover:bg-[#005bb5]"
                        style="border-top-right-radius: 9px; border-bottom-right-radius: 9px;">
                        <img src="{{ asset('icons/send.webp') }}" alt="Submit Icon" class="w-6 h-5">
                    </button>
                </form>
                <!-- Google Play download icons under input field -->
                <div class="flex gap-2 mt-5">
                    <img src="{{ asset('icons/google play download.webp') }}" alt="Google Play Download"
                        class="h-10 w-auto">
                    <img src="{{ asset('icons/app store download.webp') }}" alt="Apple App Store Download"
                        class="h-10 w-auto">
                </div>
            </div>
        </div> <!-- end of .container -->
    </div>

    <!-- Bar: legal and payment methods -->
    <div class="pt-4 pb-4 px-5 mt-6 text-center text-white mx-auto max-w-[90%] md:max-w-[95%] text-sm bg-white/5 flex flex-col items-center justify-center md:flex-row md:items-center md:justify-between"
        style="border-radius: 9px; box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);">
        <!-- Subsection: copyright -->
        <div class="mb-2 md:mb-0 text-center md:text-left w-full md:w-auto">
            © 2025 <span class="font-semibold text-[#0479FF]">ByteCart</span>. All rights reserved.
        </div>
        <!-- Subsection: payment icons -->
        <div class="flex flex-wrap justify-center gap-2 md:gap-4 w-full md:w-auto">
            <img src="{{ asset('icons/visa.webp') }}" alt="Visa"
                class="h-6 w-auto bg-white/10 p-1" style="border-radius: 4.5px;" title="Visa">
            <img src="{{ asset('icons/mastercard.webp') }}" alt="Mastercard"
                class="h-6 w-auto bg-white/10 p-1" style="border-radius: 4.5px;" title="Mastercard">
            <img src="{{ asset('icons/koko.webp') }}" alt="Koko"
                class="h-6 w-auto bg-white/10 p-1" style="border-radius: 4.5px;" title="Koko">
            <img src="{{ asset('icons/mintpay.webp') }}" alt="MintPay"
                class="h-6 w-auto bg-white/10 p-1" style="border-radius: 4.5px;" title="MintPay">
            <img src="{{ asset('icons/cod.webp') }}" alt="Cash on Delivery"
                class="h-6 w-auto bg-white/10 p-1" style="border-radius: 4.5px;" title="Cash on Delivery">
        </div>
    </div>
</footer>

</html>