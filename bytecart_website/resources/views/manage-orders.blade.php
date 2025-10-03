@php
use Illuminate\Support\Facades\DB;
use App\Models\Order;

$user = auth()->user();
if (!$user || !in_array('admin', (array)($user->roles ?? []))) {
\Illuminate\Support\Facades\Auth::guard('web')->logout();
\Illuminate\Support\Facades\Session::invalidate();
\Illuminate\Support\Facades\Session::regenerateToken();
header('Location: ' . route('login'));
exit;
}

// Ensure mongodb_orders is configured at runtime
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

// Auto-advance: mark pending orders placed over 1 hour ago as processed (Mongo)
try {
DB::connection('mongodb_orders')
->table('orders') // changed from ->collection('orders')
->where('order_status', 'pending')
->whereNotNull('placed_at')
->where('placed_at', '<=', \Carbon\Carbon::now()->subHour())
    ->update(['order_status' => 'processed']);
    } catch (\Throwable $e) {
    // no-op; optional logging
    }

    // 2) Filters (show ALL users' orders; only apply recognized values)
    $q = trim((string) request('q', ''));
    $status = (string) request('status', '');
    $dateFrom = request('date_from');
    $dateTo = request('date_to');

    $allowedStatuses = ['pending','processed','shipped','out for delivery','delivered','canceled'];

    // Basic YYYY-MM-DD validation
    if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $dateFrom ?? '')) $dateFrom = null;
    if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $dateTo ?? '')) $dateTo = null;

    // 3) Build base query once (Mongo Eloquent)
    $base = Order::query();

    if ($q !== '') {
    $base->where(function($w) use ($q) {
    $w->where('order_number', 'like', '%'.$q.'%')
    ->orWhere('customer_name', 'like', '%'.$q.'%')
    ->orWhere('customer_email', 'like', '%'.$q.'%')
    ->orWhere('customer_phone', 'like', '%'.$q.'%');
    if (ctype_digit($q)) {
    $w->orWhere('user_id', (int)$q);
    }
    });
    }
    if (in_array($status, $allowedStatuses, true)) {
    $base->where('order_status', $status);
    }
    if ($dateFrom) {
    $from = \Carbon\Carbon::parse($dateFrom)->startOfDay();
    $base->where(function($q) use ($from) {
    $q->where('placed_at', '>=', $from)
    ->orWhere('created_at', '>=', $from);
    });
    }
    if ($dateTo) {
    $to = \Carbon\Carbon::parse($dateTo)->endOfDay();
    $base->where(function($q) use ($to) {
    $q->where('placed_at', '<=', $to)
        ->orWhere('created_at', '<=', $to);
            });
            }

            // 4) Debug info BEFORE pagination
            $debugSql=null; $debugBindings=null; $preCount=null;
            if (config('app.debug')) {
            $debugSql='mongo: orders query' ;
            $debugBindings=[];
            try { $preCount=(clone $base)->count(); } catch (\Throwable $e) { $preCount = 'ERR: '.$e->getMessage(); }
            }

            // 5) Paginate using a CLONE of the filtered query (order by placed_at/created_at)
            $orders = (clone $base)
            ->orderByDesc('placed_at')
            ->orderByDesc('created_at')
            ->paginate(20)
            ->withQueryString();

            // 6) Preload order_items for the current page from Mongo
            $mongo = DB::connection('mongodb_orders');
            // Use order_number to avoid ObjectId type mismatches
            $orderNumbers = $orders->pluck('order_number')->filter()->values()->all();
            $itemsByOrder = collect();
            if ($orderNumbers) {
            $items = $mongo->table('order_items')
            ->whereIn('order_number', $orderNumbers)
            ->get();
            $itemsByOrder = collect($items)
            ->map(fn($d) => (object)$d)
            ->groupBy('order_number');
            }

            // UI helper
            $badgeClass = function ($val, $okStates = [], $warn = null, $bad = null) {
            if (in_array($val, $okStates, true)) return 'bg-green-100 text-green-700';
            if ($val === $warn) return 'bg-yellow-100 text-yellow-800';
            if ($val === $bad) return 'bg-red-100 text-red-700';
            return 'bg-gray-100 text-gray-700';
            };
            @endphp

            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <meta name="csrf-token" content="{{ csrf_token() }}">
                <title>ByteCart - Admin | Manage Orders</title>
                <link rel="icon" type="image/x-icon" href="{{ asset('logo/x-icon.webp') }}">
                @vite(['resources/css/app.css', 'resources/js/app.js'])
                <style>
                    /* Pagination styles (aligned with shop/manage-admins) */
                    .pager-container {
                        display: flex;
                        justify-content: center;
                        margin: 0;
                        padding: 0;
                    }

                    .pager-wrap {
                        display: flex;
                        align-items: center;
                        justify-content: space-between;
                        gap: 0.75rem;
                        /* bg/rounded/shadow are applied via Tailwind on the element */
                        padding: 14px 18px;
                        width: 100%;
                        max-width: none;
                        margin: 0;
                    }

                    .pager {
                        display: flex;
                        align-items: center;
                        gap: 6px;
                        flex-wrap: wrap;
                        justify-content: center;
                    }

                    .pager-info {
                        color: #475569;
                        font-weight: 600;
                        font-size: 0.9rem;
                        line-height: 1;
                        white-space: nowrap;
                        flex: 0 0 auto;
                        padding: 0 4px;
                    }

                    .pager a,
                    .pager span.pager-btn {
                        display: inline-flex;
                        align-items: center;
                        justify-content: center;
                        width: 36px;
                        height: 36px;
                        border-radius: 50%;
                        border: 1px solid #e5e7eb;
                        background: #fff;
                        color: #334155;
                        font-weight: 600;
                        text-decoration: none;
                        transition: all .2s ease;
                        font-size: 0.875rem;
                        line-height: 1;
                        flex-shrink: 0;
                    }

                    .pager a:hover:not(.disabled) {
                        border-color: #3b82f6;
                        background: #eff6ff;
                        color: #3b82f6;
                        transform: translateY(-1px);
                    }

                    .pager .active {
                        background: #3b82f6 !important;
                        border-color: #3b82f6 !important;
                        color: #fff !important;
                        box-shadow: 0 2px 8px rgba(59, 130, 246, 0.3);
                    }

                    .pager .disabled {
                        opacity: 0.4;
                        pointer-events: none;
                        cursor: not-allowed;
                    }

                    .pager-ellipsis {
                        width: 36px;
                        height: 36px;
                        display: inline-flex;
                        align-items: center;
                        justify-content: center;
                        color: #94a3b8;
                        font-weight: 700;
                        font-size: 0.875rem;
                        flex-shrink: 0;
                    }

                    @media (max-width: 640px) {
                        .pager-wrap {
                            flex-direction: column;
                            padding: 18px;
                        }

                        .pager {
                            order: 2;
                            gap: 4px;
                        }

                        .pager-info {
                            order: 1;
                            text-align: center;
                            font-size: 0.875rem;
                            margin-bottom: 10px;
                        }
                    }

                    @media (max-width: 480px) {
                        .pager {
                            gap: 2px;
                        }

                        .pager a,
                        .pager span.pager-btn,
                        .pager-ellipsis {
                            width: 30px;
                            height: 30px;
                            font-size: 0.75rem;
                        }
                    }
                </style>
            </head>

            <x-app-layout>
                <x-slot name="header">
                    <h2 class="font-semibold text-xl text-gray-800 leading-tight">
                        {{ __('Manage Orders') }}
                    </h2>
                </x-slot>

                <div class="w-full mx-auto pb-5 pt-5 px-4 sm:px-16 sm:pb-10 sm:pt-10">
                    @if (session('status'))
                    <div id="status-message" class="mb-4 p-3 rounded-[18px] bg-green-50 text-green-700 border border-green-200">
                        {{ session('status') }}
                    </div>
                    @endif
                    @if ($errors->any())
                    <div id="error-messages" class="mb-4 p-3 rounded-[18px] bg-red-50 text-red-700 border border-red-200">
                        <ul class="list-disc ml-6">
                            @foreach ($errors->all() as $error)
                            <li class="text-sm">{{ $error }}</li>
                            @endforeach
                        </ul>
                    </div>
                    @endif

                    <div class="bg-white rounded-[18px] p-6 mb-8" style="box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);">
                        <form method="GET" id="ordersFilterForm">
                            @csrf
                            <div class="flex items-center justify-between mb-4">
                                <h3 class="text-lg font-semibold text-gray-900">Filter Orders</h3>
                                <div class="hidden md:flex items-center gap-2">
                                    <!-- Apply Filters button removed (auto-apply enabled) -->
                                    <a href="{{ url()->current() }}" class="inline-flex items-center px-4 py-2 border border-gray-300 text-gray-700 font-medium rounded-[9px] hover:bg-gray-50 transition-colors">
                                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                                        </svg>
                                        Reset
                                    </a>
                                </div>
                            </div>

                            <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
                                <div class="space-y-2">
                                    <label for="search" class="block text-sm font-medium text-gray-700">
                                        Search Orders
                                    </label>
                                    <div class="relative">
                                        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                                            </svg>
                                        </div>
                                        <input
                                            type="text"
                                            id="search"
                                            name="q"
                                            value="{{ $q }}"
                                            class="block w-full pl-10 pr-3 py-2.5 border border-gray-300 rounded-[9px] focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                                            placeholder="Order #, customer name, email, phone...">
                                    </div>
                                    <p class="text-xs text-gray-500">Search by order number, customer details, or user ID</p>
                                </div>

                                <div class="space-y-2">
                                    <label for="status" class="block text-sm font-medium text-gray-700">
                                        Order Status
                                    </label>
                                    <select
                                        id="status"
                                        name="status"
                                        class="block w-full px-3 py-2.5 border border-gray-300 rounded-[9px] focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors">
                                        @php $statuses = ['', 'pending','processed','shipped','out for delivery','delivered','canceled']; @endphp
                                        @foreach ($statuses as $s)
                                        <option value="{{ $s }}" {{ $status===$s ? 'selected' : '' }}>
                                            {{ $s==='' ? 'All Statuses' : ucwords($s) }}
                                        </option>
                                        @endforeach
                                    </select>
                                    <p class="text-xs text-gray-500">Filter orders by their current status</p>
                                </div>

                                <div class="space-y-2">
                                    <label for="date_from" class="block text-sm font-medium text-gray-700">
                                        Date From
                                    </label>
                                    <input
                                        type="date"
                                        id="date_from"
                                        name="date_from"
                                        value="{{ $dateFrom }}"
                                        class="block w-full px-3 py-2.5 border border-gray-300 rounded-[9px] focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors">
                                    <p class="text-xs text-gray-500">Start date (placed or created)</p>
                                </div>

                                <div class="space-y-2">
                                    <label for="date_to" class="block text-sm font-medium text-gray-700">
                                        Date To
                                    </label>
                                    <input
                                        type="date"
                                        id="date_to"
                                        name="date_to"
                                        value="{{ $dateTo }}"
                                        class="block w-full px-3 py-2.5 border border-gray-300 rounded-[9px] focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors">
                                    <p class="text-xs text-gray-500">End date (inclusive)</p>
                                </div>
                            </div>

                            <!-- Mobile buttons -->
                            <div class="md:hidden flex gap-3">
                                <!-- Apply Filters button removed (auto-apply enabled) -->
                                <a href="{{ url()->current() }}" class="flex-1 inline-flex items-center justify-center px-4 py-2.5 border border-gray-300 text-gray-700 font-medium rounded-[9px] hover:bg-gray-50 transition-colors">
                                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                                    </svg>
                                    Reset
                                </a>
                            </div>
                        </form>
                    </div>

                    @php
                    // Pager helpers from paginator ($orders already paginated at 20 per page)
                    $showingFrom = $orders->firstItem() ?? 0;
                    $showingTo = $orders->lastItem() ?? 0;
                    $totalItems = $orders->total();
                    $pageUrl = function(int $page) { return request()->fullUrlWithQuery(['page' => $page]); };
                    $pages = [];
                    $last = $orders->lastPage();
                    $current = $orders->currentPage();
                    if ($last <= 7) {
                        $pages=range(1, $last);
                        } else {
                        $pages=[1, 2];
                        if ($current> 4) $pages[] = '...';
                        if ($current > 2 && $current < $last - 1) {
                            if ($current> 3) $pages[] = $current - 1;
                            $pages[] = $current;
                            if ($current < $last - 2) $pages[]=$current + 1;
                                } elseif ($current===3) {
                                $pages[]=3;
                                }
                                if ($current < $last - 3) $pages[]='...' ;
                                if (!in_array($last, $pages)) $pages[]=$last;
                                $seen=[];
                                $pages=array_values(array_filter($pages, function($p) use (&$seen) {
                                $k=is_int($p) ? "n$p" : "e$p" ;
                                if (isset($seen[$k])) return false;
                                $seen[$k]=true;
                                return true;
                                }));
                                }
                                @endphp

                                @php
                                $pageIsEmpty=$orders->count() === 0;
                                $thereAreRows = $connDiagnostics[0]['orders_count'] ?? 0;
                                @endphp

                                @if($pageIsEmpty && ($preCount ?? 0) > 0)
                                <div class="bg-yellow-50 border border-yellow-200 rounded-[18px] p-4 mb-4">
                                    <div class="text-yellow-700">
                                        Filters matched {{ $preCount }} orders, but this page has no rows to display.
                                        Try clicking Reset, or go to page 1.
                                        <a href="{{ url()->current() }}" class="underline ml-2">Reset filters</a>
                                    </div>
                                </div>
                                @endif

                                <!-- Desktop Table View (hidden on mobile) -->
                                <div class="hidden lg:block bg-white rounded-[18px] lg:overflow-visible overflow-hidden" style="box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);">
                                    <div class="overflow-x-auto lg:overflow-visible lg:overflow-x-visible lg:overflow-y-visible">
                                        <table class="min-w-full divide-y divide-gray-200">
                                            <thead class="bg-gray-50">
                                                <tr class="text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                                    <th class="px-6 py-4">Order #</th>
                                                    <th class="px-6 py-4">Customer</th>
                                                    <th class="px-6 py-4">Items</th>
                                                    <th class="px-6 py-4">Total</th>
                                                    <th class="px-6 py-4">Payment</th>
                                                    <th class="px-6 py-4">Status</th>
                                                    <th class="px-6 py-4">Date</th>
                                                    <th class="px-6 py-4">Actions</th>
                                                </tr>
                                            </thead>
                                            <tbody class="bg-white divide-y divide-gray-100">
                                                @forelse ($orders as $order)
                                                @php
                                                // Use preloaded items grouped by order_number
                                                $itemGroup = $itemsByOrder->get($order->order_number, collect());
                                                $itemsCount = $itemGroup->count();
                                                $os = $order->order_status ?? 'pending';
                                                $osClass = $badgeClass($os, ['processed','shipped','out for delivery','delivered'], 'pending', 'canceled');
                                                $oid = (string)($order->_id ?? $order->id);
                                                $rowId = 'details_'.$oid;
                                                @endphp
                                                <tr class="hover:bg-gray-50">
                                                    <td class="px-6 py-4">
                                                        <div class="font-semibold text-gray-900">{{ $order->order_number }}</div>
                                                        <div class="text-xs text-gray-500">User ID: {{ $order->user_id }}</div>
                                                    </td>
                                                    <td class="px-6 py-4">
                                                        <div class="text-gray-900 font-medium">{{ $order->customer_name ?? '—' }}</div>
                                                        <div class="text-gray-500 text-sm">{{ $order->customer_email ?? '' }}</div>
                                                        @if($order->customer_phone)
                                                        <div class="text-gray-500 text-sm">{{ $order->customer_phone }}</div>
                                                        @endif
                                                    </td>
                                                    <td class="px-6 py-4 w-32">
                                                        <div class="text-gray-700 text-sm">
                                                            {{ $itemsCount }} {{ $itemsCount === 1 ? 'item' : 'items' }}
                                                        </div>
                                                    </td>
                                                    <td class="px-6 py-4">
                                                        <div class="text-lg font-semibold text-gray-900">${{ number_format((float)($order->total ?? 0), 2) }}</div>
                                                    </td>
                                                    <td class="px-6 py-4">
                                                        <div class="text-gray-700 text-sm">{{ $order->payment_method ?? '—' }}</div>
                                                    </td>
                                                    <td class="px-6 py-4">
                                                        <span class="inline-flex px-2 py-1 rounded-full text-xs font-semibold {{ $osClass }}">
                                                            {{ ucwords($os) }}
                                                        </span>
                                                    </td>
                                                    <td class="px-6 py-4 text-gray-700 text-sm w-40">
                                                        {{ !empty($order->placed_at) ? \Carbon\Carbon::parse($order->placed_at)->format('M j, Y') : \Carbon\Carbon::parse($order->created_at)->format('M j, Y') }}
                                                        <div class="text-xs text-gray-500">
                                                            {{ !empty($order->placed_at) ? \Carbon\Carbon::parse($order->placed_at)->format('H:i') : \Carbon\Carbon::parse($order->created_at)->format('H:i') }}
                                                        </div>
                                                    </td>
                                                    <td class="px-6 py-4">
                                                        <div class="flex items-center gap-2">
                                                            <button class="inline-flex items-center px-3 py-2 border border-gray-300 rounded-[9px] bg-white hover:bg-gray-50 text-sm font-medium" onclick="toggleAdminDetails('{{ $rowId }}')">
                                                                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                                                </svg>
                                                                View
                                                            </button>
                                                            @if(!in_array($os, ['delivered','canceled']))
                                                            <div class="relative lg:z-10 lg:overflow-visible">
                                                                <button class="inline-flex items-center px-3 py-2 border border-gray-300 rounded-[9px] bg-white hover:bg-gray-50 text-sm font-medium dropdown-toggle" onclick="toggleDropdown('dropdown-{{ $order->id }}')">
                                                                    Actions
                                                                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 ml-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                                                                    </svg>
                                                                </button>
                                                                <div id="dropdown-{{ $order->id }}" class="absolute right-0 bottom-full mb-1 w-40 bg-white rounded-[9px] shadow-lg border border-gray-200 hidden z-[9999]">
                                                                    <div class="py-1">
                                                                        {{-- Only allow forward transitions --}}
                                                                        @if(in_array($os, ['pending','processed']))
                                                                        <form method="POST" action="{{ route('admin.orders.updateStatus', $oid) }}" class="block">
                                                                            @csrf
                                                                            <input type="hidden" name="status" value="shipped">
                                                                            <button type="button" class="w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 admin-action-btn"
                                                                                data-action="shipped" data-order-number="{{ $order->order_number }}">
                                                                                Mark as Shipped
                                                                            </button>
                                                                        </form>
                                                                        @endif

                                                                        @if($os === 'shipped')
                                                                        <form method="POST" action="{{ route('admin.orders.updateStatus', $oid) }}" class="block">
                                                                            @csrf
                                                                            <input type="hidden" name="status" value="out for delivery">
                                                                            <button type="button" class="w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 admin-action-btn"
                                                                                data-action="out for delivery" data-order-number="{{ $order->order_number }}">
                                                                                Out for Delivery
                                                                            </button>
                                                                        </form>
                                                                        @endif

                                                                        @if($os === 'out for delivery')
                                                                        <form method="POST" action="{{ route('admin.orders.updateStatus', $oid) }}" class="block">
                                                                            @csrf
                                                                            <input type="hidden" name="status" value="delivered">
                                                                            <button type="button" class="w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 admin-action-btn"
                                                                                data-action="delivered" data-order-number="{{ $order->order_number }}">
                                                                                Mark as Delivered
                                                                            </button>
                                                                        </form>
                                                                        @endif

                                                                        @if(!in_array($os, ['delivered','canceled']))
                                                                        <hr class="my-1">
                                                                        <form method="POST" action="{{ route('admin.orders.updateStatus', $oid) }}" class="block">
                                                                            @csrf
                                                                            <input type="hidden" name="status" value="canceled">
                                                                            <button type="button" class="w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-red-50 admin-action-btn"
                                                                                data-action="canceled" data-order-number="{{ $order->order_number }}">
                                                                                Cancel Order
                                                                            </button>
                                                                        </form>
                                                                        @endif
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            @endif
                                                        </div>
                                                    </td>
                                                </tr>
                                                <tr id="{{ $rowId }}" class="hidden">
                                                    <td colspan="8" class="px-6 py-6 bg-gray-50">
                                                        <div class="grid lg:grid-cols-2 gap-6">
                                                            <div class="bg-white rounded-[18px] p-4 border border-gray-300">
                                                                <div class="font-semibold text-gray-900 mb-3">Order Items</div>
                                                                <div class="space-y-3">
                                                                    @foreach($itemGroup as $it)
                                                                    <div class="flex items-center gap-3 p-3 bg-gray-50 rounded-[9px]">
                                                                        <div class="w-12 h-12 rounded-[4.5px] bg-white flex items-center justify-center overflow-hidden border">
                                                                            @if(!empty($it->image))
                                                                            <img src="{{ asset($it->image) }}" alt="" class="max-w-full max-h-full object-contain">
                                                                            @else
                                                                            <span class="text-gray-400 text-xs">No image</span>
                                                                            @endif
                                                                        </div>
                                                                        <div class="flex-1">
                                                                            <div class="font-medium text-gray-900">{{ $it->product_name }}</div>
                                                                            <div class="text-gray-500 text-sm">
                                                                                @if(!empty($it->model_name)) Model: {{ $it->model_name }} @endif
                                                                                @if(!empty($it->color)) @if(!empty($it->model_name)) | @endif Color: {{ $it->color }} @endif
                                                                            </div>
                                                                        </div>
                                                                        <div class="text-right">
                                                                            <div class="text-gray-700 text-sm">Qty: {{ (int)($it->qty ?? 0) }}</div>
                                                                            <div class="text-gray-900 font-semibold">${{ number_format((float)($it->line_total ?? 0), 2) }}</div>
                                                                        </div>
                                                                    </div>
                                                                    @endforeach
                                                                </div>
                                                            </div>

                                                            <div class="space-y-4">
                                                                <div class="bg-white rounded-[18px] p-4 border border-gray-300">
                                                                    <div class="font-semibold text-gray-900 mb-3">Order Summary</div>
                                                                    <div class="space-y-2">
                                                                        <div class="flex justify-between text-gray-700">
                                                                            <span>Subtotal</span>
                                                                            <span>${{ number_format((float)($order->subtotal ?? 0), 2) }}</span>
                                                                        </div>
                                                                        <div class="flex justify-between text-gray-700">
                                                                            <span>Shipping</span>
                                                                            <span>${{ number_format((float)($order->shipping_fee ?? 0), 2) }}</span>
                                                                        </div>
                                                                        <div class="flex justify-between text-gray-700">
                                                                            <span>Tax</span>
                                                                            <span>${{ number_format((float)($order->tax ?? 0), 2) }}</span>
                                                                        </div>
                                                                        <hr class="my-2">
                                                                        <div class="flex justify-between font-semibold text-lg">
                                                                            <span>Total</span>
                                                                            <span>${{ number_format((float)($order->total ?? 0), 2) }}</span>
                                                                        </div>
                                                                    </div>
                                                                </div>

                                                                <div class="bg-white rounded-[18px] p-4 border border-gray-300">
                                                                    <div class="font-semibold text-gray-900 mb-3">Addresses</div>
                                                                    <div class="grid md:grid-cols-2 gap-4">
                                                                        <div>
                                                                            <div class="font-medium mb-1 text-gray-700">Shipping</div>
                                                                            <div class="text-gray-600 text-sm">
                                                                                {{ $order->shipping_street_address }}{{ !empty($order->shipping_apartment_suite) ? ', '.$order->shipping_apartment_suite : '' }}<br>
                                                                                {{ $order->shipping_city }}, {{ $order->shipping_district }} {{ $order->shipping_zip_code }}
                                                                            </div>
                                                                        </div>
                                                                        <div>
                                                                            <div class="font-medium mb-1 text-gray-700">Billing</div>
                                                                            <div class="text-gray-600 text-sm">
                                                                                {{ $order->billing_street_address }}{{ !empty($order->billing_apartment_suite) ? ', '.$order->billing_apartment_suite : '' }}<br>
                                                                                {{ $order->billing_city }}, {{ $order->billing_district }} {{ $order->billing_zip_code }}
                                                                            </div>
                                                                        </div>
                                                                    </div>
                                                                </div>

                                                                @if(!empty($order->notes))
                                                                <div class="bg-white rounded-[18px] p-4 border border-gray-300">
                                                                    <div class="font-semibold text-gray-900 mb-2">Order Notes</div>
                                                                    <div class="text-gray-700 text-sm">{{ $order->notes }}</div>
                                                                </div>
                                                                @endif
                                                            </div>
                                                        </div>
                                                    </td>
                                                </tr>
                                                @empty
                                                <tr>
                                                    <td colspan="8" class="px-6 py-12 text-center">
                                                        <div class="text-gray-500">
                                                            <div class="text-lg font-medium mb-2">No orders found</div>
                                                            <a href="{{ url()->current() }}" class="text-blue-600 hover:text-blue-700 underline">Reset filters</a>
                                                        </div>
                                                    </td>
                                                </tr>
                                                @endforelse
                                            </tbody>
                                        </table>
                                    </div>
                                </div>

                                {{-- Pagination (desktop only) --}}
                                @if($orders->lastPage() > 1)
                                <div class="hidden lg:block">
                                    <div class="pager-container mt-6">
                                        <div class="pager-wrap w-full bg-white shadow-[0_4px_24px_0_rgba(30,41,59,0.13)] rounded-[18px] overflow-hidden">
                                            <div class="pager-info">Showing {{ $showingFrom }}–{{ $showingTo }} Out Of {{ $totalItems }}</div>
                                            <div class="pager">
                                                <a href="{{ $pageUrl(1) }}" class="pager-btn {{ $orders->onFirstPage() ? 'disabled' : '' }}" aria-label="First page">«</a>
                                                <a href="{{ $orders->previousPageUrl() ?: $pageUrl(1) }}" class="pager-btn {{ $orders->onFirstPage() ? 'disabled' : '' }}" aria-label="Previous page">‹</a>
                                                @foreach($pages as $p)
                                                @if($p === '...')
                                                <span class="pager-ellipsis">…</span>
                                                @else
                                                @if($p == $orders->currentPage())
                                                <span class="pager-btn active">{{ $p }}</span>
                                                @else
                                                <a href="{{ $pageUrl($p) }}" class="pager-btn">{{ $p }}</a>
                                                @endif
                                                @endif
                                                @endforeach
                                                <a href="{{ $orders->nextPageUrl() ?: $pageUrl($orders->lastPage()) }}" class="pager-btn {{ $orders->currentPage() == $orders->lastPage() ? 'disabled' : '' }}" aria-label="Next page">›</a>
                                                <a href="{{ $pageUrl($orders->lastPage()) }}" class="pager-btn {{ $orders->currentPage() == $orders->lastPage() ? 'disabled' : '' }}" aria-label="Last page">»</a>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                @endif

                                <!-- Mobile Card View (visible on mobile) -->
                                <div class="lg:hidden space-y-4">
                                    @forelse ($orders as $order)
                                    @php
                                    $itemGroup = $itemsByOrder->get($order->order_number, collect());
                                    $itemsCount = $itemGroup->count();
                                    $os = $order->order_status ?? 'pending';
                                    $osClass = $badgeClass($os, ['processed','shipped','out for delivery','delivered'], 'pending', 'canceled');
                                    $oid = (string)($order->_id ?? $order->id);
                                    $rowId = 'mobile_details_'.$oid;
                                    @endphp
                                    <div class="bg-white shadow rounded-[18px] border border-gray-200" style="box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);">
                                        <div class="p-4">
                                            <div class="flex items-start justify-between mb-3">
                                                <div>
                                                    <div class="font-semibold text-gray-900">{{ $order->order_number }}</div>
                                                    <div class="text-sm text-gray-500">{{ $order->customer_name ?? '—' }}</div>
                                                </div>
                                                <div class="text-right">
                                                    <div class="text-lg font-semibold text-gray-900">${{ number_format((float)($order->total ?? 0), 2) }}</div>
                                                    <div class="text-sm text-gray-500">
                                                        {{ !empty($order->placed_at) ? \Carbon\Carbon::parse($order->placed_at)->format('M j, Y') : \Carbon\Carbon::parse($order->created_at)->format('M j, Y') }}
                                                    </div>
                                                </div>
                                            </div>

                                            <div class="flex items-center gap-2 mb-3">
                                                <span class="inline-flex px-2 py-1 rounded-full text-xs font-semibold {{ $osClass }}">
                                                    {{ ucwords($os) }}
                                                </span>
                                                @if($order->payment_method)
                                                <span class="inline-flex px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-700">
                                                    {{ $order->payment_method }}
                                                </span>
                                                @endif
                                                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                                                    {{ $itemsCount }} {{ $itemsCount === 1 ? 'item' : 'items' }}
                                                </span>
                                            </div>

                                            <div class="flex items-center gap-2">
                                                <button class="w-full inline-flex items-center justify-center px-3 py-2 border border-gray-300 rounded-[9px] bg-white hover:bg-gray-50 text-sm font-medium" onclick="toggleAdminDetails('{{ $rowId }}')">
                                                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 616 0z" />
                                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                                    </svg>
                                                    View Details
                                                </button>
                                            </div>
                                        </div>

                                        <div id="{{ $rowId }}" class="hidden border-t border-gray-200 p-4 bg-gray-50">
                                            <div class="space-y-4">
                                                <div>
                                                    <div class="font-semibold text-gray-900 mb-2">Contact</div>
                                                    <div class="text-sm text-gray-600">
                                                        @if($order->customer_email)
                                                        <div>{{ $order->customer_email }}</div>
                                                        @endif
                                                        @if($order->customer_phone)
                                                        <div>{{ $order->customer_phone }}</div>
                                                        @endif
                                                        <div class="text-xs mt-1">User ID: {{ $order->user_id }}</div>
                                                    </div>
                                                </div>

                                                <div>
                                                    <div class="font-semibold text-gray-900 mb-2">Items</div>
                                                    <div class="space-y-2">
                                                        @foreach($itemGroup as $it)
                                                        <div class="flex items-center gap-3 p-2 bg-white rounded-[9px] border">
                                                            <div class="w-10 h-10 rounded-[4.5px] bg-gray-100 flex items-center justify-center overflow-hidden">
                                                                @if(!empty($it->image))
                                                                <img src="{{ asset($it->image) }}" alt="" class="max-w-full max-h-full object-contain">
                                                                @else
                                                                <span class="text-gray-400 text-xs">No img</span>
                                                                @endif
                                                            </div>
                                                            <div class="flex-1 min-w-0">
                                                                <div class="font-medium text-gray-900 text-sm truncate">{{ $it->product_name }}</div>
                                                                <div class="text-gray-500 text-xs">
                                                                    Qty: {{ (int)($it->qty ?? 0) }} • ${{ number_format((float)($it->line_total ?? 0), 2) }}
                                                                </div>
                                                            </div>
                                                        </div>
                                                        @endforeach
                                                    </div>
                                                </div>

                                                @if(!in_array($os, ['delivered','canceled']))
                                                <div>
                                                    <div class="font-semibold text-gray-900 mb-2">Quick Actions</div>
                                                    <div class="space-y-2">
                                                        <div class="flex gap-2">
                                                            @if(in_array($os, ['pending','processed']))
                                                            <form method="POST" action="{{ route('admin.orders.updateStatus', $oid) }}" class="flex-1">
                                                                @csrf
                                                                <input type="hidden" name="status" value="shipped">
                                                                <button type="button" class="w-full px-3 py-2 border border-gray-300 rounded-[9px] bg-white hover:bg-gray-50 text-sm admin-action-btn"
                                                                    data-action="shipped" data-order-number="{{ $order->order_number }}">
                                                                    Mark Shipped
                                                                </button>
                                                            </form>
                                                            @endif
                                                            @if($os === 'shipped')
                                                            <form method="POST" action="{{ route('admin.orders.updateStatus', $oid) }}" class="flex-1">
                                                                @csrf
                                                                <input type="hidden" name="status" value="out for delivery">
                                                                <button type="button" class="w-full px-3 py-2 border border-gray-300 rounded-[9px] bg-white hover:bg-gray-50 text-sm admin-action-btn"
                                                                    data-action="out for delivery" data-order-number="{{ $order->order_number }}">
                                                                    Out for Delivery
                                                                </button>
                                                            </form>
                                                            @endif
                                                        </div>
                                                        <div class="flex gap-2">
                                                            @if($os === 'out for delivery')
                                                            <form method="POST" action="{{ route('admin.orders.updateStatus', $oid) }}" class="flex-1">
                                                                @csrf
                                                                <input type="hidden" name="status" value="delivered">
                                                                <button type="button" class="w-full px-3 py-2 border border-gray-300 rounded-[9px] bg-white hover:bg-gray-50 text-sm admin-action-btn"
                                                                    data-action="delivered" data-order-number="{{ $order->order_number }}">
                                                                    Mark as Delivered
                                                                </button>
                                                            </form>
                                                            @endif
                                                            @if(!in_array($os, ['delivered','canceled']))
                                                            <form method="POST" action="{{ route('admin.orders.updateStatus', $oid) }}" class="flex-1">
                                                                @csrf
                                                                <input type="hidden" name="status" value="canceled">
                                                                <button type="button" class="w-full px-3 py-2 border border-red-300 rounded-[9px] bg-red-50 hover:bg-red-100 text-red-600 text-sm admin-action-btn"
                                                                    data-action="canceled" data-order-number="{{ $order->order_number }}">
                                                                    Cancel Order
                                                                </button>
                                                            </form>
                                                            @endif
                                                        </div>
                                                    </div>
                                                </div>
                                                @endif
                                            </div>
                                        </div>
                                    </div>
                                    @empty
                                    <div class="bg-white rounded-[18px] p-8 text-center" style="box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);">
                                        <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 mx-auto mb-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2M4 13h2m13-4h-2m-5 4h2m0 0V9m0 4v2" />
                                        </svg>
                                        <div class="text-lg font-medium text-gray-900 mb-2">No orders found</div>
                                        <div class="text-gray-500 mb-4">Try adjusting your filters or search terms</div>
                                        <a href="{{ url()->current() }}" class="text-blue-600 hover:text-blue-700 underline">Reset filters</a>
                                    </div>
                                    @endforelse
                                </div>

                                {{-- Pagination (mobile only) --}}
                                @if($orders->lastPage() > 1)
                                <div class="pager-container mt-6 lg:hidden">
                                    <div class="pager-wrap w-full bg-white shadow-[0_4px_24px_0_rgba(30,41,59,0.13)] rounded-[18px] overflow-hidden">
                                        <div class="pager-info">Showing {{ $showingFrom }}–{{ $showingTo }} Out Of {{ $totalItems }}</div>
                                        <div class="pager">
                                            <a href="{{ $pageUrl(1) }}" class="pager-btn {{ $orders->onFirstPage() ? 'disabled' : '' }}" aria-label="First page">«</a>
                                            <a href="{{ $orders->previousPageUrl() ?: $pageUrl(1) }}" class="pager-btn {{ $orders->onFirstPage() ? 'disabled' : '' }}" aria-label="Previous page">‹</a>
                                            @foreach($pages as $p)
                                            @if($p === '...')
                                            <span class="pager-ellipsis">…</span>
                                            @else
                                            @if($p == $orders->currentPage())
                                            <span class="pager-btn active">{{ $p }}</span>
                                            @else
                                            <a href="{{ $pageUrl($p) }}" class="pager-btn">{{ $p }}</a>
                                            @endif
                                            @endif
                                            @endforeach
                                            <a href="{{ $orders->nextPageUrl() ?: $pageUrl($orders->lastPage()) }}" class="pager-btn {{ $orders->currentPage() == $orders->lastPage() ? 'disabled' : '' }}" aria-label="Next page">›</a>
                                            <a href="{{ $pageUrl($orders->lastPage()) }}" class="pager-btn {{ $orders->currentPage() == $orders->lastPage() ? 'disabled' : '' }}" aria-label="Last page">»</a>
                                        </div>
                                    </div>
                                </div>
                                @endif
                </div>

                <!-- Admin action confirmation modal -->
                <div id="adminActionModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-40 hidden px-4">
                    <div class="bg-white rounded-[18px] shadow-lg p-6 w-full max-w-sm relative mx-2">
                        <button id="closeAdminActionModal" class="absolute top-2 right-2 text-gray-400 hover:text-gray-600 text-xl">&times;</button>
                        <h3 id="adminActionTitle" class="text-lg font-semibold mb-4 text-gray-900">Confirm Action</h3>
                        <p id="adminActionText" class="mb-6 text-gray-700">Are you sure?</p>
                        <div class="flex flex-col sm:flex-row justify-end gap-2">
                            <button id="adminActionCancelBtn" class="px-4 py-2 bg-gray-200 text-gray-700 rounded-[9px] hover:bg-gray-300 transition w-full sm:w-auto">Cancel</button>
                            <button id="adminActionConfirmBtn" class="px-4 py-2 bg-blue-600 text-white rounded-[9px] hover:bg-blue-700 transition w-full sm:w-auto">Confirm</button>
                        </div>
                    </div>
                </div>

                <script>
                    function toggleAdminDetails(id) {
                        const row = document.getElementById(id);
                        if (!row) return;
                        row.classList.toggle('hidden');
                    }

                    function toggleDropdown(id) {
                        // Close all other dropdowns first
                        document.querySelectorAll('[id^="dropdown-"]').forEach(dropdown => {
                            if (dropdown.id !== id) {
                                dropdown.classList.add('hidden');
                            }
                        });

                        // Toggle the clicked dropdown
                        const dropdown = document.getElementById(id);
                        if (dropdown) {
                            dropdown.classList.toggle('hidden');
                        }
                    }

                    // Close dropdowns when clicking outside
                    document.addEventListener('click', function(event) {
                        if (!event.target.closest('.dropdown-toggle')) {
                            document.querySelectorAll('[id^="dropdown-"]').forEach(dropdown => {
                                dropdown.classList.add('hidden');
                            });
                        }
                    });

                    document.addEventListener('DOMContentLoaded', function() {
                        const statusBox = document.getElementById('status-message');
                        const errorBox = document.getElementById('error-messages');
                        [statusBox, errorBox].forEach(function(box) {
                            if (box) {
                                setTimeout(function() {
                                    box.style.transition = 'opacity 0.5s ease-out';
                                    box.style.opacity = '0';
                                    setTimeout(function() {
                                        box.style.display = 'none';
                                    }, 500);
                                }, 5000);
                            }
                        });
                    });

                    // Modal wiring for admin actions
                    document.addEventListener('DOMContentLoaded', function() {
                        let currentActionForm = null;
                        let currentAction = null;
                        let currentOrderNumber = null;

                        const modal = document.getElementById('adminActionModal');
                        const titleEl = document.getElementById('adminActionTitle');
                        const textEl = document.getElementById('adminActionText');
                        const btnClose = document.getElementById('closeAdminActionModal');
                        const btnCancel = document.getElementById('adminActionCancelBtn');
                        const btnConfirm = document.getElementById('adminActionConfirmBtn');

                        function setConfirmStyle(action) {
                            // Reset to default
                            btnConfirm.className = 'px-4 py-2 rounded transition w-full sm:w-auto text-white';
                            // Style by action
                            if (action === 'canceled') {
                                btnConfirm.classList.add('bg-red-500', 'hover:bg-red-600');
                            } else if (action === 'delivered') {
                                btnConfirm.classList.add('bg-green-600', 'hover:bg-green-700');
                            } else if (action === 'out for delivery') {
                                btnConfirm.classList.add('bg-amber-500', 'hover:bg-amber-600');
                            } else { // shipped or default
                                btnConfirm.classList.add('bg-blue-600', 'hover:bg-blue-700');
                            }
                        }

                        function openModal(action, orderNumber, form) {
                            currentActionForm = form;
                            currentAction = action;
                            currentOrderNumber = orderNumber;

                            // Close any open dropdowns
                            document.querySelectorAll('[id^="dropdown-"]').forEach(d => d.classList.add('hidden'));

                            // Title + message
                            const pretty = action === 'out for delivery' ? 'Out for Delivery' : action.charAt(0).toUpperCase() + action.slice(1);
                            titleEl.textContent = (action === 'canceled') ? 'Cancel Order' : `Mark as ${pretty}`;
                            textEl.textContent = (action === 'canceled') ?
                                `Are you sure you want to cancel order #${orderNumber}?` :
                                `Are you sure you want to mark order #${orderNumber} as ${pretty}?`;

                            setConfirmStyle(action);
                            modal.classList.remove('hidden');
                        }

                        function closeModal() {
                            modal.classList.add('hidden');
                            currentActionForm = null;
                            currentAction = null;
                            currentOrderNumber = null;
                        }

                        // Wire buttons that trigger modal
                        document.querySelectorAll('.admin-action-btn').forEach(btn => {
                            btn.addEventListener('click', function(e) {
                                e.preventDefault();
                                const form = this.closest('form');
                                const action = this.dataset.action || '';
                                const orderNumber = this.dataset.orderNumber || '';
                                if (!form) return;
                                openModal(action, orderNumber, form);
                            });
                        });

                        // Modal controls
                        btnClose.addEventListener('click', closeModal);
                        btnCancel.addEventListener('click', closeModal);
                        modal.addEventListener('click', function(e) {
                            if (e.target === modal) closeModal();
                        });

                        btnConfirm.addEventListener('click', function() {
                            if (!currentActionForm) return;
                            // Optional: disable confirm to prevent double submit
                            btnConfirm.disabled = true;
                            currentActionForm.submit();
                        });
                    });

                    // Auto-apply filters like manage products
                    document.addEventListener('DOMContentLoaded', function() {
                        const form = document.getElementById('ordersFilterForm');
                        if (!form) return;

                        ['status', 'date_from', 'date_to'].forEach(function(id) {
                            const el = document.getElementById(id);
                            if (el) el.addEventListener('change', function() {
                                form.submit();
                            });
                        });

                        const searchEl = document.getElementById('search');
                        if (searchEl) {
                            searchEl.addEventListener('keydown', function(e) {
                                if (e.key === 'Enter') form.submit();
                            });
                        }
                    });
                </script>
            </x-app-layout>