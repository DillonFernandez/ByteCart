<?php

/**
 * AdminDashboardStatus
 *
 * Aggregates admin dashboard KPIs from MySQL and MongoDB:
 * - Core entity counts (customers/admins/products)
 * - Order status metrics, fulfillment rates, and chart data
 * - Revenue/orders for current period and last 7 days
 * - Sales by location, recent orders, item counts, and top products
 * - Inventory health and low/out-of-stock stats
 * Exposes a build() factory to compute metrics and toViewData() to flatten for views.
 */

namespace App\Models;

use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class AdminDashboardStatus
{
    // Core entity counts (MySQL)
    public int $customerCount = 0;
    public int $adminCount = 0;
    public int $productCount = 0;

    // Order status metrics and derived rates (Mongo)
    public string $chosenConn = 'mongodb_orders';
    public array $orderStatusCounts = [];
    public int $deliveredCount = 0;
    public int $pendingCount = 0;
    public int $processedCount = 0;
    public int $inTransitCount = 0;
    public int $canceledCount = 0;
    public float $deliveredRate = 0.0;
    public float $canceledRate = 0.0;
    public array $statusChartLabels = [];
    public array $statusChartCounts = [];

    // Last 7 days (labels, revenue, orders)
    public array $last7Labels = [];
    public array $last7Revenue = [];
    public array $last7Orders = [];

    // Current period KPIs (month or last-30-days)
    public float $totalSales = 0.0;
    public int $totalOrders = 0;
    public float $totalRevenue = 0.0;
    public float $aov30 = 0.0;

    // Sales by location (Mongo orders)
    public array $salesByLocation = [];
    public array $locationChartLabels = [];
    public array $locationChartCounts = [];

    // Inventory summary (MySQL)
    public int $outOfStockModels = 0;
    public int $lowStockModels = 0;
    public int $totalModels = 0;
    public float $inventoryHealth = 0.0;
    public $displayOutOfStock;
    public $displayLowStock;

    // Misc KPIs
    public int $discountedProducts = 0;
    public int $newCustomers7 = 0;

    // Collections for UI
    public $recentOrders;
    public $itemCounts;
    public $topProducts;

    // KPI period label
    public string $kpiPeriodLabel = 'This Month';

    /**
     * Build a populated dashboard status instance by aggregating metrics from data sources.
     */
    public static function build(): self
    {
        $s = new self();

        // Configure Mongo connection if missing
        // Ensure mongodb_orders is configured at runtime
        if (!config('database.connections.mongodb_orders')) {
            config()->set('database.connections.mongodb_orders', [
                'driver'   => 'mongodb',
                'dsn'      => env('MONGODB_ORDERS_DSN'),
                'host'     => env('MONGODB_ORDERS_HOST', '127.0.0.1'),
                'port'     => env('MONGODB_ORDERS_PORT', 27017),
                'database' => env('MONGODB_ORDERS_DATABASE', 'bytecart_orders'),
                'username' => env('MONGODB_ORDERS_USERNAME', ''),
                'password' => env('MONGODB_ORDERS_PASSWORD', ''),
                'options'  => [
                    'database' => env('MONGODB_ORDERS_AUTH_DATABASE', 'admin'),
                    'ssl'      => env('MONGODB_ORDERS_SSL', false),
                ],
            ]);
        }

        // Core counts (MySQL)
        $s->customerCount = (int) User::where('roles', 'customer')->count();
        $s->adminCount = (int) User::where('roles', 'admin')->count();
        $s->productCount = (int) Products::count();

        $currentMonthStart = Carbon::now()->startOfMonth();
        $currentMonthEnd   = Carbon::now()->endOfMonth();

        $mongo = DB::connection('mongodb_orders');

        // Helpers: safe field accessor and date normalization
        // Helper to read fields from array/stdClass
        $get = function ($row, $key) {
            return is_array($row) ? ($row[$key] ?? null) : (is_object($row) ? ($row->$key ?? null) : null);
        };

        // Helper to parse placed_at safely
        $toDayKey = function ($ts) {
            if ($ts instanceof \DateTimeInterface) {
                return Carbon::instance($ts)->format('Y-m-d');
            } elseif (is_object($ts) && method_exists($ts, 'toDateTime')) {
                return $ts->toDateTime()->format('Y-m-d');
            }
            return Carbon::parse((string)$ts)->format('Y-m-d');
        };

        // Helper to compute metrics for a window (Mongo)
        $metricsForWindow = function ($start, $end) use ($mongo, $get) {
            $rows = $mongo->table('orders')
                ->whereIn('order_status', ['processed', 'shipped', 'out for delivery', 'delivered'])
                ->whereBetween('placed_at', [$start, $end])
                ->get(['total']);
            $revenue = 0.0;
            $orders = 0;
            foreach ($rows as $r) {
                $revenue += (float) ($get($r, 'total') ?? 0);
                $orders++;
            }
            return (object) ['revenue' => $revenue, 'orders' => $orders];
        };

        // Current month metrics
        $currentMonthData = $metricsForWindow($currentMonthStart, $currentMonthEnd);

        // Choose KPI period: this month if data exists, else last 30 days
        if ((int)($currentMonthData->orders ?? 0) > 0) {
            $periodStart = $currentMonthStart;
            $periodEnd = $currentMonthEnd;
            $s->kpiPeriodLabel = 'This Month';
            $s->totalSales = (float)($currentMonthData->revenue ?? 0);
            $s->totalRevenue = $s->totalSales;
            $s->totalOrders = (int)($currentMonthData->orders ?? 0);
        } else {
            $periodStart = Carbon::now()->copy()->subDays(30)->startOfDay();
            $periodEnd = Carbon::now()->copy()->endOfDay();
            $altData = $metricsForWindow($periodStart, $periodEnd);
            $s->kpiPeriodLabel = 'Last 30 Days';
            $s->totalSales = (float)($altData->revenue ?? 0);
            $s->totalRevenue = $s->totalSales;
            $s->totalOrders = (int)($altData->orders ?? 0);
        }

        // AOV
        $s->aov30 = $s->totalOrders > 0 ? round($s->totalSales / $s->totalOrders, 2) : 0.0;

        // Order status counts (Mongo)
        $rawStatusDocs = $mongo->table('orders')->get(['order_status']);
        $statusCounts = [];
        foreach ($rawStatusDocs as $doc) {
            $st = (string) ($get($doc, 'order_status') ?? 'pending');
            $statusCounts[$st] = ($statusCounts[$st] ?? 0) + 1;
        }
        $allStatuses = ['pending', 'processed', 'shipped', 'out for delivery', 'delivered', 'canceled'];
        $s->orderStatusCounts = collect($allStatuses)->mapWithKeys(function ($st) use ($statusCounts) {
            return [$st => (int)($statusCounts[$st] ?? 0)];
        })->all();

        // Derived fulfillment metrics
        $totalOrdersAll = array_sum($s->orderStatusCounts);
        $s->deliveredCount = $s->orderStatusCounts['delivered'] ?? 0;
        $s->canceledCount = $s->orderStatusCounts['canceled'] ?? 0;
        $s->pendingCount = $s->orderStatusCounts['pending'] ?? 0;
        $s->processedCount = $s->orderStatusCounts['processed'] ?? 0;
        $s->inTransitCount = ($s->orderStatusCounts['shipped'] ?? 0) + ($s->orderStatusCounts['out for delivery'] ?? 0);

        $s->deliveredRate = $totalOrdersAll ? round(($s->deliveredCount / $totalOrdersAll) * 100, 1) : 0.0;
        $s->canceledRate = $totalOrdersAll ? round(($s->canceledCount / $totalOrdersAll) * 100, 1) : 0.0;

        // Revenue and orders for last 7 days (Mongo)
        $today = Carbon::today();
        $from7 = $today->copy()->subDays(6);
        $rows7 = $mongo->table('orders')
            ->whereIn('order_status', ['processed', 'shipped', 'out for delivery', 'delivered'])
            ->whereBetween('placed_at', [$from7->copy()->startOfDay(), $today->copy()->endOfDay()])
            ->get(['placed_at', 'total']);

        $bucket = [];
        foreach ($rows7 as $r) {
            $d = $toDayKey($get($r, 'placed_at'));
            $bucket[$d] = $bucket[$d] ?? ['revenue' => 0.0, 'cnt' => 0];
            $bucket[$d]['revenue'] += (float) ($get($r, 'total') ?? 0);
            $bucket[$d]['cnt'] += 1;
        }

        $s->last7Labels = [];
        $s->last7Revenue = [];
        $s->last7Orders = [];
        for ($i = 0; $i < 7; $i++) {
            $d = $from7->copy()->addDays($i)->format('Y-m-d');
            $s->last7Labels[] = $d;
            $s->last7Revenue[] = (float)($bucket[$d]['revenue'] ?? 0);
            $s->last7Orders[] = (int)($bucket[$d]['cnt'] ?? 0);
        }

        // Sales by location within the selected period (top 5 by revenue)
        $locDocs = $mongo->table('orders')
            ->whereIn('order_status', ['processed', 'shipped', 'out for delivery', 'delivered'])
            ->whereBetween('placed_at', [$periodStart, $periodEnd])
            ->get(['shipping_city', 'total']);

        $locAgg = [];
        foreach ($locDocs as $r) {
            $city = (string)($get($r, 'shipping_city') ?? 'Unknown');
            $locAgg[$city] = $locAgg[$city] ?? ['revenue' => 0.0, 'orders' => 0];
            $locAgg[$city]['revenue'] += (float)($get($r, 'total') ?? 0);
            $locAgg[$city]['orders'] += 1;
        }
        // Sort by revenue desc and take top 5
        uasort($locAgg, fn($a, $b) => ($b['revenue'] <=> $a['revenue']));
        $topLoc = array_slice($locAgg, 0, 5, true);

        $s->salesByLocation = [];
        foreach ($topLoc as $city => $v) {
            $s->salesByLocation[] = [
                'location' => $city,
                'amount' => (float) $v['revenue'],
                'orders' => (int) $v['orders'],
            ];
        }
        $s->locationChartLabels = array_column($s->salesByLocation, 'location');
        $s->locationChartCounts = array_column($s->salesByLocation, 'amount');
        if (empty($s->salesByLocation)) {
            $s->salesByLocation = [['location' => 'No Data', 'amount' => 0, 'orders' => 0]];
            $s->locationChartLabels = ['No Data'];
            $s->locationChartCounts = [0];
        }

        // Recent orders (Mongo) - latest by placed_at
        $s->recentOrders = collect(
            $mongo->table('orders')
                ->orderBy('placed_at', 'desc')
                ->limit(5)
                ->get()
        )->map(fn($d) => (object)$d);

        // Item counts for recent orders (Mongo)
        $recentIds = collect($s->recentOrders)->map(function ($o) {
            return is_array($o) ? ($o['_id'] ?? null) : ($o->_id ?? null);
        })->filter()->values()->all();

        $s->itemCounts = !empty($recentIds)
            ? collect($mongo->table('order_items')
                ->whereIn('order_id', $recentIds)
                ->get(['order_id', 'qty']))
            ->groupBy(function ($r) use ($get) {
                $id = $get($r, 'order_id');
                return is_object($id) ? (string)$id : (string)$id;
            })
            ->map(function ($grp) use ($get) {
                return $grp->reduce(fn($carry, $row) => $carry + (int)($get($row, 'qty') ?? 0), 0);
            })
            : collect();

        // Top products within selected period (by qty)
        $periodOrderNumbers = collect(
            $mongo->table('orders')
                ->whereIn('order_status', ['processed', 'shipped', 'out for delivery', 'delivered'])
                ->whereBetween('placed_at', [$periodStart, $periodEnd])
                ->get(['order_number'])
        )->map(function ($o) {
            return is_array($o) ? ($o['order_number'] ?? null) : ($o->order_number ?? null);
        })->filter()->values()->all();

        $topProductsAgg = [];
        if (!empty($periodOrderNumbers)) {
            $rows = $mongo->table('order_items')
                ->whereIn('order_number', $periodOrderNumbers)
                ->get(['product_id', 'product_name', 'qty']);
            foreach ($rows as $r) {
                $pid = (string) ($get($r, 'product_id') ?? 'unknown');
                $pname = (string) ($get($r, 'product_name') ?? 'Unknown');
                $topProductsAgg[$pid] = $topProductsAgg[$pid] ?? ['product_id' => $pid, 'product_name' => $pname, 'qty' => 0];
                $topProductsAgg[$pid]['qty'] += (int) ($get($r, 'qty') ?? 0);
            }
        }
        usort($topProductsAgg, fn($a, $b) => ($b['qty'] <=> $a['qty']));
        $s->topProducts = collect(array_slice($topProductsAgg, 0, 5));

        // Inventory stats and display lists (MySQL)
        $models = ProductModel::with('product:id,product_name')
            ->get(['id', 'product_id', 'model_name', 'stock']);

        $allOutOfStock = $models->filter(fn($m) => (int)($m->stock ?? 0) <= 0);
        // Low stock = 1..5 inclusive
        $allLowStock = $models->filter(fn($m) => (int)($m->stock ?? 0) > 0 && (int)$m->stock <= 5);

        $s->outOfStockModels = $allOutOfStock->count();
        $s->lowStockModels = $allLowStock->count();
        $s->totalModels = $models->count();

        // Display lists (limit for UI)
        $s->displayOutOfStock = $allOutOfStock->take(20);
        $s->displayLowStock = $allLowStock->sortBy('stock')->take(20);

        $s->discountedProducts = (int) Products::where('discount', '>', 0)->count();

        // New customers last 7 days
        $s->newCustomers7 = (int) User::where('roles', 'customer')
            ->where('created_at', '>=', Carbon::now()->subDays(7))
            ->count();

        // Inventory health %
        $wellStockModels = max(0, $s->totalModels - $s->lowStockModels - $s->outOfStockModels);
        $s->inventoryHealth = $s->totalModels
            ? round(($wellStockModels / $s->totalModels) * 100, 1)
            : 0.0;
        // Clamp to [0, 100]
        $s->inventoryHealth = max(0.0, min(100.0, $s->inventoryHealth));

        // Status chart data (labels and counts)
        $s->statusChartLabels = ['Pending', 'Processed', 'In Transit', 'Delivered', 'Canceled'];
        $s->statusChartCounts = [
            $s->pendingCount,
            $s->processedCount,
            $s->inTransitCount,
            $s->deliveredCount,
            $s->canceledCount,
        ];

        return $s;
    }

    /**
     * Flatten the computed metrics into an array suitable for Blade views.
     */
    public function toViewData(): array
    {
        return [
            // Core
            'customerCount' => $this->customerCount,
            'adminCount' => $this->adminCount,
            'productCount' => $this->productCount,

            // Current month / period KPIs
            'totalSales' => $this->totalSales,
            'totalOrders' => $this->totalOrders,
            'totalRevenue' => $this->totalRevenue,
            'aov30' => $this->aov30,
            'kpiPeriodLabel' => $this->kpiPeriodLabel,

            // Sales by location
            'salesByLocation' => $this->salesByLocation,
            'locationChartLabels' => $this->locationChartLabels,
            'locationChartCounts' => $this->locationChartCounts,

            // Orders/status
            'orderStatusCounts' => collect($this->orderStatusCounts),
            'deliveredCount' => $this->deliveredCount,
            'pendingCount' => $this->pendingCount,
            'processedCount' => $this->processedCount,
            'inTransitCount' => $this->inTransitCount,
            'canceledCount' => $this->canceledCount,
            'deliveredRate' => $this->deliveredRate,
            'canceledRate' => $this->canceledRate,
            'statusChartLabels' => $this->statusChartLabels,
            'statusChartCounts' => $this->statusChartCounts,

            // 7-day
            'last7Labels' => $this->last7Labels,
            'last7Revenue' => $this->last7Revenue,
            'last7Orders' => $this->last7Orders,

            // Inventory
            'outOfStockModels' => $this->outOfStockModels,
            'lowStockModels' => $this->lowStockModels,
            'totalModels' => $this->totalModels,
            'inventoryHealth' => $this->inventoryHealth,
            'displayOutOfStock' => $this->displayOutOfStock,
            'displayLowStock' => $this->displayLowStock,

            // Other
            'discountedProducts' => $this->discountedProducts,
            'newCustomers7' => $this->newCustomers7,

            // Lists
            'recentOrders' => $this->recentOrders,
            'itemCounts' => $this->itemCounts,
            'topProducts' => $this->topProducts,
        ];
    }
}
