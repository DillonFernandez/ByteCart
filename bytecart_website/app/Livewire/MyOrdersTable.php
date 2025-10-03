<?php

/**
 * MyOrdersTable (Livewire, PowerGrid)
 *
 * Displays the authenticated customer's orders:
 * - Fields/columns/filters for order data
 * - Per-row actions (cancel/delivered) and a details modal
 * - Customer-scoped datasource with formatted values and badges
 */

namespace App\Livewire;

use App\Models\Order;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\HtmlString;
use PowerComponents\LivewirePowerGrid\PowerGridComponent;
use PowerComponents\LivewirePowerGrid\PowerGridFields;
use PowerComponents\LivewirePowerGrid\Column;
use PowerComponents\LivewirePowerGrid\Facades\PowerGrid;
use PowerComponents\LivewirePowerGrid\Facades\Filter;

class MyOrdersTable extends PowerGridComponent
{
    public string $tableName = 'my_orders';

    /**
     * Configure table header and footer (per-page and record count).
     */
    public function setUp(): array
    {
        return [
            PowerGrid::header(),
            PowerGrid::footer()
                ->showPerPage()
                ->showRecordCount(),
        ];
    }

    /**
     * Declare fields and computed display values (badges, totals, formatted dates, actions).
     */
    public function fields(): PowerGridFields
    {
        return PowerGrid::fields()
            ->add('id', fn($row) => (string)($row->_id ?? $row->id))
            ->add('order_number')
            ->add('order_status')
            ->add('order_status_badge', fn($row) => new HtmlString($this->statusBadge($row->order_status)))
            ->add('items_count')
            ->add('total_raw', fn($row) => $row->total)
            ->add('total_display', fn($row) => number_format((float)$row->total, 2))
            ->add('placed_at')
            ->add('placed_at_display', function ($row) {
                $dt = $row->placed_at ?? $row->created_at;
                if (!$dt) return '';
                return $dt->timezone(config('app.timezone'))->format('M j, Y - h:i A');
            })
            ->add('payment_method')
            ->add('actions', function ($row) {
                // Render action buttons and modal for each order row
                $status = $row->order_status;
                $canCancel  = !in_array($status, ['shipped', 'out for delivery', 'delivered', 'canceled'], true);
                $canDeliver = in_array($status, ['shipped', 'out for delivery'], true);

                $forms = [];

                if ($canCancel) {
                    $forms[] = sprintf(
                        '<button type="button" class="action-btn action-btn--danger cancel-order-btn" data-order-id="%s" data-order-number="%s">
                            Cancel
                        </button>',
                        e($row->id),
                        e($row->order_number)
                    );
                }

                if ($canDeliver) {
                    $forms[] = sprintf(
                        '<button type="button" class="action-btn action-btn--success deliver-order-btn" data-order-id="%s" data-order-number="%s">
                            Delivered
                        </button>',
                        e($row->id),
                        e($row->order_number)
                    );
                }

                $detailsButton = '<button type="button" @click="showDetails=true"
                    class="action-btn action-btn--primary">
                    Details
                </button>';

                // Modal popup for order details
                $modal = '<div x-cloak x-show="showDetails" x-transition:enter="transition ease-out duration-300"
                        x-transition:enter-start="opacity-0" x-transition:enter-end="opacity-100"
                        x-transition:leave="transition ease-in duration-200"
                        x-transition:leave-start="opacity-100" x-transition:leave-end="opacity-0"
                        class="fixed inset-0 z-50 overflow-y-auto">
                        <div class="flex min-h-screen items-center justify-center p-4">
                            <div class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm" @click="showDetails=false"></div>
                            <div class="relative w-full max-w-4xl transform overflow-hidden rounded-2xl bg-white shadow-2xl transition-all">
                                <!-- Modal Header -->
                                <div class="flex items-center justify-between border-b border-slate-200 bg-gradient-to-r from-slate-50 to-slate-100 px-6 py-4">
                                    <div class="flex items-center gap-3">
                                        <div class="flex h-10 w-10 items-center justify-center rounded-full bg-blue-100">
                                            <svg class="h-5 w-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
                                            </svg>
                                        </div>
                                        <div>
                                            <h3 class="text-lg font-semibold text-slate-900">Order #' . e($row->order_number) . '</h3>
                                            <p class="text-sm text-slate-600">Order Details & Information</p>
                                        </div>
                                    </div>
                                    <button type="button" @click="showDetails=false"
                                        class="flex h-8 w-8 items-center justify-center rounded-full bg-slate-200/50 text-slate-500 transition-colors hover:bg-slate-200 hover:text-slate-700">
                                        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                                        </svg>
                                    </button>
                                </div>
                                <!-- Modal Body -->
                                <div class="max-h-[70vh] overflow-y-auto p-6">
                                    ' . $this->renderDetails($row) . '
                                </div>
                                <!-- Modal Footer -->
                                <div class="flex justify-end border-t border-slate-200 bg-slate-50 px-6 py-4">
                                    <button type="button" @click="showDetails=false"
                                        class="inline-flex items-center gap-2 rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-medium text-slate-700 shadow-sm transition-colors hover:bg-slate-50 focus:outline-none focus:ring-2 focus:ring-blue-500">
                                        Close
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>';

                $actionButtons = $forms ? implode(' ', $forms) : '';

                $content = '<div x-data="{showDetails:false}" class="relative">' .
                    '<div class="flex flex-wrap items-center gap-2">' .
                    $actionButtons . $detailsButton .
                    '</div>' .
                    $modal .
                    '</div>';

                return new HtmlString($content);
            });
    }

