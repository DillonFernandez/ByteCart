<?php

/**
 * CheckoutController
 *
 * Orchestrates the checkout flow:
 * - Render checkout page with sanitized user/cart data
 * - Validate and sanitize inputs; handle payment details securely
 * - Persist user profile and address/payment info (MySQL)
 * - Create order and items (MongoDB) and adjust stock (MySQL)
 * - Auto-mark stale orders as delivered (non-blocking background task)
 */

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Carbon\Carbon;
use App\Support\Cart\CartFacade as Cart;

class CheckoutController extends Controller
{
    /**
     * Display checkout: auto-mark stale orders, authorize user, sanitize data, compute totals, and render.
     */
    public function show(Request $request)
    {
        // Maintenance: mark orders older than threshold as delivered
        $this->autoMarkDeliveredOrders();

        $user = Auth::user();

        // Authorization: require authenticated customer
        if (!$user instanceof \App\Models\User) {
            return redirect()->route('home');
        }
        if (!$user || ($user->roles ?? '') !== 'customer') {
            return redirect()->route('home');
        }

        // Cart: fetch items and sanitize user-supplied options (e.g., color) for safe rendering
        $items = Cart::items();
        if (is_array($items)) {
            $items = array_map(function ($item) {
                if (is_array($item) && isset($item['options']['color'])) {
                    $item['options']['color'] = strip_tags((string) $item['options']['color']);
                }
                return $item;
            }, $items);
        }

        // User: clone and sanitize profile fields for the view
        $safeUser = clone $user;
        $sanitize = function ($v) {
            return is_string($v) ? strip_tags($v) : $v;
        };
        foreach (
            [
                'name',
                'email',
                'phone_number',
                'shipping_street_address',
                'shipping_apartment_suite',
                'shipping_city',
                'shipping_district',
                'shipping_zip_code',
                'billing_street_address',
                'billing_apartment_suite',
                'billing_city',
                'billing_district',
                'billing_zip_code'
            ] as $field
        ) {
            $safeUser->$field = $sanitize($safeUser->$field ?? null);
        }

        // Totals: compute subtotal, shipping, tax, and total
        $subtotal = (float) Cart::total();
        $shipping = 5.00;
        $tax = round($subtotal * 0.05, 2);
        $total = round($subtotal + $shipping + $tax, 2);

        // Guard: redirect if cart is empty
        if (empty($items)) {
            return redirect()->route('cart')->withErrors(['cart' => 'Your cart is empty.']);
        }

        // Render: return checkout view with sanitized user and cart data
        return view('checkout', [
            'user'     => $safeUser,
            'items'    => $items,
            'subtotal' => $subtotal,
            'shipping' => $shipping,
            'tax'      => $tax,
            'total'    => $total,
        ]);
    }

