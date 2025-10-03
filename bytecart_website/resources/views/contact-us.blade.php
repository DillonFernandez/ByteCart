<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>ByteCart | Contact Us</title>
    <link rel="icon" type="image/x-icon" href="{{ asset('logo/x-icon.webp') }}">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <style>
        .card-elevated {
            box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);
        }

        .btn-primary {
            background-color: #0479FF;
            transition: all 0.3s ease;
            /* ensure medium components use 9px */
            border-radius: 9px;
        }

        .btn-primary:hover {
            background-color: #0360d0;
            transform: translateY(-1px);
            box-shadow: 0 4px 12px rgba(4, 121, 255, 0.4);
        }

        .form-input {
            border: 1px solid #e5e7eb;
            /* bump from 8px to 9px to match the scale */
            border-radius: 9px;
            padding: 12px 16px;
            width: 100%;
            transition: all 0.3s ease;
            font-size: 14px;
        }

        .form-input:focus {
            outline: none;
            border-color: #0479FF;
            box-shadow: 0 0 0 3px rgba(4, 121, 255, 0.1);
        }

        .contact-icon {
            width: 48px;
            height: 48px;
            background: #f0f8ff;
            /* was 12px; use 9px for medium elements */
            border-radius: 9px;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 16px;
        }

        .section-title {
            font-size: 2rem;
            font-weight: 700;
            color: #1f2937;
            margin-bottom: 0.5rem;
        }

        .section-subtitle {
            color: #6b7280;
            font-size: 1.125rem;
            margin-bottom: 2rem;
        }

        .hero-section {
            text-align: center;
            margin-bottom: 4rem;
        }

        @media (max-width: 768px) {
            .section-title {
                font-size: 1.75rem;
            }

            .hero-section {
                margin-bottom: 2rem;
            }
        }

        /* Border radius hierarchy overrides (18 / 9 / 4.5) */

        /* Make all rounded-xl on this page use 18px */
        .rounded-xl {
            border-radius: 18px;
        }

        /* Small elements (e.g., inline icon in the button) use 4.5px */
        .btn-primary img {
            border-radius: 4.5px;
        }
    </style>
</head>

