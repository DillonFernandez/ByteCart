@php
$user = auth()->user();
if (!$user || ($user->roles ?? '') !== 'customer') {
\Illuminate\Support\Facades\Auth::guard('web')->logout();
\Illuminate\Support\Facades\Session::invalidate();
\Illuminate\Support\Facades\Session::regenerateToken();
header('Location: ' . route('login'));
exit;
}

$maskedCard = '';
if (!empty($user->card_number)) {
try {
$plain = decrypt($user->card_number); // fixed: added missing ')'
// mask all but last 4 digits
$maskedCard = preg_replace('/\d(?=\d{4})/', '*', preg_replace('/\D/', '', $plain));
// format as groups if 16 digits
if (strlen($maskedCard) === 16) {
$maskedCard = trim(chunk_split($maskedCard, 4, ' '));
}
} catch (\Throwable $e) {
$maskedCard = '';
}
}
$decryptedName = '';
if (!empty($user->cardholder_name)) {
try { $decryptedName = decrypt($user->cardholder_name); } catch (\Throwable $e) {}
}
$decryptedExpiry = '';
if (!empty($user->expiry_date)) {
try { $decryptedExpiry = decrypt($user->expiry_date); } catch (\Throwable $e) {}
}
// Never show CVV
@endphp
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>{{ $user->name ?? 'Payment Methods' }} | Payment Methods</title>
    <link rel="icon" type="image/x-icon" href="{{ asset('logo/x-icon.webp') }}">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <style>
        /* Payment Methods Layout */
        .payment-methods-container {
            display: flex;
            flex-direction: column;
            gap: 2rem;
        }

        .payment-content {
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

        .payment-icons {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            padding: 1rem;
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 9px;
            margin-bottom: 1.5rem;
            flex-wrap: wrap;
        }

        .payment-icons img {
            height: 2rem;
            width: auto;
            background: white;
            border-radius: 4.5px;
            padding: 0.25rem;
            box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1);
        }

        .payment-options {
            display: grid;
            gap: 0.75rem;
        }

        .payment-option {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            padding: 1rem;
            border: 2px solid #e5e7eb;
            border-radius: 9px;
            cursor: pointer;
            transition: all 0.2s ease;
            background: white;
        }

        .payment-option:hover {
            border-color: #3b82f6;
            background: #f8fafc;
        }

        .payment-option.selected {
            border-color: #2563eb;
            background: #eff6ff;
        }

        .payment-option input[type="radio"] {
            width: 18px;
            height: 18px;
            accent-color: #2563eb;
        }

        .payment-option-label {
            font-weight: 500;
            color: #374151;
            font-size: 0.875rem;
            cursor: pointer;
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

        .form-row {
            display: grid;
            grid-template-columns: 1fr 100px;
            gap: 1rem;
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

        /* Icons */
        .icon {
            width: 20px;
            height: 20px;
            flex-shrink: 0;
        }

        @media (max-width: 767px) {
            .payment-methods-container {
                gap: 0rem;
            }

            .page-header {
                margin-bottom: 1rem;
            }

            .form-section {
                padding: 1.5rem;
            }

            .payment-icons {
                justify-content: center;
            }

            .payment-icons img {
                height: 1.75rem;
            }

            .form-row {
                grid-template-columns: 1fr;
            }
        }

        /* Responsive Design */
        @media (min-width: 768px) {
            .payment-methods-container {
                flex-direction: row;
                align-items: flex-start;
                gap: 3rem;
            }

            .payment-content {
                flex: 1;
            }

            .page-title,
            .page-subtitle {
                text-align: left;
            }

            .payment-icons {
                justify-content: flex-start;
            }
        }

        @media (min-width: 1024px) {
            .payment-methods-container {
                gap: 4rem;
            }
        }
    </style>
</head>

<body>
    @livewire('nav-bar')
    <div class="w-full mx-auto pb-8 pt-5 px-4 sm:px-16 sm:pb-10 sm:pt-5">
        <div class="payment-methods-container">
            <!-- Desktop/Mobile Navigation -->
            @livewire('account-navbar')

            <!-- Main Content -->
            <div class="payment-content">
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
                    <h1 class="page-title">Payment Methods</h1>
                    <p class="page-subtitle">Manage your payment preferences and billing options</p>
                </div>

                <!-- Info Banner -->
                <div class="info-banner">
                    <div class="info-banner-title">
                        Secure Payment Processing
                    </div>
                    <p class="info-banner-text">
                        Choose your preferred payment method for a seamless checkout experience. All payment information is encrypted and securely processed to protect your financial data.
                    </p>
                </div>

                <!-- Help Section -->
                <div class="help-section">
                    <h3 class="help-title">
                        Payment Options & Support
                    </h3>
                    <ul class="help-list">
                        <li>All card payments are encrypted and securely processed</li>
                        <li>Refunds are processed within 5-7 business days for eligible transactions</li>
                        <li>Installment options (Koko, Mintpay) are subject to provider approval</li>
                        <li>Cash on Delivery available for select locations and order values</li>
                        <li>Contact support for payment-related questions or issues</li>
                    </ul>
                    <a class="support-link">
                        <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
                            <polyline points="22,6 12,13 2,6" />
                        </svg>
                        Contact Payment Support
                    </a>
                </div>

                <!-- Form -->
                <form method="POST" action="{{ route('payment-methods.store') }}" id="payment-method-form">
                    @csrf

                    <!-- Payment Method Selection -->
                    <div class="form-section">
                        <h2 class="section-title">
                            <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <rect x="1" y="4" width="22" height="16" rx="2" ry="2" />
                                <line x1="1" y1="10" x2="23" y2="10" />
                            </svg>
                            Select Payment Method
                        </h2>

                        <!-- Payment Icons -->
                        <div class="payment-icons">
                            <img src="{{ asset('icons/visa.webp') }}" alt="Visa" title="Visa">
                            <img src="{{ asset('icons/mastercard.webp') }}" alt="Mastercard" title="Mastercard">
                            <img src="{{ asset('icons/koko.webp') }}" alt="Koko" title="Koko">
                            <img src="{{ asset('icons/mintpay.webp') }}" alt="MintPay" title="MintPay">
                            <img src="{{ asset('icons/cod.webp') }}" alt="Cash on Delivery" title="Cash on Delivery">
                        </div>

                        <!-- Payment Options -->
                        <div class="payment-options">
                            <label class="payment-option">
                                <input type="radio" name="payment_method" value="Visa/MasterCard" required
                                    {{ old('payment_method', $user->payment_method) == 'Visa/MasterCard' ? 'checked' : '' }}>
                                <span class="payment-option-label">Visa / MasterCard</span>
                            </label>

                            <label class="payment-option">
                                <input type="radio" name="payment_method" value="Koko"
                                    {{ old('payment_method', $user->payment_method) == 'Koko' ? 'checked' : '' }}>
                                <span class="payment-option-label">Koko (Installment/Pay Later)</span>
                            </label>

                            <label class="payment-option">
                                <input type="radio" name="payment_method" value="Mintpay"
                                    {{ old('payment_method', $user->payment_method) == 'Mintpay' ? 'checked' : '' }}>
                                <span class="payment-option-label">Mintpay (Installment/Pay Later)</span>
                            </label>

                            <label class="payment-option">
                                <input type="radio" name="payment_method" value="COD"
                                    {{ old('payment_method', $user->payment_method) == 'COD' ? 'checked' : '' }}>
                                <span class="payment-option-label">Cash on Delivery (COD)</span>
                            </label>
                        </div>
                    </div>

                    <!-- Card Details Section -->
                    <div id="card-fields" class="form-section" style="display: none;">
                        <h2 class="section-title">
                            <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <rect x="1" y="4" width="22" height="16" rx="2" ry="2" />
                                <line x1="1" y1="10" x2="23" y2="10" />
                            </svg>
                            Card Details
                        </h2>

                        <div class="form-group">
                            <label class="form-label">Card Number</label>
                            <input type="text" name="card_number" maxlength="23"
                                pattern="[0-9* ]{12,23}" title="Enter 12-19 digits (spaces allowed). Masked accepted."
                                placeholder="#### #### #### ####" class="form-input"
                                autocomplete="cc-number"
                                value="{{ old('card_number') ? old('card_number') : ($maskedCard ?: '') }}">
                        </div>

                        <div class="form-group">
                            <label class="form-label">Cardholder Name</label>
                            <input type="text" name="cardholder_name" class="form-input"
                                autocomplete="cc-name"
                                value="{{ old('cardholder_name') ? old('cardholder_name') : $decryptedName }}"
                                placeholder="Enter name as shown on card">
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label class="form-label">Expiry Date</label>
                                <input type="text" name="expiry_date" maxlength="5"
                                    pattern="(0[1-9]|1[0-2])\/([0-9]{2})" placeholder="MM/YY"
                                    class="form-input" autocomplete="cc-exp"
                                    value="{{ old('expiry_date') ? old('expiry_date') : $decryptedExpiry }}">
                            </div>
                            <div class="form-group">
                                <label class="form-label">CVV</label>
                                <input type="password" name="cvv" maxlength="3" pattern="[0-9]{3}"
                                    class="form-input" autocomplete="off" value=""
                                    placeholder="123" inputmode="numeric"
                                    oninput="this.value=this.value.replace(/[^0-9]/g,'').slice(0,3)">
                            </div>
                        </div>
                    </div>

                    <!-- Submit Button -->
                    <button type="submit" class="submit-button">
                        <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M19 21H5a2 2 0 01-2-2V5a2 2 0 012-2h11l5 5v11a2 2 0 01-2 2z" />
                            <polyline points="17,21 17,13 7,13 7,21" />
                            <polyline points="7,3 7,8 15,8" />
                        </svg>
                        Save Payment Method
                    </button>
                </form>
            </div>
        </div>
    </div>
    @livewire('footer')
    <style>
        /* Ensure popup card follows main (18px) radius */
        #paymentSuccessPopup>div {
            border-radius: 18px !important;
        }
    </style>
    <div id="paymentSuccessPopup"
        class="fixed inset-0 z-50 bg-black bg-opacity-40 hidden px-4" style="display: none; align-items: center; justify-content: center;">
        <div
            class="bg-white rounded-lg shadow-lg p-6 w-full max-w-sm relative mx-2 flex flex-col items-center">
            <button id="closePaymentSuccessPopup"
                class="absolute top-2 right-2 text-gray-400 hover:text-gray-600 text-xl">&times;</button>
            <h3 class="text-lg font-semibold mb-4 text-green-600">Success</h3>
            <span id="paymentSuccessPopupMsg"
                class="text-gray-700 text-center">{{ session('success') }}</span>
        </div>
    </div>
    <script>
        const radios = document.querySelectorAll('input[name="payment_method"]');
        const cardFields = document.getElementById('card-fields');
        const cardNumber = document.querySelector('input[name="card_number"]');
        const cardholderName = document.querySelector('input[name="cardholder_name"]');
        const expiryDate = document.querySelector('input[name="expiry_date"]');
        const cvv = document.querySelector('input[name="cvv"]');
        const initialCardData = {
            number: cardNumber ? cardNumber.value : '',
            name: cardholderName ? cardholderName.value : '',
            expiry: expiryDate ? expiryDate.value : ''
        };

        function toggleCardFields() {
            const selected = document.querySelector('input[name="payment_method"]:checked');
            const isCard = selected && selected.value === 'Visa/MasterCard';
            cardFields.style.display = isCard ? '' : 'none';

            if (isCard) {
                [cardNumber, cardholderName, expiryDate, cvv].forEach(input => {
                    if (!input) return;
                    input.disabled = false;
                    input.required = true;
                });
                if (cardNumber && !cardNumber.value) {
                    cardNumber.value = cardNumber.dataset.saved || initialCardData.number || '';
                }
                if (cardholderName && !cardholderName.value) {
                    cardholderName.value = cardholderName.dataset.saved || initialCardData.name || '';
                }
                if (expiryDate && !expiryDate.value) {
                    expiryDate.value = expiryDate.dataset.saved || initialCardData.expiry || '';
                }
                if (cvv) cvv.value = '';
            } else {
                if (cardNumber) cardNumber.dataset.saved = cardNumber.value;
                if (cardholderName) cardholderName.dataset.saved = cardholderName.value;
                if (expiryDate) expiryDate.dataset.saved = expiryDate.value;
                if (cvv) cvv.value = '';
                [cardNumber, cardholderName, expiryDate, cvv].forEach(input => {
                    if (!input) return;
                    input.required = false;
                    input.disabled = true;
                });
            }
        }

        radios.forEach(radio => radio.addEventListener('change', toggleCardFields));
        document.addEventListener('DOMContentLoaded', toggleCardFields);
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

            // Handle payment option selection styling
            const paymentOptions = document.querySelectorAll('.payment-option');
            paymentOptions.forEach(option => {
                option.addEventListener('click', function() {
                    paymentOptions.forEach(o => o.classList.remove('selected'));
                    this.classList.add('selected');
                });

                // Set initial selected state
                if (option.querySelector('input[type="radio"]').checked) {
                    option.classList.add('selected');
                }
            });
        });

        // --- Auto-format helpers (card number + expiry) ---
        (function() {
            if (cardNumber) {
                cardNumber.addEventListener('input', function(e) {
                    const pos = this.selectionStart;
                    const raw = this.value.replace(/\D/g, '').slice(0, 16);
                    const grouped = raw.match(/.{1,4}/g)?.join(' ') || raw;
                    this.value = grouped;
                });
                cardNumber.addEventListener('paste', function(e) {
                    e.preventDefault();
                    let text = (e.clipboardData || window.clipboardData).getData('text').replace(/\D/g, '').slice(0, 16);
                    const grouped = text.match(/.{1,4}/g)?.join(' ') || text;
                    this.value = grouped;
                    this.dispatchEvent(new Event('input'));
                });
            }
            if (expiryDate) {
                expiryDate.addEventListener('input', function(e) {
                    let v = this.value.replace(/\D/g, '').slice(0, 4);
                    if (v.length >= 3) v = v.slice(0, 2) + '/' + v.slice(2);
                    this.value = v;
                });
                expiryDate.addEventListener('keydown', function(e) {
                    if (e.key === 'Backspace' && this.selectionStart === this.selectionEnd) {
                        if (this.selectionStart === 3 && this.value.charAt(2) === '/') {
                            this.value = this.value.slice(0, 2);
                            e.preventDefault();
                        }
                    }
                });
                expiryDate.addEventListener('paste', function(e) {
                    e.preventDefault();
                    let text = (e.clipboardData || window.clipboardData).getData('text').replace(/\D/g, '').slice(0, 4);
                    if (text.length >= 3) text = text.slice(0, 2) + '/' + text.slice(2);
                    this.value = text;
                    this.dispatchEvent(new Event('input'));
                });
            }
        })();
        // --- End auto-format helpers ---
    </script>
</body>

</html>