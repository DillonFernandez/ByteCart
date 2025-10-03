@php
$user = auth()->user();
if (!$user || ($user->roles ?? '') !== 'customer') {
\Illuminate\Support\Facades\Auth::guard('web')->logout();
\Illuminate\Support\Facades\Session::invalidate();
\Illuminate\Support\Facades\Session::regenerateToken();
header('Location: ' . route('login'));
exit;
}

use App\Models\Order;

// Fetch the current user's orders from Mongo (mongodb_orders) via Eloquent model
$orders = Order::with('items')
->where('user_id', $user->id)
->orderByDesc('placed_at')
->orderByDesc('created_at')
->paginate(10);
@endphp
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>{{ $user->name ?? 'My Orders' }} | My Orders</title>
    <link rel="icon" type="image/x-icon" href="{{ asset('logo/x-icon.webp') }}">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <style>
        * {
            box-sizing: border-box;
        }

        /* My Orders Layout */
        .my-orders-container {
            display: flex;
            flex-direction: column;
            gap: 2rem;
        }

        .orders-content {
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

        /* Info Banner */
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

        .icon {
            width: 20px;
            height: 20px;
            flex-shrink: 0;
        }

        /* Help Section (match shipping/payment pages) */
        .help-section {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 18px;
            padding: 1.5rem;
            margin-bottom: 1rem;
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
            padding: 3rem 2rem;
            background: white;
            border: none;
            border-radius: 18px;
            box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);
        }

        .empty-state__icon {
            width: 64px;
            height: 64px;
            margin: 0 auto 1.5rem;
            padding: 1rem;
            background: #f8fafc;
            border-radius: 50%;
            color: #64748b;
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

        @media (max-width: 767px) {
            .my-orders-container {
                gap: 0rem;
            }

            .page-header {
                margin-bottom: 1rem;
            }
        }

        .card {
            box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);
            border-radius: 18px;
            border: 1px solid #f1f5f9;
            transition: box-shadow 0.2s ease;
        }

        .card:hover {
            box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);
        }

        .badge {
            padding: 6px 12px;
            border-radius: 999px;
            font-size: 0.75rem;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }

        .badge.gray {
            background: #f3f4f6;
            color: #374151;
        }

        .badge.green {
            background: #dcfce7;
            color: #166534;
        }

        .badge.yellow {
            background: #fef9c3;
            color: #854d0e;
        }

        .badge.red {
            background: #fee2e2;
            color: #991b1b;
        }

        .btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            padding: 10px 16px;
            border-radius: 9px;
            border: 1px solid #e5e7eb;
            background: #fff;
            cursor: pointer;
            font-size: 0.875rem;
            font-weight: 500;
            transition: all 0.2s ease;
            min-height: 40px;
        }

        .btn:hover {
            background: #f9fafb;
            transform: translateY(-1px);
        }

        .muted {
            color: #6b7280;
        }

        /* Responsive breakpoints */
        @media (min-width: 768px) {
            .my-orders-container {
                flex-direction: row;
                align-items: flex-start;
                gap: 3rem;
            }

            .orders-content {
                flex: 1;
            }

            .page-title,
            .page-subtitle {
                text-align: left;
            }

            .order-summary {
                grid-template-columns: repeat(3, 1fr);
            }

            .order-title {
                flex-direction: row;
                align-items: center;
            }
        }

        @media (min-width: 1024px) {
            .my-orders-container {
                gap: 4rem;
            }
        }

        @media (min-width: 768px) {
            .details-grid {
                grid-template-columns: 2fr 1fr;
            }

            .table th,
            .table td {
                padding: 12px 16px;
            }
        }

        @media (min-width: 1024px) {
            .order-content {
                padding: 24px;
            }

            .order-header {
                padding: 18px 24px;
            }
        }

        @media (max-width: 639px) {
            .order-title {
                flex-direction: column;
                align-items: flex-start;
                gap: 12px;
            }

            .order-actions {
                flex-direction: column;
                align-items: stretch;
            }

            .btn {
                width: 100%;
            }

            .table {
                font-size: 0.875rem;
            }

            .table th,
            .table td {
                padding: 8px 4px;
            }

            .order-summary {
                grid-template-columns: 1fr;
                gap: 16px;
            }

            .summary-item {
                display: flex;
                justify-content: space-between;
                align-items: center;
                text-align: left;
            }

            .summary-value {
                font-size: 1rem;
            }
        }

        /* Alpine x-cloak helper for order details in PowerGrid */
        [x-cloak] {
            display: none !important;
        }

        /* PowerGrid Table Styling */
        .pg-table-container {
            background: white;
            border-radius: 18px;
            border: none;
            box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);
            overflow: hidden;
            margin-bottom: 2rem;
        }

        .pg-table-container table {
            width: 100%;
            border-collapse: collapse;
        }

        .pg-table-container th {
            background: #f8fafc;
            padding: 12px 16px;
            text-align: left;
            font-weight: 600;
            font-size: 0.875rem;
            color: #374151;
            border-bottom: 1px solid #e2e8f0;
        }

        .pg-table-container td {
            padding: 16px;
            border-bottom: 1px solid #f1f5f9;
            vertical-align: middle;
            font-size: 0.875rem;
        }

        .pg-table-container tr:hover {
            background: #f8fafc;
        }

        .pg-table-container tr:last-child td {
            border-bottom: none;
        }

        /* Action Button Styles */
        .action-btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
            padding: 8px 16px;
            border-radius: 9px;
            border: 1px solid;
            font-size: 0.75rem;
            font-weight: 500;
            transition: all 0.2s ease;
            cursor: pointer;
            text-decoration: none;
            min-height: 32px;
            min-width: 80px;
            text-align: center;
        }

        .action-btn:hover {
            transform: translateY(-1px);
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
        }

        .action-btn--primary {
            background: #f8fafc;
            border-color: #e2e8f0;
            color: #475569;
        }

        .action-btn--primary:hover {
            background: #f1f5f9;
            border-color: #cbd5e1;
        }

        .action-btn--danger {
            background: #fee2e2;
            border-color: #fecaca;
            color: #991b1b;
        }

        .action-btn--danger:hover {
            background: #fecaca;
            border-color: #f87171;
        }

        .action-btn--success {
            background: #dcfce7;
            border-color: #bbf7d0;
            color: #166534;
        }

        .action-btn--success:hover {
            background: #bbf7d0;
            border-color: #86efac;
        }

        /* PowerGrid Header and Footer Styling */
        .pg-header,
        .pg-footer {
            background: #f8fafc;
            border-bottom: 1px solid #e2e8f0;
            padding: 16px;
        }

        .pg-footer {
            border-bottom: none;
            border-top: 1px solid #e2e8f0;
        }

        /* Mobile Responsive Adjustments */
        @media (max-width: 767px) {
            .action-btn {
                padding: 6px 12px;
                min-width: 70px;
                font-size: 0.7rem;
            }

            .pg-table-container th,
            .pg-table-container td {
                padding: 8px 4px;
                font-size: 0.75rem;
            }

            .pg-table-container th:nth-child(n+3),
            .pg-table-container td:nth-child(n+3) {
                display: none;
            }
        }

        @media (max-width: 639px) {
            .pg-table-container {
                border-radius: 18px;
                margin-bottom: 1rem;
            }
        }
    </style>