    /**
     * Provide current customer's orders as the data source.
     * Returns a Collection to avoid toSql() on Mongo builders.
     */
    public function datasource() // return a Collection to avoid toSql() on Mongo builder
    {
        $user = Auth::user();
        if (!$user || ($user->roles ?? '') !== 'customer') {
            return collect();
        }

        // Query: eager-load items, scope by user, and order by latest
        $rows = Order::query()
            ->with(['items']) // eager load items
            ->where('user_id', $user->id)
            ->orderByDesc('placed_at')
            ->orderByDesc('created_at')
            ->get();

        // Normalize: string id and derived items_count for PowerGrid
        return $rows->map(function ($o) {
            $o->id = (string)($o->_id ?? $o->id);
            $o->items_count = isset($o->items) && is_iterable($o->items) ? count($o->items) : (int)($o->items_count ?? 0);
            return $o;
        });
    }

    /**
     * Define table columns and map to fields.
     */
    public function columns(): array
    {
        return [
            Column::make('Order #', 'order_number')
                ->searchable(),

            Column::make('Date / Time', 'placed_at')
                ->field('placed_at', 'placed_at_display')
                ->searchable(),

            Column::make('Status (raw)', 'order_status')
                ->searchable()
                ->hidden(),

            Column::make('Status', 'order_status_badge'),

            Column::make('Items', 'items_count'),

            Column::make('Payment', 'payment_method'),

            Column::make('Total ($)', 'total_raw')
                ->field('total_raw', 'total_display'),

            Column::make('Actions', 'actions'),
        ];
    }

    /**
     * Define filters (e.g., order status).
     */
    public function filters(): array
    {
        return [
            Filter::select('order_status')
                ->dataSource([
                    ['value' => 'pending',          'label' => 'Pending'],
                    ['value' => 'processing',       'label' => 'Processing'],
                    ['value' => 'processed',        'label' => 'Processed'],
                    ['value' => 'shipped',          'label' => 'Shipped'],
                    ['value' => 'out for delivery', 'label' => 'Out For Delivery'],
                    ['value' => 'delivered',        'label' => 'Delivered'],
                    ['value' => 'canceled',         'label' => 'Canceled'],
                ])
                ->optionValue('value')
                ->optionLabel('label'),
        ];
    }

    /**
     * Render a styled status badge for the given status.
     */
    private function statusBadge(string $status): string
    {
        [$classes, $label] = match ($status) {
            'pending' => ['bg-amber-50 text-amber-700 border border-amber-200', 'Pending'],
            'processing', 'processed', 'shipped', 'out for delivery', 'delivered'
            => ['bg-green-50 text-green-700 border border-green-200', ucwords($status)],
            'canceled' => ['bg-red-50 text-red-700 border border-red-200', 'Canceled'],
            default => ['bg-slate-50 text-slate-600 border border-slate-200', ucwords($status)],
        };

        return '<span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ' . $classes . '">' . $label . '</span>';
    }

