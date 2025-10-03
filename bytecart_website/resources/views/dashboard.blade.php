@php
$user = auth()->user();
if (!$user || !in_array('admin', (array)($user->roles ?? []))) {
\Illuminate\Support\Facades\Auth::guard('web')->logout();
\Illuminate\Support\Facades\Session::invalidate();
\Illuminate\Support\Facades\Session::regenerateToken();
header('Location: ' . route('login'));
exit;
}
@endphp

@php
// Build or use injected status from controller (keeps view working even without route wiring)
try {
$status = $status ?? \App\Models\AdminDashboardStatus::build();
} catch (\Throwable $e) {
$status = null;
}
$viewData = (is_object($status) && method_exists($status, 'toViewData'))
? $status->toViewData()
: [
'customerCount' => 0,
'adminCount' => 0,
'productCount' => 0,
'totalSales' => 0.0,
'totalOrders' => 0,
'totalRevenue' => 0.0,
'aov30' => 0.0,
'kpiPeriodLabel' => 'This Month',
'salesByLocation' => [],
'locationChartLabels' => [],
'locationChartCounts' => [],
'orderStatusCounts' => collect([]),
'deliveredCount' => 0,
'pendingCount' => 0,
'processedCount' => 0,
'inTransitCount' => 0,
'canceledCount' => 0,
'deliveredRate' => 0.0,
'canceledRate' => 0.0,
'statusChartLabels' => [],
'statusChartCounts' => [],
'last7Labels' => [],
'last7Revenue' => [],
'last7Orders' => [],
'outOfStockModels' => 0,
'lowStockModels' => 0,
'totalModels' => 0,
'inventoryHealth' => 0.0,
'discountedProducts' => 0,
'newCustomers7' => 0,
'recentOrders' => collect(),
'itemCounts' => collect(),
'topProducts' => collect(),
];
extract($viewData, EXTR_SKIP);

// Ensure mongodb_orders configured (safe runtime seed)
try {
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
} catch (\Throwable $e) {
$mongo = null;
}

