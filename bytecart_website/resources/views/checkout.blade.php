<!DOCTYPE html>
<!-- Orders are stored in MongoDB (connection: mongodb_orders). -->
<html lang="en">
@php
// Prepare masked card + decrypted ancillary fields (needed by Blade below)
$maskedCard = '';
$decryptedName = '';
$decryptedExpiry = '';
if (!empty($user->card_number)) {
try {
$plain = decrypt($user->card_number);
$digitsOnly = preg_replace('/\D/', '', $plain);
$maskedCard = preg_replace('/\d(?=\d{4})/', '*', $digitsOnly);
if (strlen($maskedCard) === 16) {
$maskedCard = trim(chunk_split($maskedCard, 4, ' '));
} elseif ($maskedCard !== '') {
// group generically in blocks of 4 for other lengths (13–19)
$maskedCard = trim(implode(' ', str_split($maskedCard, 4)));
}
} catch (\Throwable $e) {
$maskedCard = '';
}
}
if (!empty($user->cardholder_name)) {
try { $decryptedName = decrypt($user->cardholder_name); } catch (\Throwable $e) {}
}
if (!empty($user->expiry_date)) {
try { $decryptedExpiry = decrypt($user->expiry_date); } catch (\Throwable $e) {}
}
// CVV intentionally never exposed
@endphp

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>ByteCart | Checkout</title>
    <link rel="icon" type="image/x-icon" href="{{ asset('logo/x-icon.webp') }}">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <style>
        .card-elevated {
            box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);
        }

        .btn-primary {
            background-color: #0479FF;
            transition: all 0.3s ease;
        }

        .btn-primary:hover {
            background-color: #0360d0;
            transform: translateY(-1px);
            box-shadow: 0 4px 12px rgba(4, 121, 255, 0.4);
        }

        .input {
            border: 1px solid #e5e7eb;
            border-radius: 9px;
            padding: 12px;
            width: 100%;
            transition: all 0.3s ease;
            font-size: 14px;
        }

        .input:focus {
            outline: none;
            border-color: #0479FF;
            box-shadow: 0 0 0 3px rgba(4, 121, 255, 0.1);
        }

        .section-title {
            font-weight: 700;
            font-size: 1.25rem;
            margin-bottom: 1rem;
            color: #1f2937;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .form-label {
            color: #6b7280;
            font-size: 14px;
            font-weight: 500;
            margin-bottom: 6px;
            display: block;
        }

        .checkbox-label {
            display: flex;
            align-items: center;
            gap: 8px;
            color: #374151;
            font-size: 14px;
            cursor: pointer;
        }

        .radio-label {
            display: flex;
            align-items: center;
            gap: 8px;
            color: #374151;
            font-size: 14px;
            cursor: pointer;
            padding: 12px;
            border: 1px solid #e5e7eb;
            border-radius: 9px;
            transition: all 0.3s ease;
        }

        .radio-label:hover {
            border-color: #0479FF;
            background-color: #f8faff;
        }

        .radio-label input:checked {
            accent-color: #0479FF;
        }

        .progress-bar {
            background-color: #f3f4f6;
            height: 4px;
            border-radius: 9px;
            overflow: hidden;
        }

        .progress-fill {
            background-color: #0479FF;
            height: 100%;
            transition: width 0.3s ease;
            border-radius: 9px;
        }

        .summary-card {
            background: #ffffff;
        }

        .trust-badge {
            background: #f0fdf4;
            border: 1px solid #bbf7d0;
        }

        .hidden {
            display: none;
        }

        .alert-success {
            background-color: #f0fdf4;
            border: 1px solid #bbf7d0;
            color: #166534;
        }

        .alert-error {
            background-color: #fef2f2;
            border: 1px solid #fecaca;
            color: #dc2626;
        }

        .order-item {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 16px 0;
            border-bottom: 1px solid #f3f4f6;
        }

        .order-item:last-child {
            border-bottom: none;
        }

        .item-image {
            width: 64px;
            height: 64px;
            background: #f9fafb;
            border-radius: 9px;
            display: flex;
            align-items: center;
            justify-content: center;
            overflow: hidden;
            flex-shrink: 0;
        }

        .item-details {
            flex: 1;
            min-width: 0;
        }

        .item-name {
            font-weight: 600;
            font-size: 14px;
            color: #1f2937;
            margin-bottom: 4px;
        }

        .item-meta {
            color: #6b7280;
            font-size: 12px;
            margin-bottom: 2px;
        }

        .item-price {
            font-weight: 700;
            color: #1f2937;
            font-size: 14px;
        }

        @media (max-width: 1023px) {
            .lg-grid-2 {
                grid-template-columns: 1fr;
            }
        }

        @media (min-width: 1024px) {
            .lg-grid-2 {
                grid-template-columns: repeat(2, 1fr);
            }
        }
    </style>