    /**
     * Place order: lock cart, validate/sanitize inputs, handle payment, persist data, create order, adjust stock, and respond.
     */
    public function place(Request $request)
    {
        // Concurrency: lock cart for duration of checkout
        Cart::lock();

        try {
            // Pre-checks: auto-mark delivered; fetch user and authorize as customer
            $this->autoMarkDeliveredOrders();

            $user = Auth::user();

            if (!$user || ($user->roles ?? '') !== 'customer') {
                return redirect()->route('home');
            }

            // Normalize inputs (e.g., trim phone, billing same-as-shipping fallback)
            $data = $request->all();
            if (isset($data['phone_number'])) {
                $data['phone_number'] = preg_replace('/\s+/', '', $data['phone_number']);
            }
            if (!empty($data['is_billing_same_as_shipping'])) {
                $data['billing_street_address']  = $data['shipping_street_address']  ?? ($user->shipping_street_address ?? null);
                $data['billing_apartment_suite'] = $data['shipping_apartment_suite'] ?? ($user->shipping_apartment_suite ?? null);
                $data['billing_city']            = $data['shipping_city']            ?? ($user->shipping_city ?? null);
                $data['billing_district']        = $data['shipping_district']        ?? ($user->shipping_district ?? null);
                $data['billing_zip_code']        = $data['shipping_zip_code']        ?? ($user->shipping_zip_code ?? null);
            }

            // Validate checkout form fields
            $validated = validator($data, [
                'phone_number'                 => 'required|regex:/^[0-9]{10}$/',
                'payment_method'               => 'required|string|in:Visa/MasterCard,Koko,Mintpay,COD',
                'card_number'                  => 'nullable|string',
                'cardholder_name'              => 'nullable|string',
                'expiry_date'                  => 'nullable|string',
                'cvv'                          => 'nullable|string',
                'shipping_street_address'      => 'required|string|max:255',
                'shipping_apartment_suite'     => 'nullable|string|max:255',
                'shipping_city'                => 'required|string|max:255',
                'shipping_district'            => 'required|string|max:255',
                'shipping_zip_code'            => 'required|regex:/^[0-9]{5}$/',
                'billing_street_address'       => 'required|string|max:255',
                'billing_apartment_suite'      => 'nullable|string|max:255',
                'billing_city'                 => 'required|string|max:255',
                'billing_district'             => 'required|string|max:255',
                'billing_zip_code'             => 'required|regex:/^[0-9]{5}$/',
                'is_billing_same_as_shipping'  => 'nullable|boolean',
                'notes'                        => 'nullable|string|max:2000',
            ], [
                'phone_number.regex'       => 'Phone number must be exactly 10 digits (0-9). Spaces are allowed.',
                'shipping_zip_code.regex'  => 'Shipping ZIP must be exactly 5 digits (0-9).',
                'billing_zip_code.regex'   => 'Billing ZIP must be exactly 5 digits (0-9).',
            ])->validate();

            // Sanitize validated input fields
            $clean = $validated;
            foreach (
                [
                    'phone_number',
                    'payment_method',
                    'card_number',
                    'cardholder_name',
                    'expiry_date',
                    'cvv',
                    'shipping_street_address',
                    'shipping_apartment_suite',
                    'shipping_city',
                    'shipping_district',
                    'shipping_zip_code',
                    'billing_street_address',
                    'billing_apartment_suite',
                    'billing_city',
                    'billing_district',
                    'billing_zip_code',
                    'notes'
                ] as $k
            ) {
                if (array_key_exists($k, $clean) && $clean[$k] !== null) {
                    $clean[$k] = strip_tags((string) $clean[$k]);
                }
            }

            // Payment: card-specific validation and normalization when using Visa/MasterCard
            if (($clean['payment_method'] ?? '') === 'Visa/MasterCard') {
                if (isset($clean['card_number'])) {
                    $clean['card_number'] = preg_replace('/[^0-9 *]/', '', $clean['card_number']);
                }
                $rawCard = $clean['card_number'] ?? '';
                $isMasked = strpos($rawCard, '*') !== false;

                $rules = [
                    'cardholder_name' => 'required|string|max:255',
                    'expiry_date'     => 'required|string|max:7',
                    'cvv'             => 'required|string|min:3|max:4',
                ];
                if (!$isMasked) {
                    $rules['card_number'] = ['required', 'regex:/^[0-9 ]{12,23}$/'];
                }

                validator($clean, $rules, [
                    'card_number.regex' => 'Card number must have 12-19 digits (digits & spaces only).',
                ])->validate();

                if (!$isMasked) {
                    $digits = preg_replace('/\D/', '', $rawCard);
                    $len = strlen($digits);
                    if ($len < 12 || $len > 19) {
                        return back()->withErrors(['card_number' => 'Card number length must be 12 to 19 digits.'])->withInput();
                    }
                }
            }

            // Cart: load items and guard against empty cart
            $cartItems = \App\Support\Cart\CartFacade::items();
            if (empty($cartItems)) {
                return redirect()->route('cart')->withErrors(['cart' => 'Your cart is empty.']);
            }

            // Persist: save user profile, addresses, and payment details (MySQL)
            try {
                $isSame = (bool) ($clean['is_billing_same_as_shipping'] ?? false);

                $shipping = [
                    'shipping_street_address'  => $clean['shipping_street_address'],
                    'shipping_apartment_suite' => $clean['shipping_apartment_suite'] ?? null,
                    'shipping_city'            => $clean['shipping_city'],
                    'shipping_district'        => $clean['shipping_district'],
                    'shipping_zip_code'        => $clean['shipping_zip_code'],
                ];

                $billing = $isSame ? [
                    'billing_street_address'  => $shipping['shipping_street_address'],
                    'billing_apartment_suite' => $shipping['shipping_apartment_suite'],
                    'billing_city'            => $shipping['shipping_city'],
                    'billing_district'        => $shipping['shipping_district'],
                    'billing_zip_code'        => $shipping['shipping_zip_code'],
                ] : [
                    'billing_street_address'  => $clean['billing_street_address'],
                    'billing_apartment_suite' => $clean['billing_apartment_suite'] ?? null,
                    'billing_city'            => $clean['billing_city'],
                    'billing_district'        => $clean['billing_district'],
                    'billing_zip_code'        => $clean['billing_zip_code'],
                ];

                $user->is_billing_same_as_shipping = $isSame;
                $user->phone_number = $clean['phone_number'];
                $user->payment_method = $clean['payment_method'] ?? $user->payment_method;

                if (($clean['payment_method'] ?? '') === 'Visa/MasterCard') {
                    $rawCardInput = $clean['card_number'] ?? '';
                    $isMasked = strpos($rawCardInput, '*') !== false;
                    $digits = preg_replace('/\D/', '', $rawCardInput);

                    if ($isMasked) {
                        if ($user->card_number) {
                            // reuse existing encrypted number
                        } else {
                            return back()->withErrors(['card_number' => 'Enter full card number.'])->withInput();
                        }
                    } else {
                        if ($digits === '' || strlen($digits) < 12 || strlen($digits) > 19) {
                            return back()->withErrors(['card_number' => 'Invalid card number length.'])->withInput();
                        }
                        $user->card_number = encrypt($digits);
                    }

                    $expiryPlain = (string) ($clean['expiry_date'] ?? '');
                    if (!preg_match('/^(0[1-9]|1[0-2])\/\d{2}$/', $expiryPlain)) {
                        return back()->withErrors(['expiry_date' => 'Invalid expiry format (MM/YY).'])->withInput();
                    }
                    [$mm, $yy] = explode('/', $expiryPlain);
                    $expYear = 2000 + (int) $yy;
                    $expMonth = (int) $mm;
                    $expiryEnd = \Carbon\Carbon::create($expYear, $expMonth, 1)->endOfMonth();
                    if ($expiryEnd->lt(\Carbon\Carbon::now()->startOfDay())) {
                        return back()->withErrors(['expiry_date' => 'Card is expired.'])->withInput();
                    }

                    $holder = trim((string) ($clean['cardholder_name'] ?? ''));
                    $holder = mb_strtoupper($holder);
                    if ($holder === '') {
                        return back()->withErrors(['cardholder_name' => 'Cardholder name required.'])->withInput();
                    }

                    $user->cardholder_name = encrypt($holder);
                    $user->expiry_date     = encrypt($expiryPlain);
                    $cvvPlain = (string) ($clean['cvv'] ?? '');
                    if (!preg_match('/^[0-9]{3,4}$/', $cvvPlain)) {
                        return back()->withErrors(['cvv' => 'Invalid CVV.'])->withInput();
                    }
                    $user->cvv = encrypt($cvvPlain);
                } else {
                    $user->card_number     = null;
                    $user->cardholder_name = null;
                    $user->expiry_date     = null;
                    $user->cvv             = null;
                }

                foreach ($shipping as $k => $v) {
                    $user->$k = $v;
                }
                foreach ($billing as $k => $v) {
                    $user->$k = $v;
                }

                if ($user instanceof \App\Models\User) {
                    $user->save();
                } else {
                    return back()->withErrors(['user' => 'Failed to save user details.'])->withInput();
                }
            } catch (\Throwable $e) {
                report($e);
                return back()->withErrors(['order' => 'Failed to save your details. Please try again.'])->withInput();
            }

            // Totals: compute subtotal, shipping fee, tax, and grand total
            $subtotal    = (float) \App\Support\Cart\CartFacade::total();
            $shippingFee = 5.00;
            $tax         = round($subtotal * 0.05, 2);
            $grandTotal  = round($subtotal + $shippingFee + $tax, 2);

            // Orders: ensure Mongo configured and get connection
            try {
                $this->ensureMongoConfigured();
                $mongo = DB::connection('mongodb_orders');

                // Orders: generate unique order number
                do {
                    $orderNumber = $this->generateOrderNumber();
                    $exists = $mongo->table('orders') // changed from ->collection('orders')
                        ->where('order_number', $orderNumber)
                        ->count() > 0;
                } while ($exists);

                // Orders: build order document payload
                $orderDoc = [
                    'user_id'                     => $user->id,
                    'order_number'                => $orderNumber,
                    'customer_name'               => is_string($user->name ?? null) ? strip_tags($user->name) : ($user->name ?? null),
                    'customer_email'              => is_string($user->email ?? null) ? strip_tags($user->email) : ($user->email ?? null),
                    'customer_phone'              => $clean['phone_number'] ?? null,
                    'billing_street_address'      => $clean['billing_street_address'],
                    'billing_apartment_suite'     => $clean['billing_apartment_suite'] ?? null,
                    'billing_city'                => $clean['billing_city'],
                    'billing_district'            => $clean['billing_district'],
                    'billing_zip_code'            => $clean['billing_zip_code'],
                    'shipping_street_address'     => $clean['shipping_street_address'],
                    'shipping_apartment_suite'    => $clean['shipping_apartment_suite'] ?? null,
                    'shipping_city'               => $clean['shipping_city'],
                    'shipping_district'           => $clean['shipping_district'],
                    'shipping_zip_code'           => $clean['shipping_zip_code'],
                    'is_billing_same_as_shipping' => (bool) ($isSame ?? false),
                    'subtotal'                    => $subtotal,
                    'shipping_fee'                => $shippingFee,
                    'tax'                         => $tax,
                    'total'                       => $grandTotal,
                    'payment_method'              => $clean['payment_method'] ?? null,
                    'order_status'                => 'pending',
                    'notes'                       => $clean['notes'] ?? null,
                    'placed_at'                   => now(),
                    'created_at'                  => now(),
                    'updated_at'                  => now(),
                ];

                // Orders: insert order (MongoDB)
                $orderId = $mongo->table('orders')->insertGetId($orderDoc); // changed from ->collection('orders')

                // Inventory: begin MySQL transaction and decrement stock with concurrency checks
                DB::beginTransaction();

                // Stock decrement loop (unchanged logic)
                foreach ($cartItems as $lineId => $item) {
                    $modelId = (int) ($item['model_id']
                        ?? $item['product_model_id']
                        ?? ($item['model']['id'] ?? null));
                    $qty = (int) ($item['qty'] ?? 1);

                    if ($modelId < 1 || $qty < 1) {
                        continue;
                    }

                    $model = \App\Models\ProductModel::where('id', $modelId)->lockForUpdate()->first(['id', 'stock']);
                    if (!$model) {
                        DB::rollBack();
                        // Cleanup inserted order in Mongo
                        $mongo->table('orders')->where('order_number', $orderNumber)->delete();
                        return back()->withErrors(['stock' => 'Item not found. Please update your cart.'])->withInput();
                    }

                    $currentStock = $model->stock;
                    $available    = (int) $currentStock;

                    if ($available < $qty) {
                        DB::rollBack();
                        // Cleanup inserted order in Mongo
                        $mongo->table('orders')->where('order_number', $orderNumber)->delete();
                        return back()->withErrors(['stock' => 'One or more items no longer have enough stock. Please update your cart.'])->withInput();
                    }

                    $newStock = $available - $qty;

                    $affected = \App\Models\ProductModel::where('id', $modelId)
                        ->where('stock', $currentStock)
                        ->update(['stock' => $newStock]);

                    if ($affected !== 1) {
                        $fresh = \App\Models\ProductModel::where('id', $modelId)->lockForUpdate()->first(['stock']);
                        if ($fresh && (int) $fresh->stock >= $qty) {
                            $affected = \App\Models\ProductModel::where('id', $modelId)
                                ->where('stock', $fresh->stock)
                                ->update(['stock' => ((int) $fresh->stock) - $qty]);
                        }
                    }

                    if ($affected !== 1) {
                        DB::rollBack();
                        // Cleanup inserted order in Mongo
                        $mongo->table('orders')->where('order_number', $orderNumber)->delete();
                        return back()
                            ->withErrors(['stock' => 'One or more items no longer have enough stock. Please update your cart.'])
                            ->withInput();
                    }
                }

                DB::commit();

                // Order items: insert all items in MongoDB
                $itemsDocs = [];
                foreach ($cartItems as $item) {
                    $qty       = (int) ($item['qty'] ?? 1);
                    $unit      = (float) ($item['price'] ?? 0);
                    $lineTotal = $unit * $qty;

                    $itemsDocs[] = [
                        'order_id'          => $orderId, // Mongo _id reference
                        'order_number'      => $orderNumber, // also store order_number for simpler lookups
                        'user_id'           => $user->id,
                        'product_id'        => $item['product_id'] ?? null,
                        'product_model_id'  => $item['model_id'] ?? ($item['product_model_id'] ?? null),
                        'product_name'      => $item['name'] ?? 'Item',
                        'model_name'        => $item['model_name'] ?? null,
                        'color'             => $item['options']['color'] ?? null,
                        'image'             => $item['image'] ?? null,
                        'unit_price'        => $unit,
                        'qty'               => $qty,
                        'line_total'        => $lineTotal,
                        'created_at'        => now(),
                        'updated_at'        => now(),
                    ];
                }

                if (!empty($itemsDocs)) {
                    $mongo->table('order_items')->insert($itemsDocs); // changed from ->collection('order_items')->insertMany(...)
                }

                // Success: unlock and clear cart; redirect with confirmation
                Cart::unlock();
                Cart::clear();

                return redirect()
                    ->route('my-order')
                    ->with('status', 'Order placed: ' . $orderNumber);
            } catch (\Throwable $e) {
                // Rollback/cleanup: attempt MySQL rollback and Mongo cleanup; report and return error response
                try {
                    DB::rollBack();
                } catch (\Throwable $ignored) {
                }
                try {
                    if (!empty($orderNumber)) {
                        $mongo = DB::connection('mongodb_orders');
                        $mongo->table('order_items')->where('order_number', $orderNumber)->delete(); // changed
                        $mongo->table('orders')->where('order_number', $orderNumber)->delete();      // changed
                    }
                } catch (\Throwable $ignored) {
                }
                report($e);
                $msg = config('app.debug')
                    ? ('Failed to place order: ' . $e->getMessage())
                    : 'Failed to place order. Please try again.';
                return back()
                    ->withErrors(['order' => $msg])
                    ->withInput();
            }
        } finally {
            // Safety: always unlock cart on any path
            Cart::unlock();
        }
    }

