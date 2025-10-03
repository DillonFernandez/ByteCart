@php
$user = auth()->user();
if (!$user || ($user->roles ?? '') !== 'customer') {
\Illuminate\Support\Facades\Auth::guard('web')->logout();
\Illuminate\Support\Facades\Session::invalidate();
\Illuminate\Support\Facades\Session::regenerateToken();
header('Location: ' . route('login'));
exit;
}
// Helper to check truthy value for checkbox
function isChecked($value) {
return in_array($value, [true, 1, '1'], true);
}
@endphp
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>{{ $user->name ?? 'Shipping Info' }} | Shipping Info</title>
    <link rel="icon" type="image/x-icon" href="{{ asset('logo/x-icon.webp') }}">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <style>
        /* Shipping Info Layout */
        .shipping-info-container {
            display: flex;
            flex-direction: column;
            gap: 2rem;
        }

        .shipping-content {
            width: 100%;
        }

        .page-header {
            margin-bottom: 2rem;
        }

        .page-title {
            font-size: 2rem;
            font-weight: 700;
            color: #1e293b;
            margin: 0 0 0.5rem 0;
            text-align: center;
        }

        .page-subtitle {
            color: #64748b;
            font-size: 1rem;
            margin: 0;
            text-align: center;
        }

        .info-banner {
            background: linear-gradient(135deg, #dbeafe 0%, #bfdbfe 100%);
            border: 1px solid #93c5fd;
            border-radius: 18px;
            padding: 1.5rem;
            margin-bottom: 2rem;
        }

        .info-banner-title {
            font-weight: 600;
            color: #1e40af;
            margin-bottom: 0.5rem;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .info-banner-text {
            color: #1e40af;
            line-height: 1.6;
            margin: 0;
        }

        .help-section {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 18px;
            padding: 1.5rem;
            margin-bottom: 2rem;
        }

        .help-title {
            font-size: 1.125rem;
            font-weight: 600;
            color: #1e293b;
            margin: 0 0 1rem 0;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .help-list {
            list-style: none;
            padding: 0;
            margin: 0 0 1rem 0;
        }

        .help-list li {
            display: flex;
            align-items: flex-start;
            gap: 0.75rem;
            margin-bottom: 0.75rem;
            color: #475569;
            line-height: 1.5;
        }

        .help-list li:before {
            content: '✓';
            color: #16a34a;
            font-weight: 600;
            flex-shrink: 0;
            margin-top: 0.125rem;
        }

        .support-link {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            color: #2563eb;
            text-decoration: none;
            font-weight: 500;
            transition: color 0.2s;
        }

        .support-link:hover {
            color: #1d4ed8;
            text-decoration: underline;
        }

        /* Form Styles */
        .form-section {
            background: white;
            border: none;
            border-radius: 18px;
            padding: 2rem;
            margin-bottom: 1.5rem;
            box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);
        }

        .section-title {
            font-size: 1.25rem;
            font-weight: 600;
            color: #1e293b;
            margin: 0 0 1.5rem 0;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .form-group {
            margin-bottom: 1.5rem;
        }

        .form-label {
            display: block;
            font-weight: 500;
            color: #374151;
            margin-bottom: 0.5rem;
            font-size: 0.875rem;
        }

        .form-input {
            width: 100%;
            padding: 0.75rem 1rem;
            border: 1px solid #d1d5db;
            border-radius: 9px;
            font-size: 0.875rem;
            transition: all 0.2s ease;
            background: white;
            color: #1f2937;
        }

        .form-input:focus {
            outline: none;
            border-color: #2563eb;
            box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
        }

        .form-input.readonly {
            background: #f9fafb;
            color: #6b7280;
        }

        .form-error {
            color: #dc2626;
            font-size: 0.75rem;
            margin-top: 0.25rem;
        }

        .checkbox-group {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            padding: 1rem;
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 9px;
            margin-top: 1rem;
        }

        .checkbox-input {
            width: 18px;
            height: 18px;
            accent-color: #2563eb;
        }

        .checkbox-label {
            font-weight: 500;
            color: #374151;
            font-size: 0.875rem;
        }

        .addresses-grid {
            display: grid;
            gap: 1.5rem;
            grid-template-columns: 1fr;
        }

        .addresses-grid .form-section {
            margin-bottom: 0;
        }

        /* Full width when billing is hidden */
        .addresses-grid:has(#billing-fields[style*="display: none"]) .form-section:first-child {
            grid-column: 1 / -1;
        }

        .submit-button {
            background: #2563eb;
            color: white;
            padding: 0.875rem 2rem;
            border: none;
            border-radius: 9px;
            font-weight: 500;
            font-size: 0.875rem;
            cursor: pointer;
            transition: all 0.2s ease;
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
        }

        .submit-button:hover {
            background: #1d4ed8;
            transform: translateY(-1px);
        }

        .submit-button:active {
            transform: translateY(0);
        }

        /* Status Messages */
        .status-message {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            padding: 1rem 1.25rem;
            border-radius: 18px;
            margin-bottom: 1.5rem;
            font-weight: 500;
        }

        .status-message--success {
            background: #ecfdf5;
            border: 1px solid #a7f3d0;
            color: #065f46;
        }

        .status-message--error {
            background: #fef2f2;
            border: 1px solid #fecaca;
            color: #991b1b;
        }

        .status-icon {
            width: 20px;
            height: 20px;
            flex-shrink: 0;
        }

        .error-list {
            list-style: none;
            margin: 0;
            padding: 0;
        }

        .error-list li {
            margin-bottom: 0.25rem;
        }

        /* Icons */
        .icon {
            width: 20px;
            height: 20px;
            flex-shrink: 0;
        }

        @media (max-width: 767px) {
            .shipping-info-container {
                gap: 0rem;
            }

            .page-header {
                margin-bottom: 1rem;
            }

            .form-section {
                padding: 1.5rem;
            }
        }

        /* Responsive Design */
        @media (min-width: 768px) {
            .shipping-info-container {
                flex-direction: row;
                align-items: flex-start;
                gap: 3rem;
            }

            .shipping-content {
                flex: 1;
            }

            .page-title,
            .page-subtitle {
                text-align: left;
            }

            .addresses-grid {
                grid-template-columns: repeat(2, 1fr);
                gap: 2rem;
            }
        }

        @media (min-width: 1024px) {
            .shipping-info-container {
                gap: 4rem;
            }
        }
    </style>
</head>

<body>
    @livewire('nav-bar')
    <div class="w-full mx-auto pb-8 pt-5 px-4 sm:px-16 sm:pb-10 sm:pt-5">
        <div class="shipping-info-container">
            <!-- Desktop/Mobile Navigation -->
            @livewire('account-navbar')

            <!-- Main Content -->
            <div class="shipping-content">
                <!-- Status Messages -->
                @if (session('success'))
                <div id="status-message" class="status-message status-message--success">
                    <svg class="status-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M9 12l2 2 4-4M21 12c0 4.97-4.03 9-9 9s-9-4.03-9-9 4.03-9 9-9 9 4.03 9 9z" />
                    </svg>
                    {{ session('success') }}
                </div>
                @endif

                @if ($errors->any())
                <div id="error-message" class="status-message status-message--error">
                    <svg class="status-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <circle cx="12" cy="12" r="10" />
                        <line x1="15" y1="9" x2="9" y2="15" />
                        <line x1="9" y1="9" x2="15" y2="15" />
                    </svg>
                    <ul class="error-list">
                        @foreach ($errors->all() as $error)
                        <li>{{ $error }}</li>
                        @endforeach
                    </ul>
                </div>
                @endif

                <!-- Page Header -->
                <div class="page-header">
                    <h1 class="page-title">Shipping Information</h1>
                    <p class="page-subtitle">Manage your delivery and billing addresses</p>
                </div>

                <!-- Info Banner -->
                <div class="info-banner">
                    <div class="info-banner-title">
                        Secure Address Management
                    </div>
                    <p class="info-banner-text">
                        Keep your shipping and billing information up to date for faster checkout and accurate deliveries. All address information is encrypted and kept secure.
                    </p>
                </div>

                <!-- Help Section -->
                <div class="help-section">
                    <h3 class="help-title">
                        Shipping Tips & Support
                    </h3>
                    <ul class="help-list">
                        <li>Your address information is kept private and secure</li>
                        <li>We deliver to most locations across Sri Lanka</li>
                        <li>Delivery times may vary by location and availability</li>
                        <li>Include apartment/suite numbers for accurate delivery</li>
                        <li>Contact support for special delivery instructions</li>
                    </ul>
                    <a class="support-link">
                        <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
                            <polyline points="22,6 12,13 2,6" />
                        </svg>
                        Contact Shipping Support
                    </a>
                </div>

                <!-- Form -->
                <form method="POST" action="{{ route('shipping-info.update') }}">
                    @csrf

                    <!-- Contact Information -->
                    <div class="form-section">
                        <h2 class="section-title">
                            <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07 19.5 19.5 0 01-6-6 19.79 19.79 0 01-3.07-8.67A2 2 0 014.11 2h3a2 2 0 012 1.72 12.84 12.84 0 00.7 2.81 2 2 0 01-.45 2.11L8.09 9.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45 12.84 12.84 0 002.81.7A2 2 0 0122 16.92z" />
                            </svg>
                            Contact Information
                        </h2>
                        <div class="form-group">
                            <label for="phone_number" class="form-label">Phone Number</label>
                            <input type="text" name="phone_number" id="phone_number" class="form-input"
                                pattern="[0-9 ]{10,13}" minlength="10" maxlength="13" inputmode="numeric"
                                title="Enter 10 digits (0-9). Spaces allowed."
                                oninput="
                                    let digits=this.value.replace(/\D/g,'').slice(0,10);
                                    let f=digits;
                                    if(digits.length>6){f=digits.replace(/(\d{3})(\d{3})(\d{1,4})/,'$1 $2 $3');}
                                    else if(digits.length>3){f=digits.replace(/(\d{3})(\d{1,3})/,'$1 $2');}
                                    this.value=f;
                                "
                                value="{{ old('phone_number', $user->phone_number) }}" placeholder="Enter your phone number">
                            @error('phone_number')<div class="form-error">{{ $message }}</div>@enderror
                        </div>
                    </div>

                    <!-- Address Grid -->
                    <div class="addresses-grid">
                        <!-- Shipping Address -->
                        <div class="form-section">
                            <h2 class="section-title">
                                <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z" />
                                    <circle cx="12" cy="10" r="3" />
                                </svg>
                                Shipping Address
                            </h2>

                            <div class="form-group">
                                <label for="shipping_street_address" class="form-label">Street Address</label>
                                <input type="text" name="shipping_street_address" id="shipping_street_address" class="form-input"
                                    value="{{ old('shipping_street_address', $user->shipping_street_address) }}" placeholder="Enter street address">
                                @error('shipping_street_address')<div class="form-error">{{ $message }}</div>@enderror
                            </div>

                            <div class="form-group">
                                <label for="shipping_apartment_suite" class="form-label">Apartment/Suite (Optional)</label>
                                <input type="text" name="shipping_apartment_suite" id="shipping_apartment_suite" class="form-input"
                                    value="{{ old('shipping_apartment_suite', $user->shipping_apartment_suite) }}" placeholder="Apt, suite, unit, etc.">
                                @error('shipping_apartment_suite')<div class="form-error">{{ $message }}</div>@enderror
                            </div>

                            <div class="form-group">
                                <label for="shipping_district" class="form-label">District</label>
                                <input type="text" name="shipping_district" id="shipping_district" class="form-input"
                                    value="{{ old('shipping_district', $user->shipping_district) }}" placeholder="Enter district">
                                @error('shipping_district')<div class="form-error">{{ $message }}</div>@enderror
                            </div>

                            <div class="form-group">
                                <label for="shipping_city" class="form-label">City</label>
                                <input type="text" name="shipping_city" id="shipping_city" class="form-input"
                                    value="{{ old('shipping_city', $user->shipping_city) }}" placeholder="Enter city">
                                @error('shipping_city')<div class="form-error">{{ $message }}</div>@enderror
                            </div>

                            <div class="form-group">
                                <label for="shipping_zip_code" class="form-label">Zip Code</label>
                                <input type="text" name="shipping_zip_code" id="shipping_zip_code" class="form-input"
                                    pattern="[0-9]{5}" minlength="5" maxlength="5" inputmode="numeric"
                                    title="Enter exactly 5 digits (0-9)"
                                    oninput="this.value=this.value.replace(/[^0-9]/g,'').slice(0,5)"
                                    value="{{ old('shipping_zip_code', $user->shipping_zip_code) }}" placeholder="Enter zip code">
                                @error('shipping_zip_code')<div class="form-error">{{ $message }}</div>@enderror
                            </div>

                            <div class="checkbox-group">
                                <input type="checkbox" name="is_billing_same_as_shipping" id="is_billing_same_as_shipping" value="1" class="checkbox-input"
                                    {{ isChecked(old('is_billing_same_as_shipping', $user->is_billing_same_as_shipping)) ? 'checked' : '' }}>
                                <label for="is_billing_same_as_shipping" class="checkbox-label">Billing address is same as shipping address</label>
                            </div>
                        </div>

                        <!-- Billing Address -->
                        <div id="billing-fields" class="form-section" @php echo 'style="display: ' . (isChecked(old('is_billing_same_as_shipping', $user->is_billing_same_as_shipping)) ? 'none' : 'block') . ';"'; @endphp>
                            <h2 class="section-title">
                                <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <rect x="1" y="4" width="22" height="16" rx="2" ry="2" />
                                    <line x1="1" y1="10" x2="23" y2="10" />
                                </svg>
                                Billing Address
                            </h2>

                            <div class="form-group">
                                <label for="billing_street_address" class="form-label">Street Address</label>
                                <input type="text" name="billing_street_address" id="billing_street_address" class="form-input"
                                    value="{{ old('billing_street_address', $user->billing_street_address) }}" placeholder="Enter street address">
                                @error('billing_street_address')<div class="form-error">{{ $message }}</div>@enderror
                            </div>

                            <div class="form-group">
                                <label for="billing_apartment_suite" class="form-label">Apartment/Suite (Optional)</label>
                                <input type="text" name="billing_apartment_suite" id="billing_apartment_suite" class="form-input"
                                    value="{{ old('billing_apartment_suite', $user->billing_apartment_suite) }}" placeholder="Apt, suite, unit, etc.">
                                @error('billing_apartment_suite')<div class="form-error">{{ $message }}</div>@enderror
                            </div>

                            <div class="form-group">
                                <label for="billing_district" class="form-label">District</label>
                                <input type="text" name="billing_district" id="billing_district" class="form-input"
                                    value="{{ old('billing_district', $user->billing_district) }}" placeholder="Enter district">
                                @error('billing_district')<div class="form-error">{{ $message }}</div>@enderror
                            </div>

                            <div class="form-group">
                                <label for="billing_city" class="form-label">City</label>
                                <input type="text" name="billing_city" id="billing_city" class="form-input"
                                    value="{{ old('billing_city', $user->billing_city) }}" placeholder="Enter city">
                                @error('billing_city')<div class="form-error">{{ $message }}</div>@enderror
                            </div>

                            <div class="form-group">
                                <label for="billing_zip_code" class="form-label">Zip Code</label>
                                <input type="text" name="billing_zip_code" id="billing_zip_code" class="form-input"
                                    pattern="[0-9]{5}" minlength="5" maxlength="5" inputmode="numeric"
                                    title="Enter exactly 5 digits (0-9)"
                                    oninput="this.value=this.value.replace(/[^0-9]/g,'').slice(0,5)"
                                    value="{{ old('billing_zip_code', $user->billing_zip_code) }}" placeholder="Enter zip code">
                                @error('billing_zip_code')<div class="form-error">{{ $message }}</div>@enderror
                            </div>
                        </div>
                    </div>

                    <!-- Submit Button -->
                    <button type="submit" class="submit-button mt-5">
                        <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M19 21H5a2 2 0 01-2-2V5a2 2 0 012-2h11l5 5v11a2 2 0 01-2 2z" />
                            <polyline points="17,21 17,13 7,13 7,21" />
                            <polyline points="7,3 7,8 15,8" />
                        </svg>
                        Save Address Information
                    </button>
                </form>
            </div>
        </div>
    </div>
    @livewire('footer')

    <!-- Success popup: make the card 18px -->
    <style>
        #shippingSuccessPopup>div {
            border-radius: 18px !important;
        }
    </style>

    <div id="shippingSuccessPopup" class="fixed inset-0 z-50 bg-black bg-opacity-40 hidden px-4" style="display: none; align-items: center; justify-content: center;">
        <div class="bg-white rounded-lg shadow-lg p-6 w-full max-w-sm relative mx-2 flex flex-col items-center">
            <button id="closeShippingSuccessPopup" class="absolute top-2 right-2 text-gray-400 hover:text-gray-600 text-xl">&times;</button>
            <h3 class="text-lg font-semibold mb-4 text-green-600">Success</h3>
            <span id="shippingSuccessPopupMsg" class="text-gray-700 text-center">{{ session('success') }}</span>
        </div>
    </div>
    <script>
        const billingFields = document.getElementById('billing-fields');
        const billingCheckbox = document.getElementById('is_billing_same_as_shipping');
        // Billing field ids
        const billingFieldIds = [
            'billing_street_address',
            'billing_apartment_suite',
            'billing_city',
            'billing_district',
            'billing_zip_code'
        ];
        const shippingFieldIds = [
            'shipping_street_address',
            'shipping_apartment_suite',
            'shipping_city',
            'shipping_district',
            'shipping_zip_code'
        ];

        function syncBillingFields(disable) {
            for (let i = 0; i < billingFieldIds.length; i++) {
                const billingInput = document.getElementById(billingFieldIds[i]);
                const shippingInput = document.getElementById(shippingFieldIds[i]);
                if (billingInput && shippingInput) {
                    if (disable) {
                        billingInput.value = shippingInput.value;
                        billingInput.setAttribute('readonly', 'readonly');
                        billingInput.classList.add('bg-gray-100');
                    } else {
                        billingInput.removeAttribute('readonly');
                        billingInput.classList.remove('bg-gray-100');
                    }
                }
            }
        }

        function updateAddressLayout() {
            const addressesGrid = document.querySelector('.addresses-grid');
            const shippingSection = addressesGrid.querySelector('.form-section:first-child');

            if (billingCheckbox.checked) {
                // Make shipping form full width when billing is hidden
                if (window.innerWidth >= 768) {
                    shippingSection.style.gridColumn = '1 / -1';
                }
            } else {
                // Reset to normal grid when billing is shown
                shippingSection.style.gridColumn = '';
            }
        }

        billingCheckbox.addEventListener('change', function() {
            billingFields.style.display = this.checked ? 'none' : 'block';
            syncBillingFields(this.checked);
            updateAddressLayout();
        });
        // Ensure correct initial state on page load
        document.addEventListener('DOMContentLoaded', function() {
            billingFields.style.display = billingCheckbox.checked ? 'none' : 'block';
            syncBillingFields(billingCheckbox.checked);
            updateAddressLayout();

            // Also update billing fields if shipping fields change while checked
            for (let i = 0; i < shippingFieldIds.length; i++) {
                const shippingInput = document.getElementById(shippingFieldIds[i]);
                if (shippingInput) {
                    shippingInput.addEventListener('input', function() {
                        if (billingCheckbox.checked) {
                            syncBillingFields(true);
                        }
                    });
                }
            }
        });

        // Update layout on window resize
        window.addEventListener('resize', updateAddressLayout);

        // Auto-hide status messages after 5 seconds
        document.addEventListener('DOMContentLoaded', function() {
            const statusMessage = document.getElementById('status-message');
            const errorMessage = document.getElementById('error-message');

            function hideMessage(element) {
                if (element) {
                    setTimeout(function() {
                        element.style.transition = 'opacity 0.5s ease-out';
                        element.style.opacity = '0';
                        setTimeout(function() {
                            element.style.display = 'none';
                        }, 500);
                    }, 5000);
                }
            }

            hideMessage(statusMessage);
            hideMessage(errorMessage);
        });
    </script>
</body>

</html>