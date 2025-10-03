<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>ByteCart | About Us</title>
    <link rel="icon" type="image/x-icon" href="{{ asset('logo/x-icon.webp') }}">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <style>
        .hero-bg {
            background: linear-gradient(120deg, #2563eb 0%, #60a5fa 100%);
            position: relative;
            overflow: hidden;
        }

        .hero-overlay {
            background: linear-gradient(135deg, rgba(59, 130, 246, 0.7) 0%, rgba(255, 255, 255, 0.7) 100%);
            position: absolute;
            inset: 0;
            z-index: 1;
            opacity: 0.85;
        }

        .hero-content {
            position: relative;
            z-index: 2;
        }

        .hero-content h1 {
            letter-spacing: 1px;
            text-shadow: 0 6px 32px rgba(30, 41, 59, 0.18);
        }

        .section-title {
            font-size: 2.25rem;
            font-weight: 800;
            color: #2563eb;
            margin-bottom: 1.5rem;
            letter-spacing: 0.5px;
        }

        .icon-circle {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            background: linear-gradient(135deg, #2563eb 60%, #60a5fa 100%);
            border-radius: 50%;
            width: 56px;
            height: 56px;
            margin-bottom: 1rem;
            box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);
        }

        .card {
            background: #fff;
            border-radius: 18px;
            box-shadow: var(--card-shadow);
            transition: box-shadow 0.2s, transform 0.2s;
        }

        .cta-gradient {
            background: linear-gradient(90deg, #2563eb 0%, #60a5fa 100%);
            color: #fff;
            box-shadow: 0 8px 32px 0 rgba(30, 41, 59, 0.18);
        }

        /* Product Card Shadow for all cards/info boxes */
        :root {
            --card-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);
        }

        /* Override Tailwind shadow classes for cards/info boxes */
        .shadow-lg {
            box-shadow: var(--card-shadow) !important;
        }
    </style>
</head>

<body>
    @livewire('nav-bar')
    <!-- Hero Section -->
    <section class="hero-bg py-14 md:py-28 px-6 text-center relative">
        <div class="hero-overlay"></div>
        <div class="hero-content max-w-3xl mx-auto">
            <span class="icon-circle">
                <!-- SVG: Lightning Bolt -->
                <svg fill="none" viewBox="0 0 32 32" stroke="white" class="w-8 h-8">
                    <path d="M16 4l-8 12h6v12l8-12h-6V4z" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
                </svg>
            </span>
            <h1 class="text-5xl md:text-6xl font-extrabold text-white drop-shadow mb-6">About ByteCart</h1>
            <p class="text-lg md:text-xl text-white/90 font-medium mb-2">
                Discover how ByteCart is redefining tech retail with premium products, seamless service, and unmatched trust.
            </p>
        </div>
    </section>

    <!-- Company Story -->
    <section class="bg-white max-w-7xl mx-auto px-6 py-10 md:py-20 grid md:grid-cols-2 gap-12">
        <div class="space-y-6">
            <h2 class="section-title">Who We Are</h2>
            <p class="text-lg leading-relaxed">
                ByteCart is a modern tech-focused retailer offering an in-house catalog with full control and no third-party vendors.
                We grow organically while keeping our service personal and quality-driven.
            </p>
            <p class="text-lg">
                Our mission is to deliver premium technology with a streamlined shopping experience tailored for tech-savvy customers.
            </p>
        </div>
        <div class="card p-10 flex flex-col justify-center">
            <span class="icon-circle mx-auto mb-4">
                <!-- SVG: Chart Bar -->
                <svg fill="none" viewBox="0 0 32 32" stroke="#fff" class="w-7 h-7">
                    <rect x="6" y="16" width="4" height="8" rx="1.5" fill="#fff" opacity="0.7" />
                    <rect x="14" y="12" width="4" height="12" rx="1.5" fill="#fff" opacity="0.7" />
                    <rect x="22" y="8" width="4" height="16" rx="1.5" fill="#fff" opacity="0.7" />
                </svg>
            </span>
            <h3 class="text-2xl font-semibold text-blue-600 mb-6">ByteCart in Numbers</h3>
            <ul class="space-y-4 text-base">
                <li><strong>Founded:</strong> 2025</li>
                <li><strong>Customers:</strong> 10,000+ and growing</li>
                <li><strong>Product Catalog:</strong> 100% in-house curated</li>
                <li><strong>Platform:</strong> Optimized for mobile-first experiences</li>
                <li><strong>Reach:</strong> Nationwide & regional presence</li>
            </ul>
        </div>
    </section>

    <!-- Mission, Vision, Values -->
    <section class="bg-blue-50 py-10 md:py-20 px-6">
        <div class="max-w-7xl mx-auto grid md:grid-cols-3 gap-10 text-center">
            <div class="card bg-blue-50 p-8 rounded-xl">
                <span class="icon-circle mx-auto mb-3">
                    <!-- Replaced SVG: Rocket with image -->
                    <img src="{{ asset('icons/rocket.webp') }}" alt="Rocket Icon" style="width: 32px; height: 32px;">
                </span>
                <h3 class="text-2xl font-bold text-blue-600 mb-3">Mission</h3>
                <p class="text-base text-gray-700">Deliver innovative electronics through a customer-first digital experience.</p>
            </div>
            <div class="card bg-blue-50 p-8 rounded-xl">
                <span class="icon-circle mx-auto mb-3">
                    <!-- Replaced SVG: Eye with image -->
                    <img src="{{ asset('icons/eye.webp') }}" alt="Eye Icon" style="width: 32px; height: 32px;">
                </span>
                <h3 class="text-2xl font-bold text-blue-600 mb-3">Vision</h3>
                <p class="text-base text-gray-700">Become the region's most trusted, tech-focused online store.</p>
            </div>
            <div class="card bg-blue-50 p-8 rounded-xl">
                <span class="icon-circle mx-auto mb-3">
                    <!-- Replaced SVG: Heart with image -->
                    <img src="{{ asset('icons/heart.webp') }}" alt="Heart Icon" style="width: 32px; height: 32px;">
                </span>
                <h3 class="text-2xl font-bold text-blue-600 mb-3">Core Values</h3>
                <p class="text-base text-gray-700">Innovation, transparency, customer-focus, and operational excellence.</p>
            </div>
        </div>
    </section>

    <!-- Why We're Unique -->
    <section class="bg-gray-50">
        <div class="max-w-7xl mx-auto px-6 py-10 md:py-20">
            <h2 class="section-title text-center">Why ByteCart Stands Out</h2>
            <div class="grid md:grid-cols-3 gap-10">
                <?php
                $features = [
                    "No third-party sellers" => "Only ByteCart products. Full quality control.",
                    "Electronics focused" => "Phones, laptops, audio, wearables – that’s all we do.",
                    "Smart product suggestions" => "AI-based recommendations to help you shop smarter.",
                    "Modern UX" => "Fast, responsive, and mobile-friendly interface.",
                    "Secure payments" => "SSL-encrypted with tokenized transactions.",
                    "Hassle-free returns" => "Flexible return policies with quick support."
                ];
                foreach ($features as $title => $desc): ?>
                    <div class="card p-8 rounded-2xl text-center">
                        <h4 class="text-xl font-semibold text-blue-600 mb-3">{{ $title }}</h4>
                        <p class="text-base text-gray-700">{{ $desc }}</p>
                    </div>
                <?php endforeach; ?>
            </div>
        </div>
    </section>

    <!-- Product Categories -->
    <section class="bg-white py-10 md:py-20 px-6">
        <h2 class="section-title text-center">Product Categories</h2>
        <div class="max-w-7xl mx-auto grid sm:grid-cols-2 md:grid-cols-4 gap-8 text-center">
            <?php
            $categories = [
                "Smartphones & Accessories" => "Phones, cases, chargers & protectors.",
                "Computers & Laptops" => "Laptops, desktops, monitors & accessories.",
                "Audio & Headphones" => "Earbuds, headphones, speakers & gear.",
                "Gaming & Entertainment" => "Consoles, VR, controllers & setups.",
                "Cameras & Photography" => "DSLRs, lenses, gimbals & tripods.",
                "Smart Home & Security" => "Smart plugs, lights, locks & cameras.",
                "Home Appliances" => "ACs, washers, refrigerators & blenders.",
                "Wearable Tech" => "Smartwatches, trackers, glasses & rings."
            ];
            foreach ($categories as $cat => $desc): ?>
                <div class="card p-7 rounded-2xl">
                    <h4 class="font-semibold text-blue-600 text-lg mb-2">{{ $cat }}</h4>
                    <p class="text-base text-gray-700">{{ $desc }}</p>
                </div>
            <?php endforeach; ?>
        </div>
    </section>

    <!-- Payment Methods -->
    <section class="bg-blue-50 py-10 md:py-20 px-6">
        <h2 class="section-title text-center">Payment Methods</h2>
        <div class="max-w-5xl mx-auto grid sm:grid-cols-2 md:grid-cols-5 gap-8 text-center">
            <?php
            $payments = [
                ["visa.webp", "Pay securely with Visa cards."],
                ["mastercard.webp", "Accepted worldwide for easy payments."],
                ["koko.webp", "Buy now, pay later with Koko."],
                ["mintpay.webp", "Flexible installments via MintPay."],
                ["cod.webp", "Pay with cash when your order arrives."]
            ];
            foreach ($payments as [$icon, $desc]): ?>
                <div class="card p-7 rounded-2xl flex flex-col items-center">
                    <?php if ($icon === "mastercard.webp"): ?>
                        <img src="{{ asset('icons/' . $icon) }}" alt="MasterCard Icon" style="height: 40px; margin-bottom: 15px;">
                    <?php else: ?>
                        <img src="{{ asset('icons/' . $icon) }}" alt="{{ $icon }} Icon" style="height: 30px; margin-bottom: 25px;">
                    <?php endif; ?>
                    <p class="text-base text-gray-700">{{ $desc }}</p>
                </div>
            <?php endforeach; ?>
        </div>
    </section>

    <!-- Available on Mobile -->
    <section class="bg-gray-50 py-10 md:py-20 px-6">
        <h2 class="section-title text-center">Available on Mobile</h2>
        <div class="max-w-xl mx-auto grid sm:grid-cols-2 gap-8 text-center">
            <div class="card p-7 rounded-2xl flex flex-col items-center">
                <!-- Removed .icon-circle -->
                <img src="{{ asset('icons/google play.webp') }}" alt="Google Play" style="width: 50px; margin-bottom: 12px;">
                <h4 class="font-semibold text-blue-600 text-lg mb-2">Google Play</h4>
                <p class="text-base text-gray-700 mb-3">Download the ByteCart app for Android devices.</p>
                <img src="{{ asset('icons/google play download.webp') }}" alt="Google Play Store" style="width: 120px;">
            </div>
            <div class="card p-7 rounded-2xl flex flex-col items-center">
                <!-- Removed .icon-circle -->
                <img src="{{ asset('icons/app store.webp') }}" alt="App Store" style="width: 50px; margin-bottom: 12px;">
                <h4 class="font-semibold text-blue-600 text-lg mb-2">Apple App Store</h4>
                <p class="text-base text-gray-700 mb-3">Download the ByteCart app for iOS devices.</p>
                <img src="{{ asset('icons/app store download.webp') }}" alt="Apple App Store" style="width: 120px;">
            </div>
        </div>
    </section>

    <!-- Final CTA -->
    <section class="py-14 md:py-28 px-6 cta-gradient text-center">
        <span class="icon-circle mx-auto mb-4">
            <!-- Replaced SVG: Shopping Cart with image -->
            <img src="{{ asset('icons/about us cart.webp') }}" alt="Cart Icon" style="width: 32px; height: 32px;">
        </span>
        <h2 class="text-3xl font-bold mb-6">Experience ByteCart Today</h2>
        <p class="text-lg mb-8">Shop premium tech essentials with confidence and care.</p>
        <a href="{{ route('shop-all') }}" class="inline-block bg-white text-blue-600 px-10 py-4 rounded-full text-lg font-semibold hover:bg-blue-700 hover:text-white transition duration-200 shadow-lg">
            Shop Now
        </a>
    </section>
    @livewire('footer')
</body>

</html>