    /**
     * Background maintenance: mark orders older than 2 months as delivered (non-blocking).
     */
    private function autoMarkDeliveredOrders()
    {
        // Compute threshold date for marking delivered
        $threshold = Carbon::now()->subMonths(2);

        try {
            // Ensure Mongo connection is configured and open
            $this->ensureMongoConfigured();
            $mongo = DB::connection('mongodb_orders');

            // Fetch undelivered orders older than threshold
            $orders = $mongo->table('orders') // changed from ->collection('orders')
                ->where('order_status', '!=', 'delivered')
                ->where('placed_at', '<', $threshold)
                ->get();

            // Update each order to delivered
            foreach ($orders as $order) {
                $mongo->table('orders') // changed
                    ->where('_id', $order['_id'])
                    ->update([
                        'order_status' => 'delivered',
                        'updated_at'   => now(),
                    ]);
            }
        } catch (\Throwable $e) {
            // Non-blocking: log and continue without affecting checkout
            report($e);
        }
    }

    /**
     * Generate a unique order number.
     */
    private function generateOrderNumber(): string
    {
        // Generate formatted order number; uniqueness enforced by pre-insert check
        return 'BC-' . now()->format('Ymd') . '-' . Str::upper(Str::random(6));
    }

    /**
     * Ensure the MongoDB orders connection is configured at runtime.
     */
    private function ensureMongoConfigured(): void
    {
        // Provide connection config if missing (driver, DSN/host, credentials, options)
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
    }
}