</head>

<body>
    @livewire('nav-bar')

    <div class="w-full mx-auto pb-8 pt-5 px-4 sm:px-16 sm:pb-10 sm:pt-5">
        <div class="my-orders-container">
            <!-- Desktop/Mobile Navigation -->
            @livewire('account-navbar')

            <!-- Main Content -->
            <div class="orders-content">
                <!-- Status Messages -->
                @if (session('status'))
                <div id="status-message" class="status-message status-message--success">
                    <svg class="status-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M9 12l2 2 4-4M21 12c0 4.97-4.03 9-9 9s-9-4.03-9-9 4.03-9 9-9 9 4.03 9 9z" />
                    </svg>
                    {{ session('status') }}
                </div>
                @endif

                @if ($errors->any())
                <div class="status-message status-message--error">
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
                    <h1 class="page-title">My Orders</h1>
                    <p class="page-subtitle">Track and manage your order history</p>
                </div>

                <!-- Info Banner -->
                <div class="info-banner">
                    <div class="info-banner-title">
                        Your Order History
                    </div>
                    <p class="info-banner-text">
                        Track your purchases, view order details, and manage your shopping history. You can monitor order status, cancel pending orders, and confirm deliveries. All your order information is kept secure and easily accessible.
                    </p>
                    <p style="color: #991b1b; font-weight: 600; margin-top: 1rem;">
                        If an order is not marked as delivered after 2 months, it will be automatically marked as delivered.
                    </p>
                </div>

                <!-- NEW: Help Section -->
                <div class="help-section">
                    <h3 class="help-title">
                        Orders Help & Support
                    </h3>
                    <ul class="help-list">
                        <li>You can cancel an order while it is Pending or Processed.</li>
                        <li>Status flow: Pending → Processed → Shipped → Out for Delivery → Delivered.</li>
                        <li>Track items, quantities, and totals from the order details view.</li>
                        <li>Delivery times may vary by location; watch for email/SMS updates.</li>
                        <li>Need changes after placing an order? Contact support as soon as possible.</li>
                    </ul>
                    <a class="support-link">
                        <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
                            <polyline points="22,6 12,13 2,6" />
                        </svg>
                        Contact Order Support
                    </a>
                </div>

                <!-- Livewire My Orders Table Component -->
                @if ($orders->count() > 0)
                <livewire:my-orders-table />
                @endif

                @if ($orders->count() === 0)
                <div class="empty-state">
                    <div class="empty-state__icon">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M16 4h2a2 2 0 012 2v14a2 2 0 01-2 2H6a2 2 0 01-2-2V6a2 2 0 012-2h2" />
                            <rect x="8" y="2" width="8" height="4" rx="1" ry="1" />
                        </svg>
                    </div>
                    <h3 class="empty-state__title">No Orders Yet</h3>
                    <p class="empty-state__description">You haven't placed any orders yet. Start shopping to see your orders here.</p>
                    <a href="{{ route('home') }}" class="empty-state__button">
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

    <!-- Cancel Order Confirmation Modal -->
    <div id="cancelOrderModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-40 hidden px-4">
        <div class="bg-white rounded-[18px] shadow-lg p-6 w-full max-w-sm relative mx-2">
            <button id="closeCancelOrderModal" class="absolute top-2 right-2 text-gray-400 hover:text-gray-600 text-xl">&times;</button>
            <h3 class="text-lg font-semibold mb-4 text-red-600">Cancel Order</h3>
            <p class="mb-6 text-gray-700" id="cancelOrderText">Are you sure you want to cancel this order?</p>
            <div class="flex flex-col sm:flex-row justify-end gap-2">
                <button id="cancelOrderCancelBtn" class="px-4 py-2 bg-gray-200 text-gray-700 rounded-[9px] hover:bg-gray-300 transition w-full sm:w-auto">Cancel</button>
                <button id="confirmCancelOrderBtn" class="px-4 py-2 bg-red-500 text-white rounded-[9px] hover:bg-red-600 transition w-full sm:w-auto">Cancel Order</button>
            </div>
        </div>
    </div>

    <!-- Deliver Order Confirmation Modal -->
    <div id="deliverOrderModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-40 hidden px-4">
        <div class="bg-white rounded-[18px] shadow-lg p-6 w-full max-w-sm relative mx-2">
            <button id="closeDeliverOrderModal" class="absolute top-2 right-2 text-gray-400 hover:text-gray-600 text-xl">&times;</button>
            <h3 class="text-lg font-semibold mb-4 text-green-600">Mark as Delivered</h3>
            <p class="mb-6 text-gray-700" id="deliverOrderText">Are you sure you want to mark this order as delivered?</p>
            <div class="flex flex-col sm:flex-row justify-end gap-2">
                <button id="deliverOrderCancelBtn" class="px-4 py-2 bg-gray-200 text-gray-700 rounded-[9px] hover:bg-gray-300 transition w-full sm:w-auto">Cancel</button>
                <button id="confirmDeliverOrderBtn" class="px-4 py-2 bg-green-500 text-white rounded-[9px] hover:bg-green-600 transition w-full sm:w-auto">Mark Delivered</button>
            </div>
        </div>
    </div>

    <script>
        // Auto-hide status message after 5 seconds
        document.addEventListener('DOMContentLoaded', function() {
            const statusMessage = document.getElementById('status-message');
            if (statusMessage) {
                setTimeout(function() {
                    statusMessage.style.transition = 'opacity 0.5s ease-out';
                    statusMessage.style.opacity = '0';
                    setTimeout(function() {
                        statusMessage.style.display = 'none';
                    }, 500);
                }, 5000);
            }

            // Order action handlers
            let currentOrderId = null;
            let currentOrderNumber = null;

            const cancelModal = document.getElementById('cancelOrderModal');
            const deliverModal = document.getElementById('deliverOrderModal');
            const cancelOrderText = document.getElementById('cancelOrderText');
            const deliverOrderText = document.getElementById('deliverOrderText');

            // Route templates and CSRF cached once
            const cancelTemplate = "{{ route('orders.cancel', ['order' => 'ORDER_ID_PLACEHOLDER']) }}";
            const deliverTemplate = "{{ route('orders.delivered', ['order' => 'ORDER_ID_PLACEHOLDER']) }}";
            const csrfValue = '{{ csrf_token() }}';

            function hideModal(modalEl) {
                modalEl.classList.add('hidden');
                currentOrderId = null;
                currentOrderNumber = null;
            }

            // Cancel order handlers
            function setupCancelOrderHandlers() {
                document.querySelectorAll('.cancel-order-btn').forEach(btn => {
                    btn.addEventListener('click', function() {
                        currentOrderId = this.dataset.orderId;
                        currentOrderNumber = this.dataset.orderNumber;
                        cancelOrderText.textContent = `Are you sure you want to cancel order #${currentOrderNumber}?`;
                        cancelModal.classList.remove('hidden');
                    });
                });
            }

            // Deliver order handlers
            function setupDeliverOrderHandlers() {
                document.querySelectorAll('.deliver-order-btn').forEach(btn => {
                    btn.addEventListener('click', function() {
                        currentOrderId = this.dataset.orderId;
                        currentOrderNumber = this.dataset.orderNumber;
                        deliverOrderText.textContent = `Are you sure you want to mark order #${currentOrderNumber} as delivered?`;
                        deliverModal.classList.remove('hidden');
                    });
                });
            }

            // Initial setup
            setupCancelOrderHandlers();
            setupDeliverOrderHandlers();

            // Re-setup handlers after Livewire navigations
            document.addEventListener('livewire:navigated', function() {
                setupCancelOrderHandlers();
                setupDeliverOrderHandlers();
            });

            // Modal close handlers
            document.getElementById('closeCancelOrderModal').addEventListener('click', function() {
                hideModal(cancelModal);
            });
            document.getElementById('cancelOrderCancelBtn').addEventListener('click', function() {
                hideModal(cancelModal);
            });
            document.getElementById('closeDeliverOrderModal').addEventListener('click', function() {
                hideModal(deliverModal);
            });
            document.getElementById('deliverOrderCancelBtn').addEventListener('click', function() {
                hideModal(deliverModal);
            });

            function submitPost(routeTemplate, id) {
                if (!id) return;

                const form = document.createElement('form');
                form.method = 'POST';
                form.action = routeTemplate.replace('ORDER_ID_PLACEHOLDER', id);

                const csrfToken = document.createElement('input');
                csrfToken.type = 'hidden';
                csrfToken.name = '_token';
                csrfToken.value = csrfValue;
                form.appendChild(csrfToken);

                document.body.appendChild(form);
                form.submit();
            }

            // Confirm actions
            document.getElementById('confirmCancelOrderBtn').addEventListener('click', function() {
                submitPost(cancelTemplate, currentOrderId);
            });

            document.getElementById('confirmDeliverOrderBtn').addEventListener('click', function() {
                submitPost(deliverTemplate, currentOrderId);
            });
        });
    </script>
</body>

</html>