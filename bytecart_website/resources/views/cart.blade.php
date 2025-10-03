<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <meta name="cart-count" content="{{ isset($count) ? (int) $count : 0 }}">
    <meta name="cart-total" content="{{ isset($total) ? (float) $total : 0 }}">
    <title>ByteCart | Shopping Cart</title>
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

        .quantity-control {
            border: 1px solid #e2e8f0;
            transition: all 0.3s ease;
            background-color: #fafafa;
        }

        .quantity-control:focus-within {
            border-color: #0479FF;
            box-shadow: 0 0 0 3px rgba(4, 121, 255, 0.1);
            background-color: white;
        }

        .quantity-btn {
            transition: all 0.2s ease;
        }

        .quantity-btn:hover {
            background-color: #f1f5f9;
            color: #0479FF;
        }

        .remove-btn {
            transition: all 0.3s ease;
        }

        .remove-btn:hover {
            color: #ef4444;
            transform: scale(1.05);
        }

        input[type=number]::-webkit-inner-spin-button,
        input[type=number]::-webkit-outer-spin-button {
            -webkit-appearance: none;
            margin: 0;
        }

        input[type=number] {
            -moz-appearance: textfield;
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

        .trust-badge {
            background: #f0fdf4;
            border: 1px solid #bbf7d0;
        }
    </style>
</head>

<body class="bg-white">
    @livewire('nav-bar')

    <div class="w-full mx-auto pb-8 pt-5 px-4 sm:px-16 sm:pb-10 sm:pt-5">
        <!-- Progress Bar -->
        @if(!empty($items))
        <div class="mb-8">
            <div class="flex items-center justify-between mb-4">
                <h1 class="text-2xl sm:text-3xl font-bold text-gray-900">Shopping Cart</h1>
                <span class="text-sm text-gray-500">Step 1 of 2</span>
            </div>
            <div class="progress-bar">
                <div class="progress-fill" style="width: 50%"></div>
            </div>
            <div class="flex justify-between text-xs text-gray-500 mt-2">
                <span class="font-medium text-blue-600">Cart</span>
                <span>Checkout</span>
            </div>
        </div>
        @endif

        <!-- Alerts -->
        @if (session('status'))
        <div id="status-alert" class="mb-6 p-4 rounded-[18px] bg-emerald-50 text-emerald-700 border border-emerald-200 flex items-center">
            <div class="w-6 h-6 rounded-full bg-emerald-100 flex items-center justify-center mr-3">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                </svg>
            </div>
            <span class="font-medium">{{ session('status') }}</span>
        </div>
        @endif

        @if ($errors->any())
        <div id="error-alert" class="mb-6 p-4 rounded-[18px] bg-red-50 text-red-700 border border-red-200">
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

        @if(empty($items))
        <!-- Empty Cart State -->
        <div class="text-center py-16">
            <div class="max-w-md mx-auto">
                <div class="w-24 h-24 rounded-full bg-blue-50 flex items-center justify-center mb-6 mx-auto">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 text-blue-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z" />
                    </svg>
                </div>
                <h2 class="text-2xl font-bold text-gray-900 mb-3">Your cart is empty</h2>
                <p class="text-gray-500 mb-8 leading-relaxed">Discover our latest electronics and gadgets. Add some items to get started!</p>
                <a href="{{ url('/shop-all') }}" class="btn-primary inline-flex items-center px-8 py-3 rounded-[9px] text-white font-semibold text-lg">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
                    </svg>
                    Start Shopping
                </a>
            </div>
        </div>
        @else
        <!-- Cart Content -->
        <div class="grid grid-cols-1 xl:grid-cols-7 gap-8">
            <!-- Cart Items Section -->
            <div class="xl:col-span-5">
                <!-- Cart Items Header -->
                <div class="flex items-center justify-between mb-6">
                    <h2 class="text-xl font-bold text-gray-900">Cart Items</h2>
                    <div class="flex items-center space-x-4">
                        <span class="bg-blue-100 text-blue-800 text-sm font-medium px-3 py-1 rounded-full">
                            {{ $count }} {{ $count == 1 ? 'item' : 'items' }}
                        </span>
                        <form method="POST" action="{{ route('cart.clear') }}" class="inline">
                            @csrf
                            <button type="submit" class="text-sm text-red-600 hover:text-red-700 font-medium transition-colors">
                                Clear All
                            </button>
                        </form>
                    </div>
                </div>

                <!-- Cart Items List -->
                <div class="space-y-4 mb-8">
                    @foreach($items as $lineId => $item)
                    <div class="product-card card-elevated rounded-[18px] p-4 sm:p-6 bg-white cart-item-enter relative mb-[10px]">
                        <!-- Remove Button - Top Right Corner -->
                        <form method="POST" action="{{ route('cart.remove') }}" class="absolute top-2 right-2 z-10">
                            @csrf
                            <input type="hidden" name="line_id" value="{{ $lineId }}">
                            <button type="submit" class="remove-btn w-8 h-8 rounded-full bg-red-50 hover:bg-red-100 flex items-center justify-center text-red-500 hover:text-red-700 transition-all">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                                </svg>
                            </button>
                        </form>

                        <div class="flex flex-row items-start sm:items-center gap-3 sm:gap-4">
                            <!-- Product Image -->
                            <div class="w-16 h-16 sm:w-28 sm:h-28 bg-gray-50 rounded-[9px] flex items-center justify-center overflow-hidden flex-shrink-0">
                                @if(!empty($item['image']))
                                <img src="{{ asset($item['image']) }}" alt="{{ $item['name'] ?? 'Item' }}" class="w-full h-full object-contain p-1 sm:p-2 rounded-[4.5px]">
                                @else
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 sm:h-10 sm:w-10 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                                </svg>
                                @endif
                            </div>

                            <!-- Product Details -->
                            <div class="flex-1 min-w-0">
                                <h3 class="text-sm sm:text-base font-bold text-gray-900 mb-1 leading-tight">
                                    {{ $item['name'] ?? 'Item' }}
                                </h3>
                                <div class="space-y-1 mb-3">
                                    @if(!empty($item['model_name']))
                                    <p class="text-xs sm:text-sm text-gray-600 truncate">
                                        <span class="font-medium">Model:</span> {{ $item['model_name'] }}
                                    </p>
                                    @endif
                                    @if(!empty($item['options']['color']))
                                    <p class="text-xs sm:text-sm text-gray-600 truncate">
                                        <span class="font-medium">Color:</span> {{ $item['options']['color'] }}
                                    </p>
                                    @endif
                                </div>

                                <!-- Quantity Control -->
                                <form method="POST" action="{{ route('cart.update') }}" class="inline-block">
                                    @csrf
                                    <input type="hidden" name="line_id" value="{{ $lineId }}">
                                    <div class="flex items-center">
                                        <span class="text-xs sm:text-sm font-medium text-gray-700 mr-2">Qty:</span>
                                        <div class="flex items-center quantity-control rounded-[9px] overflow-hidden">
                                            <button type="button" class="quantity-btn w-8 h-8 sm:w-9 sm:h-9 flex items-center justify-center text-gray-600" onclick="const i=this.nextElementSibling; i.value=Math.max(1,parseInt(i.value||'1')-1); this.closest('form').submit();">
                                                <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 sm:h-4 sm:w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 12H4" />
                                                </svg>
                                            </button>
                                            <input type="number" name="qty" min="1" value="{{ (int) $item['qty'] }}" class="w-12 h-8 sm:w-14 sm:h-9 text-center border-0 focus:ring-0 text-xs sm:text-sm font-medium bg-transparent">
                                            <button type="button" class="quantity-btn w-8 h-8 sm:w-9 sm:h-9 flex items-center justify-center text-gray-600" onclick="const i=this.previousElementSibling; i.value=(parseInt(i.value||'1')+1); this.closest('form').submit();">
                                                <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 sm:h-4 sm:w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                                                </svg>
                                            </button>
                                        </div>
                                    </div>
                                    <button type="submit" class="hidden">Update</button>
                                </form>
                            </div>

                            <!-- Price Section -->
                            <div class="text-right flex-shrink-0 mt-8">
                                <div class="space-y-1">
                                    <p class="text-xs text-gray-500">Unit Price</p>
                                    <p class="text-sm sm:text-base font-semibold text-gray-900">${{ number_format((float) $item['price'], 2) }}</p>
                                    <div class="border-t border-gray-200 pt-2 mt-2">
                                        <p class="text-xs text-gray-500">Subtotal</p>
                                        <p class="text-lg sm:text-xl font-bold text-gray-900">
                                            ${{ number_format((float) $item['price'] * (int) $item['qty'], 2) }}
                                        </p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    @endforeach
                </div>

                <!-- Continue Shopping -->
                <div class="border-t border-gray-200 pt-6">
                    <a href="{{ url('/shop-all') }}" class="inline-flex items-center text-blue-600 hover:text-blue-700 font-medium transition-colors">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
                        </svg>
                        Continue Shopping
                    </a>
                </div>
            </div>

            <!-- Order Summary Sidebar -->
            <div class="xl:col-span-2">
                <div class="summary-card card-elevated p-6 sticky top-6 rounded-[18px]">
                    <h2 class="text-xl font-bold text-gray-900 mb-6 flex items-center">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
                        </svg>
                        Order Summary
                    </h2>

                    <!-- Summary Details -->
                    <div class="space-y-2 mb-6">
                        <div class="flex justify-between items-center py-1">
                            <span class="text-gray-600">Subtotal ({{ $count }} items)</span>
                            <span class="font-semibold text-gray-900">${{ number_format($total, 2) }}</span>
                        </div>
                        <div class="flex justify-between items-center py-1">
                            <span class="text-gray-600">Shipping</span>
                            <span class="font-semibold text-gray-900">$5.00</span>
                        </div>
                        <div class="flex justify-between items-center py-1">
                            <span class="text-gray-600">Tax (estimated)</span>
                            <span class="font-semibold text-gray-900">${{ number_format($total * 0.05, 2) }}</span>
                        </div>

                        <!-- Promo Code -->
                        <div class="border-t border-gray-200 pt-4">
                            <form method="POST" action="" class="space-y-3" onsubmit="return false">
                                @csrf
                                <div class="relative">
                                    <input type="text" placeholder="Enter promo code" class="w-full px-4 py-3 border border-gray-300 rounded-[9px] text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                                    <button type="submit" class="absolute right-2 top-1/2 transform -translate-y-1/2 px-4 py-1 bg-blue-600 text-white rounded-[4.5px] text-sm font-medium hover:bg-blue-700">
                                        Apply
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>

                    <!-- Total -->
                    <div class="border-t border-gray-200 pt-4 mb-6">
                        <div class="flex justify-between items-center">
                            <span class="text-lg font-bold text-gray-900">Total</span>
                            <span class="text-2xl font-bold text-gray-900">${{ number_format($total + 5 + ($total * 0.05), 2) }}</span>
                        </div>
                    </div>

                    <!-- Checkout Button -->
                    <a href="{{ route('checkout.show') }}" class="w-full btn-primary text-white px-4 py-3 rounded-[9px] font-bold text-lg flex items-center justify-center mb-4">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                        </svg>
                        Secure Checkout
                    </a>

                    <!-- Trust Signals -->
                    <div class="trust-badge rounded-[9px] p-3 mb-4 text-center">
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
        @endif
    </div>

    @livewire('footer')

    <script>
        // Keep navbar cart total in sync after page loads
        (function() {
            const mc = document.querySelector('meta[name="cart-count"]');
            const mt = document.querySelector('meta[name="cart-total"]');
            const count = mc ? parseInt(mc.content || '0', 10) : 0;
            const total = mt ? parseFloat(mt.content || '0') : 0;
            if (window.Livewire && window.Livewire.dispatch) {
                window.Livewire.dispatch('cart-updated', {
                    count,
                    total
                });
            }

            // DRY alert auto-dismiss (same timing and effects as before)
            function dismissAfter(el, delay = 5000) {
                if (!el) return;
                setTimeout(() => {
                    el.style.transition = 'opacity 0.5s ease';
                    el.style.opacity = '0';
                    setTimeout(() => {
                        el.style.display = 'none';
                    }, 500);
                }, delay);
            }
            dismissAfter(document.getElementById('status-alert'));
            dismissAfter(document.getElementById('error-alert'));
        })();
    </script>
</body>

</html>