</head>

<body class="bg-white">
    @livewire('nav-bar')

    <div class="w-full mx-auto pb-8 pt-5 px-4 sm:px-16 sm:pb-10 sm:pt-5">
        <!-- Progress Bar -->
        <div class="mb-8">
            <div class="flex items-center justify-between mb-4">
                <h1 class="text-2xl sm:text-3xl font-bold text-gray-900">Checkout</h1>
                <span class="text-sm text-gray-500">Step 2 of 2</span>
            </div>
            <div class="progress-bar">
                <div class="progress-fill" style="width: 100%"></div>
            </div>
            <div class="flex justify-between text-xs text-gray-500 mt-2">
                <span>Cart</span>
                <span class="font-medium text-blue-600">Checkout</span>
            </div>
        </div>

        <!-- Alerts -->
        @if (session('status'))
        <div id="status-alert" class="mb-6 p-4 rounded-[18px] alert-success flex items-center">
            <div class="w-6 h-6 rounded-full bg-green-100 flex items-center justify-center mr-3">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                </svg>
            </div>
            <span class="font-medium">{{ session('status') }}</span>
        </div>
        @endif

        @if ($errors->any())
        <div id="error-alert" class="mb-6 p-4 rounded-[18px] alert-error">
            <div class="flex items-center mb-3">
                <div class="w-6 h-6 rounded-full bg-red-100 flex items-center justify-center mr-3">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                        <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
                    </svg>
                </div>
                <span class="font-semibold">Please fix the following errors:</span>
            </div>
            <ul class="space-y-1 ml-9">
                @foreach ($errors->all() as $error)
                <li class="text-sm">• {{ $error }}</li>
                @endforeach
            </ul>
        </div>
        @endif

        <!-- Main Content -->
        <div class="grid grid-cols-1 xl:grid-cols-7 gap-8">
            <!-- Checkout Form -->
            <div class="xl:col-span-5">
                <form method="POST" action="{{ route('checkout.place') }}" id="checkout-form">
                    @csrf

                    <!-- Contact Information -->
                    <div class="card-elevated bg-white p-6 rounded-[18px] mb-6">
                        <h2 class="section-title">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                            </svg>
                            Contact Information
                        </h2>
                        <div class="grid lg-grid-2 gap-4">
                            <div>
                                <label class="form-label">Phone Number *</label>
                                <input class="input" id="phone_number" name="phone_number" required
                                    pattern="[0-9 ]{10,13}" minlength="10" maxlength="13" inputmode="numeric"
                                    title="Enter 10 digits (0-9). Spaces allowed."
                                    oninput="
                                        let digits=this.value.replace(/\D/g,'').slice(0,10);
                                        let f=digits;
                                        if(digits.length>6){f=digits.replace(/(\d{3})(\d{3})(\d{1,4})/,'$1 $2 $3');}
                                        else if(digits.length>3){f=digits.replace(/(\d{3})(\d{1,3})/,'$1 $2');}
                                        this.value=f;
                                    "
                                    value="{{ old('phone_number', $user->phone_number) }}">
                            </div>
                        </div>
                    </div>

                    <!-- Shipping Address -->
                    <div class="card-elevated bg-white p-6 rounded-[18px] mb-6">
                        <h2 class="section-title">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                            </svg>
                            Shipping Address
                        </h2>
                        <div class="grid lg-grid-2 gap-4">
                            <div>
                                <label class="form-label">Street Address *</label>
                                <input class="input" id="shipping_street_address" name="shipping_street_address" required value="{{ old('shipping_street_address', $user->shipping_street_address) }}">
                            </div>
                            <div>
                                <label class="form-label">Apartment/Suite</label>
                                <input class="input" id="shipping_apartment_suite" name="shipping_apartment_suite" value="{{ old('shipping_apartment_suite', $user->shipping_apartment_suite) }}">
                            </div>
                            <div>
                                <label class="form-label">City *</label>
                                <input class="input" id="shipping_city" name="shipping_city" required value="{{ old('shipping_city', $user->shipping_city) }}">
                            </div>
                            <div>
                                <label class="form-label">District *</label>
                                <input class="input" id="shipping_district" name="shipping_district" required value="{{ old('shipping_district', $user->shipping_district) }}">
                            </div>
                            <div>
                                <label class="form-label">ZIP/Postal Code *</label>
                                <input class="input" id="shipping_zip_code" name="shipping_zip_code" required
                                    pattern="[0-9]{5}" minlength="5" maxlength="5" inputmode="numeric"
                                    title="Enter exactly 5 digits (0-9)"
                                    oninput="this.value=this.value.replace(/[^0-9]/g,'').slice(0,5)"
                                    value="{{ old('shipping_zip_code', $user->shipping_zip_code) }}">
                            </div>
                        </div>

                        <div class="mt-4 pt-4 border-t border-gray-200">
                            <label class="checkbox-label">
                                <input type="checkbox" id="is_billing_same_as_shipping" name="is_billing_same_as_shipping" value="1"
                                    {{ old('is_billing_same_as_shipping', $user->is_billing_same_as_shipping ? '1' : '') ? 'checked' : '' }}
                                    onchange="toggleBilling(this)">
                                <span>Billing same as shipping</span>
                            </label>
                        </div>
                    </div>

                    <!-- Billing Address -->
                    <div id="billing-section" class="{{ old('is_billing_same_as_shipping', $user->is_billing_same_as_shipping ? '1' : '') ? 'hidden' : '' }}">
                        <div class="card-elevated bg-white p-6 rounded-[18px] mb-6">
                            <h2 class="section-title">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                                </svg>
                                Billing Address
                            </h2>
                            <div class="grid lg-grid-2 gap-4">
                                <div>
                                    <label class="form-label">Street Address *</label>
                                    <input class="input" id="billing_street_address" name="billing_street_address" required value="{{ old('billing_street_address', $user->billing_street_address) }}">
                                </div>
                                <div>
                                    <label class="form-label">Apartment/Suite</label>
                                    <input class="input" id="billing_apartment_suite" name="billing_apartment_suite" value="{{ old('billing_apartment_suite', $user->billing_apartment_suite) }}">
                                </div>
                                <div>
                                    <label class="form-label">City *</label>
                                    <input class="input" id="billing_city" name="billing_city" required value="{{ old('billing_city', $user->billing_city) }}">
                                </div>
                                <div>
                                    <label class="form-label">District *</label>
                                    <input class="input" id="billing_district" name="billing_district" required value="{{ old('billing_district', $user->billing_district) }}">
                                </div>
                                <div>
                                    <label class="form-label">ZIP/Postal Code *</label>
                                    <input class="input" id="billing_zip_code" name="billing_zip_code" required
                                        pattern="[0-9]{5}" minlength="5" maxlength="5" inputmode="numeric"
                                        title="Enter exactly 5 digits (0-9)"
                                        oninput="this.value=this.value.replace(/[^0-9]/g,'').slice(0,5)"
                                        value="{{ old('billing_zip_code', $user->billing_zip_code) }}">
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Payment Method -->
                    <div class="card-elevated bg-white p-6 rounded-[18px] mb-6">
                        <h2 class="section-title">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
                            </svg>
                            Payment Method
                        </h2>
                        <div class="space-y-3">
                            <label class="radio-label">
                                <input type="radio" name="payment_method" value="Visa/MasterCard"
                                    {{ old('payment_method', $user->payment_method) === 'Visa/MasterCard' ? 'checked' : '' }}
                                    onchange="toggleCardFields(true)" required>
                                <div class="flex items-center gap-2">
                                    <img src="{{ asset('icons/visa.webp') }}" alt="Visa" class="h-5 object-contain">
                                    <img src="{{ asset('icons/mastercard.webp') }}" alt="Mastercard" class="h-5 object-contain">
                                    <span>Visa / MasterCard</span>
                                </div>
                            </label>

                            <div id="card-fields" class="{{ old('payment_method', $user->payment_method) === 'Visa/MasterCard' ? '' : 'hidden' }} p-4 bg-gray-50 rounded-[9px]">
                                <div class="grid lg-grid-2 gap-4">
                                    <div>
                                        <label class="form-label">Card Number *</label>
                                        <input class="input" name="card_number" maxlength="23"
                                            pattern="[0-9* ]{12,23}" title="Enter 12-19 digits (spaces allowed). Masked accepted."
                                            placeholder="#### #### #### ####"
                                            value="{{ old('card_number') ? old('card_number') : ($maskedCard ?: '') }}">
                                    </div>
                                    <div>
                                        <label class="form-label">Cardholder Name *</label>
                                        <input class="input" name="cardholder_name"
                                            value="{{ old('cardholder_name') ? old('cardholder_name') : $decryptedName }}">
                                    </div>
                                    <div>
                                        <label class="form-label">Expiry (MM/YY) *</label>
                                        <input class="input" name="expiry_date" maxlength="5" pattern="(0[1-9]|1[0-2])\/([0-9]{2})" placeholder="MM/YY"
                                            value="{{ old('expiry_date') ? old('expiry_date') : $decryptedExpiry }}">
                                    </div>
                                    <div>
                                        <label class="form-label">CVV *</label>
                                        <input class="input" name="cvv" maxlength="4" pattern="[0-9]{3,4}" placeholder="123" value="" autocomplete="off"
                                            inputmode="numeric"
                                            oninput="this.value=this.value.replace(/[^0-9]/g,'').slice(0,4)">
                                    </div>
                                </div>
                            </div>

                            <label class="radio-label">
                                <input type="radio" name="payment_method" value="Koko"
                                    {{ old('payment_method', $user->payment_method) === 'Koko' ? 'checked' : '' }}
                                    onchange="toggleCardFields(false)">
                                <div class="flex items-center gap-2">
                                    <img src="{{ asset('icons/koko.webp') }}" alt="Koko" class="h-5 object-contain">
                                    <span>Koko</span>
                                </div>
                            </label>

                            <label class="radio-label">
                                <input type="radio" name="payment_method" value="Mintpay"
                                    {{ old('payment_method', $user->payment_method) === 'Mintpay' ? 'checked' : '' }}
                                    onchange="toggleCardFields(false)">
                                <div class="flex items-center gap-2">
                                    <img src="{{ asset('icons/mintpay.webp') }}" alt="MintPay" class="h-5 object-contain">
                                    <span>Mintpay</span>
                                </div>
                            </label>

                            <label class="radio-label">
                                <input type="radio" name="payment_method" value="COD"
                                    {{ old('payment_method', $user->payment_method) === 'COD' ? 'checked' : '' }}
                                    onchange="toggleCardFields(false)">
                                <div class="flex items-center gap-2">
                                    <img src="{{ asset('icons/cod.webp') }}" alt="Cash on Delivery" class="h-5 object-contain">
                                    <span>Cash on Delivery</span>
                                </div>
                            </label>
                        </div>
                    </div>

                    <!-- Order Notes -->
                    <div class="card-elevated bg-white p-6 rounded-[18px] mb-6">
                        <h2 class="section-title">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                            </svg>
                            Order Notes (Optional)
                        </h2>
                        <textarea class="input" name="notes" rows="3" placeholder="Add any special instructions for your order...">{{ old('notes') }}</textarea>
                    </div>

                    <!-- Back to Cart -->
                    <div class="border-t border-gray-200 pt-6">
                        <a href="{{ route('cart') }}" class="inline-flex items-center text-blue-600 hover:text-blue-700 font-medium transition-colors">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
                            </svg>
                            Back to Cart
                        </a>
                    </div>
                </form>
            </div>

            <!-- Order Summary Sidebar -->
            <div class="xl:col-span-2">
                <div class="summary-card card-elevated p-6 sticky top-6 rounded-[18px]">
                    <h2 class="text-xl font-bold text-gray-900 mb-4 flex items-center">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
                        </svg>
                        Order Summary
                    </h2>

                    <!-- Order Items -->
                    <div class="mb-6">
                        @foreach($items as $lineId => $item)
                        <div class="order-item">
                            <div class="item-image">
                                @if(!empty($item['image']))
                                <img src="{{ asset($item['image']) }}" alt="Item" class="w-full h-full object-contain p-1">
                                @else
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                                </svg>
                                @endif
                            </div>
                            <div class="item-details">
                                <div class="item-name">{{ $item['name'] ?? 'Item' }}</div>
                                @if(!empty($item['model_name']) || !empty($item['options']['color']))
                                <div class="item-meta">
                                    @if(!empty($item['model_name'])) Model: {{ $item['model_name'] }} @endif
                                    @if(!empty($item['model_name']) && !empty($item['options']['color'])) | @endif
                                    @if(!empty($item['options']['color'])) Color: {{ $item['options']['color'] }} @endif
                                </div>
                                @endif
                                <div class="item-meta">Qty: {{ (int) $item['qty'] }}</div>
                            </div>
                            <div class="item-price">
                                ${{ number_format((float) $item['price'] * (int) $item['qty'], 2) }}
                            </div>
                        </div>
                        @endforeach
                    </div>

                    <!-- Summary Totals -->
                    <div class="space-y-3 mb-6">
                        <div class="flex justify-between items-center">
                            <span class="text-gray-600">Subtotal</span>
                            <span class="font-semibold">${{ number_format($subtotal, 2) }}</span>
                        </div>
                        <div class="flex justify-between items-center">
                            <span class="text-gray-600">Shipping</span>
                            <span class="font-semibold">$5.00</span>
                        </div>
                        <div class="flex justify-between items-center">
                            <span class="text-gray-600">Tax (5%)</span>
                            <span class="font-semibold">${{ number_format($tax, 2) }}</span>
                        </div>
                        <div class="border-t border-gray-200 pt-3">
                            <div class="flex justify-between items-center">
                                <span class="text-lg font-bold text-gray-900">Total</span>
                                <span class="text-2xl font-bold text-gray-900">${{ number_format($total, 2) }}</span>
                            </div>
                        </div>
                    </div>

                    <!-- Place Order Button -->
                    <button
                        type="button"
                        onclick="(document.getElementById('checkout-form')?.requestSubmit?.() || document.getElementById('checkout-form')?.submit?.())"
                        class="w-full btn-primary text-white px-4 py-3 rounded-[9px] font-bold text-lg flex items-center justify-center mb-4">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                        </svg>
                        Place Order
                    </button>

                    <!-- Trust Signals -->
                    <div class="trust-badge rounded-[9px] p-3 text-center mb-4">
                        <div class="flex items-center justify-center text-sm text-green-700 font-medium">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                            </svg>
                            256-bit SSL Encrypted
                        </div>
                    </div>

                    <!-- Payment Methods -->
                    <div class="text-center">
                        <p class="text-sm text-gray-600 mb-3 font-medium">Accepted Payment Methods</p>
                        <div class="grid grid-cols-3 gap-2">
                            <div class="bg-white border border-gray-200 rounded-[9px] p-2 flex items-center justify-center h-12">
                                <img src="{{ asset('icons/visa.webp') }}" alt="Visa" class="h-6 object-contain">
                            </div>
                            <div class="bg-white border border-gray-200 rounded-[9px] p-2 flex items-center justify-center h-12">
                                <img src="{{ asset('icons/mastercard.webp') }}" alt="Mastercard" class="h-6 object-contain">
                            </div>
                            <div class="bg-white border border-gray-200 rounded-[9px] p-2 flex items-center justify-center h-12">
                                <img src="{{ asset('icons/koko.webp') }}" alt="Koko" class="h-6 object-contain">
                            </div>
                            <div class="bg-white border border-gray-200 rounded-[9px] p-2 flex items-center justify-center h-12">
                                <img src="{{ asset('icons/mintpay.webp') }}" alt="MintPay" class="h-6 object-contain">
                            </div>
                            <div class="bg-white border border-gray-200 rounded-[9px] p-2 flex items-center justify-center h-12 col-span-2">
                                <img src="{{ asset('icons/cod.webp') }}" alt="Cash on Delivery" class="h-6 object-contain">
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    @livewire('footer')

    <script>
        // Billing sync like shipping-info page
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

        function toggleBilling(cb) {
            const s = document.getElementById('billing-section');
            s.classList.toggle('hidden', cb.checked);
            syncBillingFields(cb.checked);
        }

        // Card field toggling like payment-methods page
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

        function toggleCardFields(show) {
            cardFields.classList.toggle('hidden', !show);
            if (show) {
                [cardNumber, cardholderName, expiryDate, cvv].forEach(i => {
                    if (!i) return;
                    i.disabled = false;
                    i.required = true;
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
                if (cvv) cvv.value = ''; // never restore CVV
            } else {
                if (cardNumber) cardNumber.dataset.saved = cardNumber.value;
                if (cardholderName) cardholderName.dataset.saved = cardholderName.value;
                if (expiryDate) expiryDate.dataset.saved = expiryDate.value;
                if (cvv) cvv.value = '';
                [cardNumber, cardholderName, expiryDate, cvv].forEach(i => {
                    if (!i) return;
                    i.required = false;
                    i.disabled = true;
                });
            }
        }

        document.addEventListener('DOMContentLoaded', function() {
            const billingCheckbox = document.getElementById('is_billing_same_as_shipping');
            // Initialize billing sync
            if (billingCheckbox) {
                syncBillingFields(billingCheckbox.checked);
                for (let i = 0; i < shippingFieldIds.length; i++) {
                    const shippingInput = document.getElementById(shippingFieldIds[i]);
                    if (shippingInput) {
                        shippingInput.addEventListener('input', function() {
                            if (billingCheckbox.checked) syncBillingFields(true);
                        });
                    }
                }
            }
            // Initialize card fields required state
            const selected = document.querySelector('input[name="payment_method"]:checked');
            toggleCardFields(selected && selected.value === 'Visa/MasterCard');
            document.querySelectorAll('input[name="payment_method"]').forEach(r => {
                r.addEventListener('change', e => {
                    toggleCardFields(e.target.value === 'Visa/MasterCard');
                });
            });
        });

        // --- Auto-format helpers (card number + expiry) ---
        (function() {
            if (cardNumber) {
                cardNumber.addEventListener('input', function() {
                    const raw = this.value.replace(/\D/g, '').slice(0, 16);
                    this.value = raw.match(/.{1,4}/g)?.join(' ') || raw;
                });
                cardNumber.addEventListener('paste', function(e) {
                    e.preventDefault();
                    let text = (e.clipboardData || window.clipboardData).getData('text').replace(/\D/g, '').slice(0, 16);
                    this.value = text.match(/.{1,4}/g)?.join(' ') || text;
                    this.dispatchEvent(new Event('input'));
                });
            }
            if (expiryDate) {
                expiryDate.addEventListener('input', function() {
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