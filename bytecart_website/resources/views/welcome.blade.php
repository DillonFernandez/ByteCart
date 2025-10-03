<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <link rel="icon" type="image/x-icon" href="{{ asset('logo/x-icon.webp') }}">
    <title>ByteCart | Home</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <style>
        #new-products-container,
        #discount-products-container,
        #brands-container {
            scrollbar-width: none;
            -ms-overflow-style: none;
        }

        #new-products-container::-webkit-scrollbar,
        #discount-products-container::-webkit-scrollbar,
        #brands-container::-webkit-scrollbar {
            display: none;
        }

        #brands-container {
            will-change: transform;
        }
    </style>
</head>

<body>
    @livewire('nav-bar')
    <div class="w-full mx-auto pb-8 pt-5 px-4 sm:px-16 sm:pb-10 sm:pt-5">
        <!-- Banner Section: Main Homepage Banners -->
        <section class="w-full flex justify-center">
            <div class="space-y-3">
                <div class="rounded-1xl overflow-hidden relative h-30 sm:h-45">
                    <img src="{{ asset('banners/1.webp') }}" alt="DJI Camera Drones" class="w-full h-full">
                </div>
                <div class="flex flex-col sm:flex-row gap-3">
                    <div class="basis-full sm:basis-1/2 lg:basis-[65%] rounded-1xl flex items-center justify-center px-0 py-0 overflow-hidden h-36 sm:h-40">
                        <img src="{{ asset('banners/2.webp') }}" alt="Smart Watches" class="w-full h-full">
                    </div>
                    <div class="basis-full sm:basis-1/2 lg:basis-[35%] rounded-1xl flex items-center justify-center px-0 py-0 overflow-hidden h-36 sm:h-40">
                        <img src="{{ asset('banners/3.webp') }}" alt="Buy Now Pay Later" class="w-full h-full">
                    </div>
                </div>
                <div class="rounded-1xl flex flex-col items-center justify-center py-0 px-0 relative overflow-hidden h-35 sm:h-48">
                    <img src="{{ asset('banners/4.webp') }}" alt="Installment Plan" class="w-full h-full">
                </div>
            </div>
        </section>

        <!-- Featured Categories Section -->
        <section class="mt-14">
            <h2 class="text-2xl font-bold mb-6 text-center sm:text-left">Featured Categories</h2>
            <div class="grid grid-cols-2 sm:grid-cols-4 gap-6">
                @foreach(\App\Models\Products::pluck('product_category')->unique()->sort() as $cat)
                <div class="flex flex-col items-center bg-blue-50 rounded-[18px] p-6">
                    <span class="font-semibold text-lg text-center">{{ $cat }}</span>
                </div>
                @endforeach
            </div>
        </section>

        <!-- Best Sellers Section (moved here) -->
        @php
        // Safely attempt Mongo best-sellers. Fallback to empty if connection/driver isn't available.
        $topRows = collect();
        $bestSellerProducts = collect();

        try {
        // Ensure mongodb_orders configured (same as dashboard)
        if (!config('database.connections.mongodb_orders')) {
        config()->set('database.connections.mongodb_orders', [
        'driver' => 'mongodb',
        'dsn' => env('MONGODB_ORDERS_DSN'),
        'host' => env('MONGODB_ORDERS_HOST', '127.0.0.1'),
        'port' => env('MONGODB_ORDERS_PORT', 27017),
        'database' => env('MONGODB_ORDERS_DATABASE', 'bytecart_orders'),
        'username' => env('MONGODB_ORDERS_USERNAME', ''),
        'password' => env('MONGODB_ORDERS_PASSWORD', ''),
        'options' => [
        'database' => env('MONGODB_ORDERS_AUTH_DATABASE', 'admin'),
        'ssl' => env('MONGODB_ORDERS_SSL', false),
        ],
        ]);
        }
        $mongo = \Illuminate\Support\Facades\DB::connection('mongodb_orders');

        // Safe getter (array/stdClass)
        $get = function ($row, $key) {
        return is_array($row) ? ($row[$key] ?? null) : (is_object($row) ? ($row->$key ?? null) : null);
        };

        $from30 = \Carbon\Carbon::today()->copy()->subDays(29)->startOfDay();
        $toNow = \Carbon\Carbon::now();
        $valid = ['processed','shipped','out for delivery','delivered'];

        // 1) Preferred: aggregate by order_number (matches order_items schema)
        $orderDocs = $mongo->table('orders')
        ->whereIn('order_status', $valid)
        ->whereBetween('placed_at', [$from30, $toNow])
        ->get(['order_number']);

        $orderNumbers = collect($orderDocs)
        ->map(fn($o) => (string) $get($o, 'order_number'))
        ->filter()->unique()->values()->all();

        $topProductsAgg = [];

        if (!empty($orderNumbers)) {
        $items = $mongo->table('order_items')
        ->whereIn('order_number', $orderNumbers)
        ->get(['product_id','product_name','qty']);

        foreach ($items as $r) {
        $pid = (string) ($get($r, 'product_id') ?? '');
        if ($pid === '') continue;
        $pname = (string) ($get($r, 'product_name') ?? 'Unknown');
        $q = (int) ($get($r, 'qty') ?? 0);
        $topProductsAgg[$pid] = $topProductsAgg[$pid] ?? ['product_id' => $pid, 'product_name' => $pname, 'qty' => 0];
        $topProductsAgg[$pid]['qty'] += $q;
        }
        }

        // 2) Fallback: aggregate order_items in last 30 days by created_at
        if (empty($topProductsAgg)) {
        $items2 = $mongo->table('order_items')
        ->whereBetween('created_at', [$from30, $toNow])
        ->get(['product_id','product_name','qty']);

        foreach ($items2 as $r) {
        $pid = (string) ($get($r, 'product_id') ?? '');
        if ($pid === '') continue;
        $pname = (string) ($get($r, 'product_name') ?? 'Unknown');
        $q = (int) ($get($r, 'qty') ?? 0);
        $topProductsAgg[$pid] = $topProductsAgg[$pid] ?? ['product_id' => $pid, 'product_name' => $pname, 'qty' => 0];
        $topProductsAgg[$pid]['qty'] += $q;
        }
        }

        // 3) Fallback: widen to last 90 days if still empty
        if (empty($topProductsAgg)) {
        $from90 = \Carbon\Carbon::today()->copy()->subDays(89)->startOfDay();
        $items3 = $mongo->table('order_items')
        ->whereBetween('created_at', [$from90, $toNow])
        ->get(['product_id','product_name','qty']);

        foreach ($items3 as $r) {
        $pid = (string) ($get($r, 'product_id') ?? '');
        if ($pid === '') continue;
        $pname = (string) ($get($r, 'product_name') ?? 'Unknown');
        $q = (int) ($get($r, 'qty') ?? 0);
        $topProductsAgg[$pid] = $topProductsAgg[$pid] ?? ['product_id' => $pid, 'product_name' => $pname, 'qty' => 0];
        $topProductsAgg[$pid]['qty'] += $q;
        }
        }

        // Build rows and fetch products by integer IDs
        $topRows = collect($topProductsAgg)->values()
        ->sortByDesc('qty')->take(5)->map(fn($v) => (object)$v)->values();

        $bestSellerIds = $topRows->pluck('product_id')->map(fn($v) => (int)$v)->filter()->values();

        $bestSellerProducts = $bestSellerIds->isNotEmpty()
        ? \App\Models\Products::with('models')->whereIn('id', $bestSellerIds)->get()->keyBy('id')
        : collect();
        } catch (\Throwable $e) {
        // leave $topRows empty so the UI shows "No sales data yet."
        }
        @endphp

        <section class="mt-14">
            <h2 class="text-2xl font-bold mb-6 text-center sm:text-left">Best Sellers</h2>
            <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-6">
                @forelse($topRows as $row)
                @php
                // Lookup via integer key to avoid string/int key mismatch
                $p = $bestSellerProducts->get((int)($row->product_id ?? 0));
                @endphp
                @if($p)
                @include('livewire.product-card', ['product' => $p])
                @endif
                @empty
                <div class="col-span-2 sm:col-span-3 lg:col-span-5 text-center text-gray-500">
                    No sales data yet.
                </div>
                @endforelse
            </div>
        </section>

        <!-- Discount Products Section -->
        @php
        $discountProducts = \App\Models\Products::with('models')->where('discount', '>', 0)->take(5)->get();
        @endphp
        <section class="mt-14">
            <h2 class="text-2xl font-bold mb-6 text-center sm:text-left">Discount Products</h2>
            <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-6">
                @foreach($discountProducts as $product)
                @include('livewire.product-card', ['product' => $product])
                @endforeach
            </div>
            <div class="flex justify-center mt-6">
                <a href="{{ route('shop-all', ['discounted' => 1]) }}" class="px-6 py-2 bg-blue-500 text-white rounded-[18px] font-semibold hover:bg-blue-600 transition">View All Discount Products</a>
            </div>
        </section>
        <!-- New Products Section -->
        @php
        $newProducts = \App\Models\Products::with('models')->where('new_stock', true)->take(5)->get();
        @endphp
        <section class="mt-14">
            <h2 class="text-2xl font-bold mb-6 text-center sm:text-left">New Products</h2>
            <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-6">
                @foreach($newProducts as $product)
                @include('livewire.product-card', ['product' => $product])
                @endforeach
            </div>
            <div class="flex justify-center mt-6">
                <a href="{{ route('shop-all', ['new_stock' => 1]) }}" class="px-6 py-2 bg-blue-500 text-white rounded-[18px] font-semibold hover:bg-blue-600 transition">View All New Products</a>
            </div>
        </section>

        <!-- Brands Section: Horizontally Scrollable List of Brand Logos -->
        <section class="mt-14">
            <h2 class="text-2xl font-bold mb-6 text-center sm:text-left">Our Top Brands</h2>
            <div class="relative">
                <div id="brands-container" class="flex space-x-4 sm:space-x-8 lg:space-x-16 overflow-x-auto pr-2 scroll-smooth">
                    <div class="flex-shrink-0 w-24 h-24 sm:w-40 sm:h-40 rounded-lg flex items-center justify-center">
                        <img src="{{ asset('brands/amazon.webp') }}" alt="Amazon" class="h-full object-contain p-2 sm:p-4">
                    </div>
                    <div class="flex-shrink-0 w-24 h-24 sm:w-40 sm:h-40 rounded-lg flex items-center justify-center">
                        <img src="{{ asset('brands/apple.webp') }}" alt="Apple" class="h-full object-contain p-2 sm:p-4">
                    </div>
                    <div class="flex-shrink-0 w-24 h-24 sm:w-40 sm:h-40 rounded-lg flex items-center justify-center">
                        <img src="{{ asset('brands/canon.webp') }}" alt="Canon" class="h-full object-contain p-2 sm:p-4">
                    </div>
                    <div class="flex-shrink-0 w-24 h-24 sm:w-40 sm:h-40 rounded-lg flex items-center justify-center">
                        <img src="{{ asset('brands/dell.webp') }}" alt="Dell" class="h-full object-contain p-2 sm:p-4">
                    </div>
                    <div class="flex-shrink-0 w-24 h-24 sm:w-40 sm:h-40 rounded-lg flex items-center justify-center">
                        <img src="{{ asset('brands/google.webp') }}" alt="Google" class="h-full object-contain p-2 sm:p-4">
                    </div>
                    <div class="flex-shrink-0 w-24 h-24 sm:w-40 sm:h-40 rounded-lg flex items-center justify-center">
                        <img src="{{ asset('brands/hp.webp') }}" alt="HP" class="h-full object-contain p-2 sm:p-4">
                    </div>
                    <div class="flex-shrink-0 w-24 h-24 sm:w-40 sm:h-40 rounded-lg flex items-center justify-center">
                        <img src="{{ asset('brands/lg.webp') }}" alt="LG" class="h-full object-contain p-2 sm:p-4">
                    </div>
                    <div class="flex-shrink-0 w-24 h-24 sm:w-40 sm:h-40 rounded-lg flex items-center justify-center">
                        <img src="{{ asset('brands/microsoft.webp') }}" alt="Microsoft" class="h-full object-contain p-2 sm:p-4">
                    </div>
                    <div class="flex-shrink-0 w-24 h-24 sm:w-40 sm:h-40 rounded-lg flex items-center justify-center">
                        <img src="{{ asset('brands/samsung.webp') }}" alt="Samsung" class="h-full object-contain p-2 sm:p-4">
                    </div>
                    <div class="flex-shrink-0 w-24 h-24 sm:w-40 sm:h-40 rounded-lg flex items-center justify-center">
                        <img src="{{ asset('brands/sony.webp') }}" alt="Sony" class="h-full object-contain p-2 sm:p-4">
                    </div>
                </div>
            </div>
        </section>

        <!-- Why Shop With Us Section -->
        <section class="mt-14">
            <h2 class="text-2xl font-bold mb-6 text-center sm:text-left">Why Shop With Us?</h2>
            <div class="grid grid-cols-1 sm:grid-cols-3 gap-6">
                <div class="flex flex-col items-center bg-blue-50 rounded-[18px] p-6">
                    <img src="{{ asset('icons/Fast Delivery.webp') }}" alt="Fast Delivery Icon" class="w-10 h-10 mb-2">
                    <span class="font-semibold">Fast Delivery</span>
                    <p class="text-sm text-center mt-2">Get your products delivered quickly and safely.</p>
                </div>
                <div class="flex flex-col items-center bg-blue-50 rounded-[18px] p-6">
                    <img src="{{ asset('icons/Secure Payment.webp') }}" alt="Secure Payment Icon" class="w-10 h-10 mb-2">
                    <span class="font-semibold">Secure Payment</span>
                    <p class="text-sm text-center mt-2">Your transactions are protected and encrypted.</p>
                </div>
                <div class="flex flex-col items-center bg-blue-50 rounded-[18px] p-6">
                    <img src="{{ asset('icons/Quality Guarantee.webp') }}" alt="Quality Guarantee Icon" class="w-10 h-10 mb-2">
                    <span class="font-semibold">Quality Guarantee</span>
                    <p class="text-sm text-center mt-2">We offer only genuine and high-quality products.</p>
                </div>
            </div>
        </section>

        <!-- How It Works Section -->
        <section class="mt-14">
            <h2 class="text-2xl font-bold mb-6 text-center sm:text-left">How It Works</h2>
            <div class="grid grid-cols-1 sm:grid-cols-3 gap-6">
                <div class="flex flex-col items-center bg-blue-50 rounded-[18px] p-6">
                    <span class="font-semibold text-lg mb-2">1. Browse Products</span>
                    <p class="text-sm text-center">Explore our wide range of electronics and gadgets.</p>
                </div>
                <div class="flex flex-col items-center bg-blue-50 rounded-[18px] p-6">
                    <span class="font-semibold text-lg mb-2">2. Place Your Order</span>
                    <p class="text-sm text-center">Add your favorite items to cart and checkout securely.</p>
                </div>
                <div class="flex flex-col items-center bg-blue-50 rounded-[18px] p-6">
                    <span class="font-semibold text-lg mb-2">3. Fast Delivery</span>
                    <p class="text-sm text-center">Receive your order quickly at your doorstep.</p>
                </div>
            </div>
        </section>

        <!-- Customer Reviews Section -->
        <section class="mt-14">
            <h2 class="text-2xl font-bold mb-6 text-center sm:text-left">Customer Reviews</h2>
            <div class="grid grid-cols-1 sm:grid-cols-3 gap-6">
                <style>
                    .review-card {
                        background: #fff;
                        border-radius: 18px;
                        box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);
                        padding: 1.5rem;
                        display: flex;
                        flex-direction: column;
                        gap: 1rem;
                    }

                    .review-stars {
                        display: flex;
                        gap: 2px;
                        margin-bottom: 1rem;
                    }

                    .review-text {
                        color: #6b7280;
                        font-size: 0.95rem;
                        line-height: 1.5;
                        margin-bottom: 1.5rem;
                        flex-grow: 1;
                    }

                    .review-profile {
                        display: flex;
                        align-items: center;
                        gap: 0.75rem;
                    }

                    .review-avatar {
                        width: 48px;
                        height: 48px;
                        border-radius: 50%;
                        object-fit: cover;
                    }

                    .review-info h4 {
                        font-weight: 600;
                        font-size: 1rem;
                        color: #111827;
                        margin: 0;
                    }

                    .review-info p {
                        font-size: 0.875rem;
                        color: #6b7280;
                        margin: 0;
                    }
                </style>
                @php
                $reviews = [
                [
                'name' => 'Olivia Carter',
                'role' => 'Design Lead',
                'text' => 'Pagedone stands out as the most user-friendly and effective solution I\'ve ever used.',
                'stars' => 5,
                'image' => 'reviews/1.webp'
                ],
                [
                'name' => 'Marcus Johnson',
                'role' => 'Product Manager',
                'text' => 'ByteCart has revolutionized how we handle our electronics procurement. The quality and service are exceptional.',
                'stars' => 4.5,
                'image' => 'reviews/2.webp'
                ],
                [
                'name' => 'Sarah Williams',
                'role' => 'Tech Entrepreneur',
                'text' => 'Outstanding customer support and lightning-fast delivery. ByteCart has become my go-to for all tech needs.',
                'stars' => 4,
                'image' => 'reviews/3.webp'
                ],
                ];
                @endphp
                @foreach($reviews as $review)
                <div class="review-card">
                    <div class="review-stars">
                        @for($i = 0; $i < floor($review['stars']); $i++)
                            <svg class="w-5 h-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20">
                            <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.286 3.967a1 1 0 00.95.69h4.175c.969 0 1.371 1.24.588 1.81l-3.38 2.455a1 1 0 00-.364 1.118l1.287 3.967c.3.921-.755 1.688-1.54 1.118l-3.38-2.455a1 1 0 00-1.175 0l-3.38 2.455c-.784.57-1.838-.197-1.539-1.118l1.287-3.967a1 1 0 00-.364-1.118L2.174 9.394c-.783-.57-.38-1.81.588-1.81h4.175a1 1 0 00.95-.69l1.286-3.967z" />
                            </svg>
                            @endfor
                            @if($review['stars'] - floor($review['stars']) >= 0.5)
                            <svg class="w-5 h-5 text-yellow-400" viewBox="0 0 20 20">
                                <defs>
                                    <linearGradient id="half-{{ $loop->index }}">
                                        <stop offset="50%" stop-color="currentColor" />
                                        <stop offset="50%" stop-color="#d1d5db" />
                                    </linearGradient>
                                </defs>
                                <path fill="url(#half-{{ $loop->index }})" d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.286 3.967a1 1 0 00.95.69h4.175c.969 0 1.371 1.24.588 1.81l-3.38 2.455a1 1 0 00-.364 1.118l1.287 3.967c.3.921-.755 1.688-1.54 1.118l-3.38-2.455a1 1 0 00-1.175 0l-3.38 2.455c-.784.57-1.838-.197-1.539-1.118l1.287-3.967a1 1 0 00-.364-1.118L2.174 9.394c-.783-.57-.38-1.81.588-1.81h4.175a1 1 0 00.95-.69l1.286-3.967z" />
                            </svg>
                            @endif
                            @for($i = ceil($review['stars']); $i < 5; $i++)
                                <svg class="w-5 h-5 text-gray-300" fill="currentColor" viewBox="0 0 20 20">
                                <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.286 3.967a1 1 0 00.95.69h4.175c.969 0 1.371 1.24.588 1.81l-3.38 2.455a1 1 0 00-.364 1.118l1.287 3.967c.3.921-.755 1.688-1.54 1.118l-3.38-2.455a1 1 0 00-1.175 0l-3.38 2.455c-.784.57-1.838-.197-1.539-1.118l1.287-3.967a1 1 0 00-.364-1.118L2.174 9.394c-.783-.57-.38-1.81.588-1.81h4.175a1 1 0 00.95-.69l1.286-3.967z" />
                                </svg>
                                @endfor
                    </div>
                    <p class="review-text">{{ $review['text'] }}</p>
                    <div class="review-profile">
                        <img src="{{ asset($review['image']) }}" alt="{{ $review['name'] }}" class="review-avatar">
                        <div class="review-info">
                            <h4>{{ $review['name'] }}</h4>
                            <p>{{ $review['role'] }}</p>
                        </div>
                    </div>
                </div>
                @endforeach
            </div>
        </section>
    </div>

    <script>
        // Smoother seamless auto-scroll for Brands Section
        const brandsContainer = document.getElementById('brands-container');
        const scrollStep = 1; // Increased speed

        // Clone brand logos for seamless looping
        const brandItems = Array.from(brandsContainer.children);
        brandItems.forEach(item => {
            brandsContainer.appendChild(item.cloneNode(true));
        });

        function autoScrollBrands() {
            let maxScroll = brandsContainer.scrollWidth / 2;
            if (brandsContainer.scrollLeft >= maxScroll) {
                brandsContainer.scrollLeft = 1; // Avoid visible jump
            } else {
                brandsContainer.scrollLeft += scrollStep;
            }
            requestAnimationFrame(autoScrollBrands);
        }

        requestAnimationFrame(autoScrollBrands);
    </script>
    @livewire('footer')
</body>

</html>