    /**
     * Render the order details content used inside the modal.
     */
    private function renderDetails($order): string
    {
        // Items: build desktop rows and mobile cards
        $itemsRows = '';
        $itemsCards = ''; // mobile stacked version
        foreach ($order->items as $it) {
            $modelColorChips = (($it->model_name || $it->color) ? '<div class="mt-1 text-xs text-slate-500">' .
                ($it->model_name ? '<span class="inline-flex items-center rounded bg-slate-100 px-2 py-0.5 text-[10px] font-medium text-slate-700 mr-2">Model: ' . e($it->model_name) . '</span>' : '') .
                ($it->color ? '<span class="inline-flex items-center rounded bg-slate-100 px-2 py-0.5 text-[10px] font-medium text-slate-700">Color: ' . e($it->color) . '</span>' : '') .
                '</div>' : '');

            // Desktop / tablet table row (unchanged layout)
            $itemsRows .= '<tr class="border-b border-slate-100 last:border-b-0 hover:bg-slate-25">
                <td class="py-3 pr-4 align-top">
                    <div class="font-medium text-slate-800">' . e($it->product_name) . '</div>' .
                $modelColorChips .
                '</td>
                <td class="py-3 px-4 text-center">
                    <span class="inline-flex items-center justify-center w-8 h-8 rounded-full bg-slate-100 text-sm font-medium text-slate-700">' . (int)$it->qty . '</span>
                </td>
                <td class="py-3 px-4 text-right text-slate-700">$' . number_format((float)$it->unit_price, 2) . '</td>
                <td class="py-3 pl-4 text-right font-semibold text-slate-800">$' . number_format((float)$it->line_total, 2) . '</td>
            </tr>';

            // Mobile card (no horizontal scroll)
            $itemsCards .= '<div class="p-3 rounded-lg border border-slate-200 bg-white shadow-sm">
                    <div class="flex justify-between items-start gap-3">
                        <div class="text-sm font-medium text-slate-800">' . e($it->product_name) . '</div>
                        <div class="shrink-0 text-[11px] px-2 py-1 rounded-full bg-slate-100 font-semibold text-slate-700">Qty: ' . (int)$it->qty . '</div>
                    </div>'
                . ($it->model_name || $it->color ? '<div class="mt-2 flex flex-wrap gap-2">' .
                    ($it->model_name ? '<span class="inline-block bg-slate-100 text-[10px] px-2 py-0.5 rounded font-medium text-slate-700">Model: ' . e($it->model_name) . '</span>' : '') .
                    ($it->color ? '<span class="inline-block bg-slate-100 text-[10px] px-2 py-0.5 rounded font-medium text-slate-700">Color: ' . e($it->color) . '</span>' : '') .
                    '</div>' : '') .
                '<div class="mt-3 flex justify-between text-[11px] text-slate-600">
                        <span>Unit: $' . number_format((float)$it->unit_price, 2) . '</span>
                        <span class="font-semibold text-slate-800">$' . number_format((float)$it->line_total, 2) . '</span>
                    </div>
                </div>';
        }

        // Summary: build totals section
        $summary = [
            'Subtotal' => $order->subtotal,
            'Shipping' => $order->shipping_fee,
            'Tax'      => $order->tax,
            'Total'    => $order->total,
        ];

        $summaryRows = '';
        foreach ($summary as $label => $val) {
            $isTotal = $label === 'Total';
            $summaryRows .= '<div class="flex justify-between items-center py-2 ' . ($isTotal ? 'border-t border-slate-200 font-semibold text-slate-900' : 'text-slate-700') . '">
                <span class="text-sm">' . e($label) . ':</span>
                <span class="text-sm ' . ($isTotal ? 'text-lg' : '') . '">$' . number_format((float)$val, 2) . '</span>
            </div>';
        }

        // Addresses: compose shipping and billing blocks
        $addr = fn($prefix) => trim(
            ($order->{$prefix . 'street_address'} ?? '') .
                ($order->{$prefix . 'apartment_suite'} ? ', ' . $order->{$prefix . 'apartment_suite'} : '') . "\n" .
                ($order->{$prefix . 'city'} ?? '') . ', ' .
                ($order->{$prefix . 'district'} ?? '') . ' ' .
                ($order->{$prefix . 'zip_code'} ?? '')
        );

        $shippingAddress = nl2br(e($addr('shipping_')));
        $billingAddress  = nl2br(e($addr('billing_')));

        // Return composed HTML content
        return '
            <div class="space-y-6">
                <!-- Order Items -->
                <div class="rounded-lg border border-slate-200 overflow-hidden">
                    <div class="bg-slate-50 px-4 py-3 border-b border-slate-200">
                        <h4 class="text-sm font-semibold text-slate-900 flex items-center gap-2">
                            <svg class="w-4 h-4 text-slate-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"></path>
                            </svg>
                            Order Items
                        </h4>
                    </div>
                    <!-- Desktop / Tablet Table -->
                    <div class="overflow-x-auto hidden sm:block">
                        <table class="w-full">
                            <thead class="bg-slate-50/50">
                                <tr>
                                    <th class="py-3 px-4 text-left text-xs font-semibold text-slate-600 uppercase tracking-wider">Product</th>
                                    <th class="py-3 px-4 text-center text-xs font-semibold text-slate-600 uppercase tracking-wider w-20">Qty</th>
                                    <th class="py-3 px-4 text-right text-xs font-semibold text-slate-600 uppercase tracking-wider w-24">Unit Price</th>
                                    <th class="py-3 px-4 text-right text-xs font-semibold text-slate-600 uppercase tracking-wider w-28">Total</th>
                                </tr>
                            </thead>
                            <tbody class="bg-white">' . $itemsRows . '</tbody>
                        </table>
                    </div>
                    <!-- Mobile Stacked Cards -->
                    <div class="p-4 sm:hidden bg-white">
                        <div class="space-y-3">' . $itemsCards . '</div>
                    </div>
                </div>

                <!-- Grid Layout for Summary and Addresses -->
                <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
                    <!-- Order Summary -->
                    <div class="lg:col-span-1">
                        <div class="rounded-lg border border-slate-200 overflow-hidden">
                            <div class="bg-slate-50 px-4 py-3 border-b border-slate-200">
                                <h4 class="text-sm font-semibold text-slate-900 flex items-center gap-2">
                                    <svg class="w-4 h-4 text-slate-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z"></path>
                                    </svg>
                                    Order Summary
                                </h4>
                            </div>
                            <div class="p-4 bg-gradient-to-br from-slate-50 to-white">
                                ' . $summaryRows . '
                            </div>
                        </div>
                    </div>

                    <!-- Shipping Address -->
                    <div class="lg:col-span-1">
                        <div class="rounded-lg border border-slate-200 overflow-hidden h-full">
                            <div class="bg-slate-50 px-4 py-3 border-b border-slate-200">
                                <h4 class="text-sm font-semibold text-slate-900 flex items-center gap-2">
                                    <svg class="w-4 h-4 text-slate-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path>
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path>
                                    </svg>
                                    Shipping Address
                                </h4>
                            </div>
                            <div class="p-4 bg-white text-sm text-slate-700 leading-relaxed whitespace-pre-line">' . $shippingAddress . '</div>
                        </div>
                    </div>

                    <!-- Billing Address -->
                    <div class="lg:col-span-1">
                        <div class="rounded-lg border border-slate-200 overflow-hidden h-full">
                            <div class="bg-slate-50 px-4 py-3 border-b border-slate-200">
                                <h4 class="text-sm font-semibold text-slate-900 flex items-center gap-2">
                                    <svg class="w-4 h-4 text-slate-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"></path>
                                    </svg>
                                    Billing Address
                                </h4>
                            </div>
                            <div class="p-4 bg-white text-sm text-slate-700 leading-relaxed whitespace-pre-line">' . $billingAddress . '</div>
                        </div>
                    </div>
                </div>'
            . ($order->notes ? '
                <!-- Order Notes -->
                <div class="rounded-lg border border-amber-200 overflow-hidden">
                    <div class="bg-amber-50 px-4 py-3 border-b border-amber-200">
                        <h4 class="text-sm font-semibold text-amber-900 flex items-center gap-2">
                            <svg class="w-4 h-4 text-amber-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z"></path>
                            </svg>
                            Order Notes
                        </h4>
                    </div>
                    <div class="p-4 bg-amber-25 text-sm text-amber-800">' . e($order->notes) . '</div>
                </div>' : '') .
            '</div>';
    }
}
