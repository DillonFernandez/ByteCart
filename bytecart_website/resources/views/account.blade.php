@php
$user = auth()->user();
if (!$user || ($user->roles ?? '') !== 'customer') {
\Illuminate\Support\Facades\Auth::guard('web')->logout();
\Illuminate\Support\Facades\Session::invalidate();
\Illuminate\Support\Facades\Session::regenerateToken();
header('Location: ' . route('login'));
exit;
}
@endphp
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>{{ $user->name ?? 'Account' }} | Account</title>
    <link rel="icon" type="image/x-icon" href="{{ asset('logo/x-icon.webp') }}">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <style>
        /* Account Dashboard Layout */
        .account-dashboard-container {
            display: flex;
            flex-direction: column;
            gap: 2rem;
        }

        .dashboard-content {
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

        .welcome-banner {
            background: linear-gradient(135deg, #dbeafe 0%, #bfdbfe 100%);
            border: 1px solid #93c5fd;
            border-radius: 18px;
            padding: 1.5rem;
            margin-bottom: 2rem;
        }

        .welcome-title {
            font-weight: 600;
            color: #1e40af;
            margin-bottom: 0.5rem;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .welcome-text {
            color: #1e40af;
            line-height: 1.6;
            margin: 0;
        }

        /* Dashboard Cards */
        .dashboard-grid {
            display: grid;
            gap: 1.5rem;
            grid-template-columns: 1fr;
            margin-bottom: 2rem;
        }

        .dashboard-card {
            background: white;
            border: none;
            border-radius: 18px;
            padding: 1.5rem;
            box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);
            transition: all 0.2s ease;
            position: relative;
            overflow: hidden;
            display: flex;
            flex-direction: column;
            height: 100%;
        }

        .card-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 1rem;
        }

        .card-title-section {
            display: flex;
            align-items: center;
            gap: 0.75rem;
        }

        .card-icon {
            width: 3rem;
            height: 3rem;
            background: linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%);
            border-radius: 9px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #2563eb;
            border: 1px solid #bfdbfe;
        }

        .card-title {
            font-size: 1.125rem;
            font-weight: 600;
            color: #1e293b;
            margin: 0;
        }

        .card-metric {
            text-align: right;
        }

        .primary-metric {
            font-size: 2rem;
            font-weight: 800;
            color: #2563eb;
            line-height: 1;
            margin: 0;
        }

        .metric-label {
            color: #64748b;
            font-size: 0.75rem;
            font-weight: 500;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            margin-top: 0.25rem;
        }

        .card-body {
            flex: 1;
            display: flex;
            flex-direction: column;
            margin-bottom: 1.25rem;
        }

        .metrics-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            background: #f8fafc;
            padding: 1rem;
            border-radius: 9px;
            margin-bottom: 1rem;
            border: 1px solid #f1f5f9;
        }

        .mini-metric {
            text-align: center;
        }

        .mini-metric-value {
            font-size: 1.25rem;
            font-weight: 700;
            color: #1e293b;
            line-height: 1;
        }

        .mini-metric-label {
            color: #64748b;
            font-size: 0.75rem;
            margin-top: 0.25rem;
            font-weight: 500;
        }

        .status-section {
            margin-bottom: 1rem;
        }

        .status-badges {
            display: flex;
            gap: 0.5rem;
            flex-wrap: wrap;
            margin-bottom: 0.75rem;
        }

        .badge {
            display: inline-flex;
            align-items: center;
            padding: 0.25rem 0.75rem;
            border-radius: 999px;
            font-size: 0.7rem;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }

        .badge--complete {
            background: #dcfce7;
            color: #166534;
            border: 1px solid #bbf7d0;
        }

        .badge--incomplete {
            background: #fef3c7;
            color: #92400e;
            border: 1px solid #fde68a;
        }

        .badge--info {
            background: #dbeafe;
            color: #1e40af;
            border: 1px solid #93c5fd;
        }

        .card-details {
            color: #64748b;
            font-size: 0.8rem;
            line-height: 1.4;
            background: #fafbfc;
            padding: 0.75rem;
            border-radius: 9px;
            border-left: 3px solid #e2e8f0;
            flex: 1;
        }

        .card-action {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 0.5rem;
            width: 100%;
            padding: 0.75rem 1rem;
            background: #2563eb;
            color: white;
            text-decoration: none;
            border-radius: 9px;
            font-weight: 500;
            font-size: 0.8rem;
            transition: all 0.2s ease;
            text-transform: uppercase;
            letter-spacing: 0.025em;
        }

        .card-action:hover {
            background: #1d4ed8;
            transform: translateY(-1px);
            box-shadow: 0 4px 12px rgba(37, 99, 235, 0.3);
        }

        .card-action svg {
            width: 16px;
            height: 16px;
        }

        /* Quick Actions Section */
        .quick-actions {
            background: white;
            border: none;
            border-radius: 18px;
            padding: 2rem;
            box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);
        }

        .quick-actions-title {
            font-size: 1.25rem;
            font-weight: 600;
            color: #1e293b;
            margin: 0 0 1.5rem 0;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .actions-grid {
            display: grid;
            gap: 1rem;
            grid-template-columns: 1fr;
        }

        .action-button {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            padding: 1rem;
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 9px;
            text-decoration: none;
            color: #374151;
            font-weight: 500;
            transition: all 0.2s ease;
        }

        .action-button:hover {
            background: #e2e8f0;
            transform: translateY(-1px);
        }

        .action-icon {
            width: 20px;
            height: 20px;
            color: #2563eb;
        }

        /* Icons */
        .icon {
            width: 20px;
            height: 20px;
            flex-shrink: 0;
        }

        @media (max-width: 767px) {
            .account-dashboard-container {
                gap: 0rem;
            }

            .page-header {
                margin-bottom: 1rem;
            }

            .quick-actions {
                padding: 1.5rem;
            }
        }

        /* Responsive Design */
        @media (min-width: 768px) {
            .account-dashboard-container {
                flex-direction: row;
                align-items: flex-start;
                gap: 3rem;
            }

            .dashboard-content {
                flex: 1;
            }

            .page-title,
            .page-subtitle {
                text-align: left;
            }

            .dashboard-grid {
                grid-template-columns: repeat(2, 1fr);
                gap: 2rem;
            }

            .actions-grid {
                grid-template-columns: repeat(3, 1fr);
            }
        }

        @media (min-width: 1280px) {
            .dashboard-grid {
                grid-template-columns: repeat(4, 1fr);
            }
        }
    </style>
</head>

<body>
    @livewire('nav-bar')
    <div class="w-full mx-auto pb-8 pt-5 px-4 sm:px-16 sm:pb-10 sm:pt-5">
        @php
        use App\Models\Order;
        use App\Models\WishList;

        // Replaced Mongo fields with MySQL equivalents
        $ordersQuery = Order::where('user_id', $user->id);
        $ordersCount = (clone $ordersQuery)->count();
        $openOrdersCount = (clone $ordersQuery)->whereNotIn('order_status', ['delivered','canceled'])->count();
        $lastOrder = (clone $ordersQuery)->orderByDesc('placed_at')->first();
        $wishCount = WishList::where('user_id', $user->id)->count();
        $hasShipping = !empty($user->shipping_street_address) && !empty($user->shipping_city) && !empty($user->shipping_district) && !empty($user->shipping_zip_code);
        $hasBilling = ($user->is_billing_same_as_shipping ?? false) || (!empty($user->billing_street_address) && !empty($user->billing_city) && !empty($user->billing_district) && !empty($user->billing_zip_code));
        $paymentMethod = $user->payment_method ?? null;
        $hasSavedCard = ($paymentMethod === 'Visa/MasterCard') && !empty($user->card_number);
        @endphp

        <div class="account-dashboard-container">
            <!-- Desktop/Mobile Navigation -->
            @livewire('account-navbar')

            <!-- Main Content -->
            <div class="dashboard-content">
                <!-- Page Header -->
                <div class="page-header">
                    <h1 class="page-title">Account Dashboard</h1>
                    <p class="page-subtitle">Welcome back, {{ $user->first_name ?? $user->name }}! Here's your account overview</p>
                </div>

                <!-- Welcome Banner -->
                <div class="welcome-banner">
                    <div class="welcome-title">
                        Quick Account Overview
                    </div>
                    <p class="welcome-text">
                        Manage your orders, update your profile, and track your purchases all in one place.
                        Use the navigation menu to access different sections of your account.
                    </p>
                </div>

                <!-- Dashboard Cards -->
                <div class="dashboard-grid">
                    <!-- Orders Card -->
                    <div class="dashboard-card">
                        <div class="card-header">
                            <div class="card-title-section">
                                <div class="card-icon">
                                    <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M16 4h2a2 2 0 012 2v14a2 2 0 01-2 2H6a2 2 0 01-2-2V6a2 2 0 012-2h2" />
                                        <rect x="8" y="2" width="8" height="4" rx="1" ry="1" />
                                    </svg>
                                </div>
                                <h3 class="card-title">Orders</h3>
                            </div>
                            <div class="card-metric">
                                <div class="primary-metric">{{ $ordersCount }}</div>
                                <div class="metric-label">Total</div>
                            </div>
                        </div>
                        <div class="card-body">
                            <div class="metrics-row">
                                <div class="mini-metric">
                                    <div class="mini-metric-value">{{ $openOrdersCount }}</div>
                                    <div class="mini-metric-label">Active</div>
                                </div>
                                <div class="mini-metric">
                                    <div class="mini-metric-value">{{ $ordersCount - $openOrdersCount }}</div>
                                    <div class="mini-metric-label">Completed</div>
                                </div>
                            </div>
                            @if($lastOrder)
                            <div class="card-details">
                                <strong>Latest Order:</strong> #{{ $lastOrder->order_number }}<br>
                                <strong>Status:</strong> {{ ucfirst($lastOrder->order_status ?? 'pending') }}<br>
                                <strong>Date:</strong> {{ optional($lastOrder->placed_at)->format('M d, Y') }}
                            </div>
                            @else
                            <div class="card-details">No orders placed yet. Start shopping to see your orders here!</div>
                            @endif
                        </div>
                        <a href="{{ route('my-order') }}" class="card-action">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M9 12l2 2 4-4" />
                                <path d="M21 12c0 4.97-4.03 9-9 9s-9-4.03-9-9 4.03-9 9-9 9 4.03 9 9z" />
                            </svg>
                            View All Orders
                        </a>
                    </div>

                    <!-- Wish List Card -->
                    <div class="dashboard-card">
                        <div class="card-header">
                            <div class="card-title-section">
                                <div class="card-icon">
                                    <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M20.84 4.61a5.5 5.5 0 00-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 00-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 000-7.78z" />
                                    </svg>
                                </div>
                                <h3 class="card-title">Wish List</h3>
                            </div>
                            <div class="card-metric">
                                <div class="primary-metric">{{ $wishCount }}</div>
                                <div class="metric-label">Items</div>
                            </div>
                        </div>
                        <div class="card-body">
                            <div class="card-details">
                                @if($wishCount > 0)
                                You have {{ $wishCount }} item{{ $wishCount === 1 ? '' : 's' }} saved for later. Perfect for planning future purchases!
                                @else
                                Start building your wish list by clicking the heart icon on products you love.
                                @endif
                            </div>
                        </div>
                        <a href="{{ route('wish-list') }}" class="card-action">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M20.84 4.61a5.5 5.5 0 00-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 00-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 000-7.78z" />
                            </svg>
                            Open Wish List
                        </a>
                    </div>

                    <!-- Shipping Info Card -->
                    <div class="dashboard-card">
                        <div class="card-header">
                            <div class="card-title-section">
                                <div class="card-icon">
                                    <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z" />
                                        <circle cx="12" cy="10" r="3" />
                                    </svg>
                                </div>
                                <h3 class="card-title">Shipping Info</h3>
                            </div>
                        </div>
                        <div class="card-body">
                            <div class="status-section">
                                <div class="status-badges">
                                    @if($hasShipping)
                                    <span class="badge badge--complete">Shipping Complete</span>
                                    @else
                                    <span class="badge badge--incomplete">Shipping Incomplete</span>
                                    @endif

                                    @if($user->is_billing_same_as_shipping ?? false)
                                    <span class="badge badge--info">Same as Shipping</span>
                                    @elseif($hasBilling)
                                    <span class="badge badge--complete">Billing Complete</span>
                                    @else
                                    <span class="badge badge--incomplete">Billing Incomplete</span>
                                    @endif
                                </div>
                            </div>
                            <div class="card-details">
                                @if($hasShipping && $hasBilling)
                                Your shipping and billing addresses are set up and ready for checkout.
                                @else
                                Complete your address information for faster checkout and accurate deliveries.
                                @endif
                            </div>
                        </div>
                        <a href="{{ route('shipping-info') }}" class="card-action">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M12 6v6l4 2" />
                                <circle cx="12" cy="12" r="10" />
                            </svg>
                            Manage Addresses
                        </a>
                    </div>

                    <!-- Payment Methods Card -->
                    <div class="dashboard-card">
                        <div class="card-header">
                            <div class="card-title-section">
                                <div class="card-icon">
                                    <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <rect x="1" y="4" width="22" height="16" rx="2" ry="2" />
                                        <line x1="1" y1="10" x2="23" y2="10" />
                                    </svg>
                                </div>
                                <h3 class="card-title">Payment Methods</h3>
                            </div>
                        </div>
                        <div class="card-body">
                            <div class="status-section">
                                <div class="status-badges">
                                    @if($paymentMethod)
                                    <span class="badge badge--info">{{ $paymentMethod }}</span>
                                    @if($hasSavedCard)
                                    <span class="badge badge--complete">Card Saved</span>
                                    @endif
                                    @else
                                    <span class="badge badge--incomplete">Not Set</span>
                                    @endif
                                </div>
                            </div>
                            <div class="card-details">
                                @if($paymentMethod)
                                Your preferred payment method is set to {{ $paymentMethod }}.
                                @if($hasSavedCard)Card details are securely saved.@endif
                                @else
                                Choose your preferred payment method for faster and more convenient checkout.
                                @endif
                            </div>
                        </div>
                        <a href="{{ route('payment-methods') }}" class="card-action">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <rect x="1" y="4" width="22" height="16" rx="2" ry="2" />
                                <line x1="1" y1="10" x2="23" y2="10" />
                            </svg>
                            Payment Settings
                        </a>
                    </div>
                </div>

                <!-- Quick Actions Section -->
                <div class="quick-actions">
                    <h3 class="quick-actions-title">
                        <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <circle cx="12" cy="12" r="3" />
                            <path d="M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 010 2.83 2 2 0 01-2.83 0l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-2 2 2 2 0 01-2-2v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 01-2.83 0 2 2 0 010-2.83l.06-.06a1.65 1.65 0 00.33-1.82 1.65 1.65 0 00-1.51-1H3a2 2 0 01-2-2 2 2 0 012-2h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 010-2.83 2 2 0 012.83 0l.06.06a1.65 1.65 0 001.82.33H9a1.65 1.65 0 001-1.51V3a2 2 0 012-2 2 2 0 012 2v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 012.83 0 2 2 0 010 2.83l-.06.06a1.65 1.65 0 00-.33 1.82V9a1.65 1.65 0 001.51 1H21a2 2 0 012 2 2 2 0 01-2 2h-.09a1.65 1.65 0 00-1.51 1z" />
                        </svg>
                        Quick Actions
                    </h3>
                    <div class="actions-grid">
                        <a href="{{ route('account-settings') }}" class="action-button">
                            <svg class="action-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M16 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2" />
                                <circle cx="8.5" cy="7" r="4" />
                                <path d="M20 8v6M23 11h-6" />
                            </svg>
                            Profile & Security
                        </a>
                        <a href="{{ route('shipping-info') }}" class="action-button">
                            <svg class="action-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z" />
                                <circle cx="12" cy="10" r="3" />
                            </svg>
                            Manage Addresses
                        </a>
                        <a href="{{ route('payment-methods') }}" class="action-button">
                            <svg class="action-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <rect x="1" y="4" width="22" height="16" rx="2" ry="2" />
                                <line x1="1" y1="10" x2="23" y2="10" />
                            </svg>
                            Payment Methods
                        </a>
                    </div>
                </div>
            </div>
        </div>
    </div>
    @livewire('footer')
</body>

</html>