@php
$user = auth()->user();
if (!$user || ($user->roles ?? '') !== 'customer') {
\Illuminate\Support\Facades\Auth::guard('web')->logout();
\Illuminate\Support\Facades\Session::invalidate();
\Illuminate\Support\Facades\Session::regenerateToken();
header('Location: ' . route('login'));
exit;
}
$wishListProducts = [];
if ($user) {
$wishListProducts = \App\Models\WishList::where('user_id', $user->id)->with('product.models')->get()->map(function($item) {
return $item->product;
})->filter()->all();
}
@endphp
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>{{ $user->name ?? 'Wish List' }} | Wish List</title>
    <link rel="icon" type="image/x-icon" href="{{ asset('logo/x-icon.webp') }}">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <style>
        /* Wish List Layout */
        .wish-list-container {
            display: flex;
            flex-direction: column;
            gap: 2rem;
        }

        .wishlist-content {
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

        /* Empty State */
        .empty-state {
            text-align: center;
            padding: 4rem 2rem;
            background: white;
            border: none;
            border-radius: 18px;
            box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);
        }

        .empty-state__icon {
            width: 80px;
            height: 80px;
            margin: 0 auto 1.5rem;
            padding: 1.5rem;
            background: #fef3f2;
            border-radius: 50%;
            color: #e11d48;
        }

        .empty-state__icon svg {
            width: 100%;
            height: 100%;
        }

        .empty-state__title {
            font-size: 1.5rem;
            font-weight: 600;
            color: #1e293b;
            margin: 0 0 0.75rem 0;
        }

        .empty-state__description {
            color: #64748b;
            margin: 0 0 2rem 0;
            line-height: 1.6;
        }

        .empty-state__button {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            padding: 0.875rem 1.5rem;
            background: #2563eb;
            color: white;
            text-decoration: none;
            border-radius: 9px;
            font-weight: 500;
            transition: all 0.2s ease;
        }

        .empty-state__button:hover {
            background: #1d4ed8;
            transform: translateY(-1px);
        }

        .button-icon {
            width: 18px;
            height: 18px;
        }

        /* Product Grid */
        .products-section {
            background: transparent;
            border: none;
            border-radius: 0;
            padding: 0;
            box-shadow: none;
        }

        .products-title {
            font-size: 1.25rem;
            font-weight: 600;
            color: #1e293b;
            margin: 0 0 1.5rem 0;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .products-count {
            background: #e0e7ff;
            color: #4338ca;
            padding: 0.25rem 0.75rem;
            border-radius: 999px;
            font-size: 0.875rem;
            font-weight: 500;
        }

        .divider {
            height: 1px;
            background: linear-gradient(to right, transparent, #e2e8f0, transparent);
            margin: 2rem 0;
        }

        /* Icons */
        .icon {
            width: 20px;
            height: 20px;
            flex-shrink: 0;
        }

        @media (max-width: 767px) {
            .wish-list-container {
                gap: 0rem;
            }

            .page-header {
                margin-bottom: 1rem;
            }
        }

        /* Responsive Design */
        @media (min-width: 768px) {
            .wish-list-container {
                flex-direction: row;
                align-items: flex-start;
                gap: 3rem;
            }

            .wishlist-content {
                flex: 1;
            }

            .page-title,
            .page-subtitle {
                text-align: left;
            }
        }

        @media (min-width: 1024px) {
            .wish-list-container {
                gap: 4rem;
            }
        }
    </style>
</head>

<body class="bg-white">
    @livewire('nav-bar')
    <div class="bg-white w-full mx-auto pb-8 pt-5 px-4 sm:px-16 sm:pb-10 sm:pt-5">
        <div class="wish-list-container">
            <!-- Desktop/Mobile Navigation -->
            @livewire('account-navbar')

            <!-- Main Content -->
            <div class="wishlist-content">
                <!-- Page Header -->
                <div class="page-header">
                    <h1 class="page-title">My Wish List</h1>
                    <p class="page-subtitle">Save and organize your favorite products</p>
                </div>

                <!-- Info Banner -->
                <div class="info-banner">
                    <div class="info-banner-title">
                        Your Personal Wish List
                    </div>
                    <p class="info-banner-text">
                        Save products you love and easily find them later. Your wish list helps you keep track of favorites and plan future purchases. Items are saved privately and can be accessed anytime.
                    </p>
                </div>

                @if(count($wishListProducts) > 0)
                <!-- Products Section -->
                <div class="products-section">
                    <div class="products-title">
                        <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M20.84 4.61a5.5 5.5 0 00-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 00-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 000-7.78z" />
                        </svg>
                        Saved Products
                        <span class="products-count">{{ count($wishListProducts) }} item{{ count($wishListProducts) !== 1 ? 's' : '' }}</span>
                    </div>
                    <div class="custom-card-grid">
                        @foreach($wishListProducts as $product)
                        @include('livewire.product-card', ['product' => $product])
                        @endforeach
                    </div>
                </div>
                @else
                <!-- Empty State -->
                <div class="empty-state">
                    <div class="empty-state__icon">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M20.84 4.61a5.5 5.5 0 00-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 00-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 000-7.78z" />
                        </svg>
                    </div>
                    <h3 class="empty-state__title">Your Wish List is Empty</h3>
                    <p class="empty-state__description">
                        Start building your wish list by browsing our products and clicking the heart icon on items you love.
                        This way, you can easily find your favorites later!
                    </p>
                    <a href="{{ route('shop-all') }}" class="empty-state__button">
                        <svg class="button-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M3 3h2l.4 2M7 13h10l4-8H5.4m0 0L7 13m0 0l-2.5 8M7 13l2.5-8M17 21a2 2 0 100-4 2 2 0 000 4zM9 21a2 2 0 100-4 2 2 0 000 4z" />
                        </svg>
                        Start Shopping
                    </a>
                </div>
                @endif
            </div>
        </div>
    </div>
    @livewire('footer')
</body>

</html>