// Always pull these from MySQL (not Mongo)
try {
// Total Customers
$customerCount = (int) \App\Models\User::where('roles', 'customer')->count();

// Inventory Health (outOfStock, lowStock, totals)
$models = \App\Models\ProductModel::get(['id', 'stock']);
$outOfStockModels = $models->filter(fn($m) => (int)($m->stock ?? 0) <= 0)->count();
    $lowStockModels = $models->filter(fn($m) => (int)($m->stock ?? 0) > 0 && (int)$m->stock <= 5)->count();
        $totalModels = $models->count();
        $well = max(0, $totalModels - $lowStockModels - $outOfStockModels);
        $inventoryHealth = $totalModels ? round(($well / $totalModels) * 100, 1) : 0.0;
        $inventoryHealth = max(0.0, min(100.0, $inventoryHealth));
        } catch (\Throwable $e) {
        // leave defaults from $viewData
        }

        // Pull these from MongoDB: totals, charts, location, top items, recent orders
        if ($mongo) {
        try {
        $now = \Carbon\Carbon::now();
        $today = \Carbon\Carbon::today();
        $from7 = $today->copy()->subDays(6);
        $from30 = $today->copy()->subDays(29)->startOfDay();
        $validStatuses = ['processed','shipped','out for delivery','delivered'];

        // Helper to read fields from array/stdClass
        $get = function ($row, $key) {
        return is_array($row) ? ($row[$key] ?? null) : (is_object($row) ? ($row->$key ?? null) : null);
        };

        // Totals (Last 30 days) if empty
        $rows30 = $mongo->table('orders')
        ->whereIn('order_status', $validStatuses)
        ->whereBetween('placed_at', [$from30, $now])
        ->get(['total']);
        $rev30 = 0.0; $cnt30 = 0;
        foreach ($rows30 as $r) { $rev30 += (float)($get($r,'total') ?? 0); $cnt30++; }
        if (($totalOrders ?? 0) === 0 && $cnt30 > 0) {
        $kpiPeriodLabel = 'Last 30 Days';
        $totalOrders = $cnt30;
        $totalSales = (float) $rev30;
        $totalRevenue = (float) $rev30;
        }

        // Last 7 days charts
        $rows7 = $mongo->table('orders')
        ->whereIn('order_status', $validStatuses)
        ->whereBetween('placed_at', [$from7->copy()->startOfDay(), $today->copy()->endOfDay()])
        ->get(['placed_at', 'total']);
        $bucket = [];
        foreach ($rows7 as $r) {
        $ts = $get($r, 'placed_at');
        if ($ts instanceof \DateTimeInterface) {
        $d = \Carbon\Carbon::instance($ts)->format('Y-m-d');
        } elseif (is_object($ts) && method_exists($ts, 'toDateTime')) {
        $d = $ts->toDateTime()->format('Y-m-d');
        } else {
        $d = \Carbon\Carbon::parse((string)$ts)->format('Y-m-d');
        }
        $bucket[$d] = $bucket[$d] ?? ['revenue' => 0.0, 'cnt' => 0];
        $bucket[$d]['revenue'] += (float)($get($r,'total') ?? 0);
        $bucket[$d]['cnt'] += 1;
        }
        $last7Labels = []; $last7Revenue = []; $last7Orders = [];
        for ($i=0; $i<7; $i++) {
            $d=$from7->copy()->addDays($i)->format('Y-m-d');
            $last7Labels[] = $d;
            $last7Revenue[] = (float)($bucket[$d]['revenue'] ?? 0);
            $last7Orders[] = (int)($bucket[$d]['cnt'] ?? 0);
            }

            // Sales by Location (Last 30 days top 5)
            $locDocs = $mongo->table('orders')
            ->whereIn('order_status', $validStatuses)
            ->whereBetween('placed_at', [$from30, $now])
            ->get(['shipping_city','total']);
            $locAgg = [];
            foreach ($locDocs as $r) {
            $city = (string)($get($r,'shipping_city') ?? 'Unknown');
            $locAgg[$city] = $locAgg[$city] ?? 0.0;
            $locAgg[$city] += (float)($get($r,'total') ?? 0);
            }
            arsort($locAgg);
            $topLoc = array_slice($locAgg, 0, 5, true);
            $salesByLocation = [];
            foreach ($topLoc as $city => $amt) {
            $salesByLocation[] = ['location' => $city, 'amount' => (float)$amt, 'orders' => 0];
            }
            $locationChartLabels = array_column($salesByLocation, 'location');
            $locationChartCounts = array_column($salesByLocation, 'amount');

            // Top Selling Items (Last 30 days) - use order_number instead of ObjectId
            $periodOrderNumbers = collect(
            $mongo->table('orders')
            ->whereIn('order_status', $validStatuses)
            ->whereBetween('placed_at', [$from30, $now])
            ->get(['order_number'])
            )->map(function ($o) {
            return is_array($o) ? ($o['order_number'] ?? null) : ($o->order_number ?? null);
            })->filter()->values()->all();

            $topProducts = collect();
            if (!empty($periodOrderNumbers)) {
            $rows = $mongo->table('order_items')
            ->whereIn('order_number', $periodOrderNumbers)
            ->get(['product_id','product_name','qty']);
            $agg = [];
            foreach ($rows as $r) {
            $pid = (string)($get($r,'product_id') ?? 'unknown');
            $pname = (string)($get($r,'product_name') ?? 'Unknown');
            $agg[$pid] = $agg[$pid] ?? ['product_id'=>$pid,'product_name'=>$pname,'qty'=>0];
            $agg[$pid]['qty'] += (int)($get($r,'qty') ?? 0);
            }
            usort($agg, fn($a,$b) => ($b['qty'] <=> $a['qty']));
                $topProducts = collect(array_slice($agg, 0, 5))->map(fn($v) => (object)$v);
                }

                // Recent Orders (latest 5 by placed_at)
                $recentOrders = collect(
                $mongo->table('orders')
                ->orderBy('placed_at', 'desc')
                ->limit(5)
                ->get()
                )->map(fn($d) => (object)$d);

                } catch (\Throwable $e) {
                // leave defaults
                }
                }
                @endphp

                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <meta name="csrf-token" content="{{ csrf_token() }}">
                    <title>ByteCart - Admin | Dashboard</title>
                    <link rel="icon" type="image/x-icon" href="{{ asset('logo/x-icon.webp') }}">
                    @vite(['resources/css/app.css', 'resources/js/app.js'])
                </head>

                <x-app-layout>
                    <x-slot name="header">
                        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
                            {{ __('Dashboard') }}
                        </h2>
                    </x-slot>
                    <div class="min-h-screen">
                        <div class="w-full mx-auto pb-5 pt-5 px-4 sm:px-16 sm:pb-10 sm:pt-10">

                            <!-- Key Metrics Cards -->
                            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
                                <!-- Total Sales -->
                                <div class="bg-white rounded-[18px] p-6" style="box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);">
                                    <div class="flex items-center justify-between">
                                        <div>
                                            <p class="text-sm font-medium text-gray-600">Total Sales</p>
                                            <p class="text-2xl font-bold text-gray-900">${{ number_format((float) $totalSales) }}</p>
                                            <div class="flex items-center mt-2">
                                                <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800">
                                                    {{ $kpiPeriodLabel ?? 'This Month' }}
                                                </span>
                                            </div>
                                        </div>
                                        <div class="w-12 h-12 bg-blue-50 rounded-lg flex items-center justify-center">
                                            <img src="{{ asset('icons/sales.webp') }}" alt="Sales" class="w-8 h-8">
                                        </div>
                                    </div>
                                </div>

                                <!-- Total Orders -->
                                <div class="bg-white rounded-[18px] p-6" style="box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);">
                                    <div class="flex items-center justify-between">
                                        <div>
                                            <p class="text-sm font-medium text-gray-600">Total Orders</p>
                                            <p class="text-2xl font-bold text-gray-900">{{ number_format($totalOrders) }}</p>
                                            <div class="flex items-center mt-2">
                                                <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800">
                                                    {{ $kpiPeriodLabel ?? 'This Month' }}
                                                </span>
                                            </div>
                                        </div>
                                        <div class="w-12 h-12 bg-green-50 rounded-lg flex items-center justify-center">
                                            <img src="{{ asset('icons/orders.webp') }}" alt="Orders" class="w-8 h-8">
                                        </div>
                                    </div>
                                </div>

                                <!-- Total Revenue -->
                                <div class="bg-white rounded-[18px] p-6" style="box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);">
                                    <div class="flex items-center justify-between">
                                        <div>
                                            <p class="text-sm font-medium text-gray-600">Total Revenue</p>
                                            <p class="text-2xl font-bold text-gray-900">${{ number_format((float) $totalRevenue) }}</p>
                                            <div class="flex items-center mt-2">
                                                <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-purple-100 text-purple-800">
                                                    {{ $kpiPeriodLabel ?? 'This Month' }}
                                                </span>
                                            </div>
                                        </div>
                                        <div class="w-12 h-12 bg-purple-50 rounded-lg flex items-center justify-center">
                                            <img src="{{ asset('icons/revenue.webp') }}" alt="Revenue" class="w-8 h-8">
                                        </div>
                                    </div>
                                </div>

                                <!-- Total Customers -->
                                <div class="bg-white rounded-[18px] p-6" style="box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);">
                                    <div class="flex items-center justify-between">
                                        <div>
                                            <p class="text-sm font-medium text-gray-600">Total Customers</p>
                                            <p class="text-2xl font-bold text-gray-900">{{ number_format($customerCount) }}</p>
                                            <div class="flex items-center mt-2">
                                                <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-orange-100 text-orange-800">
                                                    All Time
                                                </span>
                                            </div>
                                        </div>
                                        <div class="w-12 h-12 bg-orange-50 rounded-lg flex items-center justify-center">
                                            <img src="{{ asset('icons/customer.webp') }}" alt="Customers" class="w-8 h-8">
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Charts Section -->
                            <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
                                <!-- Revenue Chart -->
                                <div class="bg-white rounded-[18px] p-6 h-full flex flex-col" style="box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);">
                                    <div class="flex items-center justify-between mb-6">
                                        <div>
                                            <h3 class="text-lg font-semibold text-gray-900">Revenue Chart</h3>
                                            <p class="text-sm text-gray-600">Last 7 days</p>
                                        </div>
                                        <div class="flex items-center">
                                            <div class="w-3 h-3 bg-green-500 rounded-full mr-2"></div>
                                            <span class="text-xs text-gray-600">Daily Revenue</span>
                                        </div>
                                    </div>
                                    <div class="flex-1 h-48 sm:h-56 lg:min-h-[240px]">
                                        <canvas id="revenueChart" class="w-full h-full"></canvas>
                                    </div>
                                </div>

                                <!-- Orders Chart -->
                                <div class="bg-white rounded-[18px] p-6 h-full flex flex-col" style="box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);">
                                    <div class="flex items-center justify-between mb-6">
                                        <div>
                                            <h3 class="text-lg font-semibold text-gray-900">Orders Chart</h3>
                                            <p class="text-sm text-gray-600">Last 7 days</p>
                                        </div>
                                        <div class="flex items-center">
                                            <div class="w-3 h-3 bg-purple-500 rounded-full mr-2"></div>
                                            <span class="text-xs text-gray-600">Daily Orders</span>
                                        </div>
                                    </div>
                                    <div class="flex-1 h-48 sm:h-56 lg:min-h-[240px]">
                                        <canvas id="ordersChart" class="w-full h-full"></canvas>
                                    </div>
                                </div>

                                <!-- Sales by Location Chart -->
                                <div class="bg-white rounded-[18px] p-6 h-full flex flex-col" style="box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);">
                                    <div class="flex items-center justify-between mb-4">
                                        <div>
                                            <h3 class="text-lg font-semibold text-gray-900">Sales by Location</h3>
                                            <p class="text-sm text-gray-600">Top 5 cities ({{ $kpiPeriodLabel ?? 'This Month' }})</p>
                                        </div>
                                    </div>
                                    <div class="flex-1 h-32 sm:h-40 lg:h-48 mb-4 flex items-center justify-center">
                                        <div class="w-32 h-32 sm:w-40 sm:h-40 lg:w-48 lg:h-48">
                                            <canvas id="locationChart" class="w-full h-full"></canvas>
                                        </div>
                                    </div>
                                    <div class="space-y-2 max-h-20 sm:max-h-24 overflow-y-auto">
                                        @foreach($salesByLocation as $location)
                                        <div class="flex items-center justify-between text-xs">
                                            <div class="flex items-center">
                                                <div class="w-2 h-2 rounded-full mr-2 {{ ['bg-blue-500', 'bg-green-500', 'bg-purple-500', 'bg-amber-500', 'bg-red-500'][$loop->index % 5] }}"></div>
                                                <span class="text-gray-900 truncate">{{ $location['location'] }}</span>
                                            </div>
                                            <span class="font-medium">${{ number_format($location['amount']) }}</span>
                                        </div>
                                        @endforeach
                                    </div>
                                </div>
                            </div>

                            <!-- Bottom Section - Equal Height Cards -->
                            <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
                                <!-- Top Selling Items -->
                                <div class="bg-white rounded-[18px] h-full flex flex-col" style="box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);">
                                    <div class="p-6 border-b border-gray-200">
                                        <div class="flex items-center justify-between">
                                            <h3 class="text-lg font-semibold text-gray-900">Top Selling Items</h3>
                                            <div class="flex space-x-2">
                                                <button class="px-3 py-1 text-xs bg-gray-100 text-gray-600 rounded">{{ $kpiPeriodLabel ?? 'This Month' }}</button>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="flex-1 divide-y divide-gray-50">
                                        @if($topProducts->isEmpty())
                                        <div class="p-6 text-center flex items-center justify-center h-full">
                                            <div>
                                                <div class="w-12 h-12 mx-auto bg-gray-100 rounded-lg flex items-center justify-center mb-3">
                                                    <svg class="w-6 h-6 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10"></path>
                                                    </svg>
                                                </div>
                                                <p class="text-gray-500">No sales data available</p>
                                            </div>
                                        </div>
                                        @else
                                        @foreach($topProducts->take(5) as $index => $tp)
                                        <div class="p-4 hover:bg-gray-50 transition-colors">
                                            <div class="flex items-center space-x-4">
                                                <div class="w-10 h-10 bg-gray-100 rounded-lg flex items-center justify-center">
                                                    <span class="text-sm font-medium text-gray-600">{{ $index + 1 }}</span>
                                                </div>
                                                <div class="flex-1 min-w-0">
                                                    <p class="text-sm font-medium text-gray-900 truncate">{{ $tp->product_name ?? 'Product' }}</p>
                                                    <p class="text-xs text-gray-500">
                                                        ID: {{ \Illuminate\Support\Str::limit(($tp->product_id ?? $tp->id ?? 'N/A'), 15) }}
                                                    </p>
                                                </div>
                                                <div class="text-right">
                                                    <p class="text-sm font-medium text-gray-900">{{ (int)$tp->qty }} sold</p>
                                                    <p class="text-xs text-gray-500">Units</p>
                                                </div>
                                            </div>
                                        </div>
                                        @endforeach
                                        @endif
                                    </div>
                                </div>

                                <!-- Recent Orders -->
                                <div class="bg-white rounded-[18px] h-full flex flex-col" style="box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);">
                                    <div class="p-6 border-b border-gray-200">
                                        <div class="flex items-center justify-between">
                                            <div>
                                                <h3 class="text-lg font-semibold text-gray-900">Recent Orders</h3>
                                            </div>
                                            <div class="flex space-x-2">
                                                <button class="px-3 py-1 text-xs bg-gray-100 text-gray-600 rounded">Latest 5 Orders</button>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="flex-1 p-6">
                                        @if(collect($recentOrders)->isEmpty())
                                        <div class="text-center h-full flex items-center justify-center">
                                            <div>
                                                <div class="w-12 h-12 mx-auto bg-gray-100 rounded-lg flex items-center justify-center mb-3">
                                                    <svg class="w-6 h-6 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"></path>
                                                    </svg>
                                                </div>
                                                <p class="text-gray-500">No recent orders</p>
                                            </div>
                                        </div>
                                        @else
                                        <div class="space-y-4">
                                            @foreach(collect($recentOrders) as $ro)
                                            @php
                                            $os = $ro->order_status ?? 'pending';
                                            $statusColors = [
                                            'pending' => 'bg-yellow-100 text-yellow-800',
                                            'processed' => 'bg-blue-100 text-blue-800',
                                            'shipped' => 'bg-indigo-100 text-indigo-800',
                                            'out for delivery' => 'bg-purple-100 text-purple-800',
                                            'delivered' => 'bg-green-100 text-green-800',
                                            'canceled' => 'bg-red-100 text-red-800'
                                            ];
                                            $statusColor = $statusColors[$os] ?? 'bg-gray-100 text-gray-800';
                                            @endphp
                                            <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                                                <div>
                                                    <p class="text-sm font-medium text-gray-900">{{ $ro->order_number }}</p>
                                                    <p class="text-xs text-gray-500">{{ \Illuminate\Support\Str::limit($ro->customer_name, 20) }}</p>
                                                </div>
                                                <div class="text-right">
                                                    <p class="text-sm font-medium text-gray-900">${{ number_format((float)($ro->total ?? 0), 2) }}</p>
                                                    <span class="inline-flex items-center px-2 py-1 rounded text-xs font-medium {{ $statusColor }}">
                                                        {{ ucfirst($os) }}
                                                    </span>
                                                </div>
                                            </div>
                                            @endforeach
                                        </div>
                                        @endif
                                    </div>
                                </div>

                                <!-- Inventory Health -->
                                <div class="bg-white rounded-[18px] p-6 h-full flex flex-col" style="box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);">
                                    <div class="flex items-center justify-between mb-6">
                                        <div>
                                            <h3 class="text-lg font-semibold text-gray-900">Inventory Health</h3>
                                            <p class="text-sm text-gray-600">Overall stock status</p>
                                        </div>
                                    </div>

                                    <div class="flex-1 flex flex-col justify-center">
                                        <div class="relative w-32 h-32 mx-auto mb-6">
                                            <svg class="w-32 h-32 transform -rotate-90" viewBox="0 0 128 128">
                                                <circle cx="64" cy="64" r="52" stroke="#e5e7eb" stroke-width="8" fill="none" />
                                                <circle cx="64" cy="64" r="52" stroke="{{ $inventoryHealth >= 80 ? '#10b981' : ($inventoryHealth >= 60 ? '#f59e0b' : '#ef4444') }}" stroke-width="8"
                                                    fill="none" stroke-dasharray="326.73"
                                                    stroke-dashoffset="{{ 326.73 - (326.73 * $inventoryHealth / 100) }}"
                                                    stroke-linecap="round" />
                                            </svg>
                                            <div class="absolute inset-0 flex items-center justify-center">
                                                <div class="text-center">
                                                    <div class="text-2xl font-bold text-gray-900">{{ $inventoryHealth }}%</div>
                                                    <div class="text-xs {{ $inventoryHealth >= 80 ? 'text-green-600' : ($inventoryHealth >= 60 ? 'text-yellow-600' : 'text-red-600') }} font-medium">
                                                        {{ $inventoryHealth >= 80 ? 'Healthy' : ($inventoryHealth >= 60 ? 'Warning' : 'Critical') }}
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        <div class="text-center mb-6">
                                            <p class="text-sm text-gray-600">{{ $totalModels - $lowStockModels - $outOfStockModels }} of {{ $totalModels }} models are well stocked</p>
                                        </div>

                                        <div class="grid grid-cols-3 gap-4 text-center">
                                            <div>
                                                <p class="text-xs text-gray-500">Total</p>
                                                <p class="font-semibold text-gray-900">{{ $totalModels }}</p>
                                            </div>
                                            <div>
                                                <p class="text-xs text-gray-500">Low Stock</p>
                                                <p class="font-semibold text-amber-600">{{ $lowStockModels }}</p>
                                            </div>
                                            <div>
                                                <p class="text-xs text-gray-500">Out of Stock</p>
                                                <p class="font-semibold text-red-600">{{ $outOfStockModels }}</p>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Data payload for charts -->
                    <div id="dashboard-data"
                        data-labels='{{ json_encode($last7Labels) }}'
                        data-revenue='{{ json_encode($last7Revenue) }}'
                        data-orders='{{ json_encode($last7Orders) }}'
                        data-location-labels='{{ json_encode($locationChartLabels) }}'
                        data-location-counts='{{ json_encode($locationChartCounts) }}'
                        data-status-labels='@json($statusChartLabels)'
                        data-status-counts='@json($statusChartCounts)'>
                    </div>

                    <!-- Charts scripts -->
                    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
                    <script>
                        (function() {
                            function initCharts() {
                                const dataEl = document.getElementById('dashboard-data');
                                let labels = [],
                                    revenue = [],
                                    orders = [],
                                    locationLabels = [],
                                    locationCounts = [];

                                if (dataEl) {
                                    try {
                                        labels = JSON.parse(dataEl.getAttribute('data-labels') || '[]');
                                    } catch (e) {}
                                    try {
                                        revenue = JSON.parse(dataEl.getAttribute('data-revenue') || '[]');
                                    } catch (e) {}
                                    try {
                                        orders = JSON.parse(dataEl.getAttribute('data-orders') || '[]');
                                    } catch (e) {}
                                    try {
                                        locationLabels = JSON.parse(dataEl.getAttribute('data-location-labels') || '[]');
                                    } catch (e) {}
                                    try {
                                        locationCounts = JSON.parse(dataEl.getAttribute('data-location-counts') || '[]');
                                    } catch (e) {}
                                }

                                // Revenue Chart
                                const rc = document.getElementById('revenueChart');
                                if (rc && window.Chart) {
                                    const ex = Chart.getChart(rc);
                                    if (ex) ex.destroy();

                                    new Chart(rc, {
                                        type: 'line',
                                        data: {
                                            labels: labels.map(date => new Date(date).toLocaleDateString('en-US', {
                                                month: 'short',
                                                day: 'numeric'
                                            })),
                                            datasets: [{
                                                label: 'Revenue ($)',
                                                data: revenue,
                                                borderColor: '#10b981',
                                                backgroundColor: 'rgba(16, 185, 129, 0.1)',
                                                tension: 0.4,
                                                fill: true,
                                                pointRadius: 4,
                                                pointBackgroundColor: '#10b981'
                                            }]
                                        },
                                        options: {
                                            responsive: true,
                                            maintainAspectRatio: false,
                                            plugins: {
                                                legend: {
                                                    display: false
                                                }
                                            },
                                            scales: {
                                                y: {
                                                    beginAtZero: true,
                                                    grid: {
                                                        color: '#f3f4f6'
                                                    },
                                                    ticks: {
                                                        font: {
                                                            size: window.innerWidth < 640 ? 10 : 12
                                                        },
                                                        callback: function(value) {
                                                            return '$' + value.toLocaleString();
                                                        }
                                                    }
                                                },
                                                x: {
                                                    grid: {
                                                        display: false
                                                    },
                                                    ticks: {
                                                        font: {
                                                            size: window.innerWidth < 640 ? 10 : 12
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    });
                                }

                                // Orders Chart
                                const oc = document.getElementById('ordersChart');
                                if (oc && window.Chart) {
                                    const ex2 = Chart.getChart(oc);
                                    if (ex2) ex2.destroy();

                                    new Chart(oc, {
                                        type: 'bar',
                                        data: {
                                            labels: labels.map(date => new Date(date).toLocaleDateString('en-US', {
                                                month: 'short',
                                                day: 'numeric'
                                            })),
                                            datasets: [{
                                                label: 'Orders',
                                                data: orders,
                                                backgroundColor: 'rgba(139, 92, 246, 0.8)',
                                                borderColor: '#8b5cf6',
                                                borderWidth: 1,
                                                borderRadius: 4
                                            }]
                                        },
                                        options: {
                                            responsive: true,
                                            maintainAspectRatio: false,
                                            plugins: {
                                                legend: {
                                                    display: false
                                                }
                                            },
                                            scales: {
                                                y: {
                                                    beginAtZero: true,
                                                    grid: {
                                                        color: '#f3f4f6'
                                                    },
                                                    ticks: {
                                                        stepSize: 1,
                                                        font: {
                                                            size: window.innerWidth < 640 ? 10 : 12
                                                        },
                                                        callback: function(value) {
                                                            return Math.floor(value);
                                                        }
                                                    }
                                                },
                                                x: {
                                                    grid: {
                                                        display: false
                                                    },
                                                    ticks: {
                                                        font: {
                                                            size: window.innerWidth < 640 ? 10 : 12
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    });
                                }

                                // Sales by Location Donut Chart
                                const lc = document.getElementById('locationChart');
                                if (lc && window.Chart) {
                                    const ex3 = Chart.getChart(lc);
                                    if (ex3) ex3.destroy();

                                    new Chart(lc, {
                                        type: 'doughnut',
                                        data: {
                                            labels: locationLabels,
                                            datasets: [{
                                                data: locationCounts,
                                                backgroundColor: ['#3b82f6', '#10b981', '#8b5cf6', '#f59e0b', '#ef4444'],
                                                borderWidth: 0,
                                                cutout: '50%'
                                            }]
                                        },
                                        options: {
                                            responsive: true,
                                            maintainAspectRatio: false,
                                            plugins: {
                                                legend: {
                                                    display: false
                                                },
                                                tooltip: {
                                                    callbacks: {
                                                        label: function(context) {
                                                            const label = context.label || '';
                                                            const value = context.parsed || 0;
                                                            return label + ': $' + value.toLocaleString();
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    });
                                }
                            }

                            function ready(cb) {
                                document.readyState !== 'loading' ? cb() : document.addEventListener('DOMContentLoaded', cb);
                            }

                            function ensure() {
                                if (window.Chart) initCharts();
                                else setTimeout(ensure, 50);
                            }
                            ready(ensure);
                        })();
                    </script>
                </x-app-layout>