<body class="bg-white">
    @livewire('nav-bar')

    <div class="container mx-auto pb-8 pt-5 px-5 sm:px-16 sm:pb-10 sm:pt-5">
        <!-- Hero Section -->
        <div class="hero-section">
            <h1 class="section-title">Contact Us</h1>
            <p class="section-subtitle max-w-2xl mx-auto">
                Have questions about our products or need technical support? We're here to help you find the perfect electronics for your needs.
            </p>
        </div>

        <!-- Contact Info Cards -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
            <div class="contact-card card-elevated bg-white p-6 rounded-xl text-center">
                <div class="contact-icon">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 4.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                    </svg>
                </div>
                <h3 class="text-lg font-semibold text-gray-900 mb-2">Email Support</h3>
                <p class="text-blue-600 font-medium mb-1">bytecart@gmail.com</p>
                <p class="text-sm text-gray-500">We'll respond within 24 hours</p>
            </div>

            <div class="contact-card card-elevated bg-white p-6 rounded-xl text-center">
                <div class="contact-icon">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                </div>
                <h3 class="text-lg font-semibold text-gray-900 mb-2">Visit Our Store</h3>
                <p class="text-gray-700 font-medium mb-1">45, Lake View Road</p>
                <p class="text-gray-700 mb-1">Nugegoda, Sri Lanka</p>
                <p class="text-sm text-gray-500">Mon-Sat: 9AM-6PM</p>
            </div>

            <div class="contact-card card-elevated bg-white p-6 rounded-xl text-center">
                <div class="contact-icon">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                    </svg>
                </div>
                <h3 class="text-lg font-semibold text-gray-900 mb-2">Call Us</h3>
                <p class="text-blue-600 font-medium mb-1">+94 76 123 4567</p>
                <p class="text-sm text-gray-500">Available during store hours</p>
            </div>
        </div>

        <!-- Main Content: Form and Map -->
        <div class="grid grid-cols-1 lg:grid-cols-7 gap-8">
            <!-- Contact Form -->
            <div class="lg:col-span-4">
                <div class="card-elevated bg-white p-8 rounded-xl h-full flex flex-col">
                    <div class="mb-8">
                        <h2 class="text-2xl font-bold text-gray-900 mb-3 flex items-center">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 mr-2 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                            </svg>
                            Send us a Message
                        </h2>
                        <p class="text-gray-600">Have a question about our electronics or need support? Fill out the form below and we'll get back to you as soon as possible.</p>
                    </div>

                    <form action="submit_contact.php" method="POST" class="space-y-6 flex-1 flex flex-col">
                        @csrf
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div>
                                <label for="name" class="block text-sm font-medium text-gray-700 mb-2">Full Name *</label>
                                <input
                                    type="text"
                                    name="name"
                                    id="name"
                                    required
                                    class="form-input"
                                    placeholder="Enter your full name">
                            </div>
                            <div>
                                <label for="email" class="block text-sm font-medium text-gray-700 mb-2">Email Address *</label>
                                <input
                                    type="email"
                                    name="email"
                                    id="email"
                                    required
                                    class="form-input"
                                    placeholder="Enter your email address">
                            </div>
                        </div>

                        <div>
                            <label for="subject" class="block text-sm font-medium text-gray-700 mb-2">Subject *</label>
                            <input
                                type="text"
                                name="subject"
                                id="subject"
                                required
                                class="form-input"
                                placeholder="What is this about?">
                        </div>

                        <div>
                            <label for="message" class="block text-sm font-medium text-gray-700 mb-2">Message *</label>
                            <textarea
                                name="message"
                                id="message"
                                rows="6"
                                required
                                class="form-input resize-none"
                                placeholder="Tell us how we can help you..."></textarea>
                        </div>

                        <div class="border-t border-gray-200 pt-6 mt-auto">
                            <button
                                type="submit"
                                class="btn-primary w-full md:w-auto px-8 py-3 rounded-xl font-bold text-lg text-white flex items-center justify-center">
                                <img src="{{ asset('icons/send.webp') }}" alt="Send" class="h-5 w-5 mr-2">
                                Send Message
                            </button>
                        </div>
                    </form>
                </div>
            </div>

            <!-- Map and Store Info -->
            <div class="lg:col-span-3 flex flex-col space-y-6">
                <!-- Store Location Map -->
                <div class="card-elevated bg-white rounded-xl overflow-hidden flex-1 flex flex-col">
                    <div class="p-6 border-b border-gray-200">
                        <h3 class="text-xl font-bold text-gray-900 flex items-center">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                            </svg>
                            Find Our Store
                        </h3>
                    </div>
                    <div class="flex-1 min-h-64">
                        <iframe
                            src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3961.0119228106164!2d79.88057167537768!3d6.889174593109896!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x3ae25a2fcdb28865%3A0x9e6d635aa4d1fec8!2s45%20Lake%20View%20Dr%2C%20Colombo%2000500!5e0!3m2!1sen!2slk!4v1757276948198!5m2!1sen!2slk"
                            width="100%"
                            height="100%"
                            style="border:0;"
                            allowfullscreen=""
                            loading="lazy"
                            referrerpolicy="no-referrer-when-downgrade">
                        </iframe>
                    </div>
                </div>

                <!-- Store Hours -->
                <div class="card-elevated bg-white p-6 rounded-xl">
                    <h3 class="text-xl font-bold text-gray-900 mb-4 flex items-center">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                        Store Hours
                    </h3>
                    <div class="space-y-3">
                        <div class="flex justify-between items-center">
                            <span class="text-gray-600">Monday - Friday</span>
                            <span class="font-medium text-gray-900">9:00 AM - 6:00 PM</span>
                        </div>
                        <div class="flex justify-between items-center">
                            <span class="text-gray-600">Saturday</span>
                            <span class="font-medium text-gray-900">9:00 AM - 5:00 PM</span>
                        </div>
                        <div class="flex justify-between items-center">
                            <span class="text-gray-600">Sunday</span>
                            <span class="font-medium text-red-600">Closed</span>
                        </div>
                    </div>
                </div>

                <!-- Quick Support -->
                <div class="card-elevated bg-blue-50 p-6 rounded-xl border border-blue-200">
                    <h3 class="text-xl font-bold text-gray-900 mb-3 flex items-center">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 5.636l-3.536 3.536m0 5.656l3.536 3.536M9.172 9.172L5.636 5.636m3.536 9.192L5.636 18.364M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-5 0a4 4 0 11-8 0 4 4 0 018 0z" />
                        </svg>
                        Need Quick Help?
                    </h3>
                    <p class="text-gray-700 mb-4">For immediate assistance with your orders or technical support, give us a call during store hours.</p>
                    <a href="tel:+94761234567" class="inline-flex items-center text-blue-600 hover:text-blue-700 font-medium transition-colors">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                        </svg>
                        +94 76 123 4567
                    </a>
                </div>
            </div>
        </div>
    </div>

    @livewire('footer')
</body>

</html>