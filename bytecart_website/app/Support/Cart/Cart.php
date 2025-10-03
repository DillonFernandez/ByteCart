<?php

namespace App\Support\Cart;

use Illuminate\Support\Facades\Session;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Schema;
use App\Models\ProductModel;
use App\Models\Products;
use App\Models\UserCart;

class Cart
{
    protected string $sessionKey = 'cart.items';

    protected float $shippingFlat = 5.00;
    protected float $taxRate = 0.05;

    protected function isAuthenticated(): bool
    {
        return Auth::check();
    }

    protected function userCart(): ?UserCart
    {
        if (!$this->isAuthenticated()) {
            return null;
        }
        $user = Auth::user();
        if (!$user) {
            return null;
        }
        // changed to store integer user_id for MySQL
        return UserCart::firstOrCreate(
            ['user_id' => (int) $user->getAuthIdentifier()], // ensure int
            ['items' => [], 'subtotal' => 0, 'total' => 0, 'locked' => false]
        );
    }

    public function items(): array
    {
        if ($this->isAuthenticated()) {
            $cart = $this->userCart();
            return $cart ? ($cart->items ?? []) : [];
        }

        return Session::get($this->sessionKey, []);
    }

    protected function computeSubTotal(array $items): float
    {
        return array_reduce($items, fn($c, $i) => $c + ((float)$i['price'] * (int)$i['qty']), 0.0);
    }

    protected function computeGrandTotal(float $subTotal): float
    {
        if ($subTotal <= 0) {
            return 0.0;
        }
        return $subTotal + $this->shippingFlat + ($subTotal * $this->taxRate);
    }

    public function calculateSubAndGrandTotals(array $items): array
    {
        $sub = $this->computeSubTotal($items);
        $grand = $this->computeGrandTotal($sub);
        return [$sub, $grand];
    }

    protected function applyTotals(?UserCart $cart, array $items): void
    {
        if (!$cart) return;
        if (!Schema::hasColumn('user_carts', 'subtotal') || !Schema::hasColumn('user_carts', 'total')) {
            // Columns not present yet (migration not run) -> skip
            $cart->save();
            return;
        }
        [$sub, $grand] = $this->calculateSubAndGrandTotals($items);
        $cart->subtotal = $sub;
        $cart->total = $grand;
        $cart->save();
    }

    protected function putItems(array $items): void
    {
        if ($this->isAuthenticated()) {
            $cart = $this->userCart();
            if ($cart) {
                if ($cart->locked) return; // respect lock
                $cart->items = $items;
                $this->applyTotals($cart, $items);
            }
            return;
        }

        Session::put($this->sessionKey, $items);
    }

    protected function normalizeOptions(array $options): array
    {
        $normalized = [];
        foreach ($options as $k => $v) {
            if (is_string($v)) {
                $normalized[$k] = trim(mb_strtolower($v));
            } else {
                $normalized[$k] = $v;
            }
        }
        ksort($normalized);
        return $normalized;
    }

    protected function makeLineKey(int|string $modelId, array $options): string
    {
        // accepts int or string; cast to string for key
        $norm = $this->normalizeOptions($options);
        return (string)$modelId . ':' . md5(json_encode($norm));
    }

    /**
     * Add a product variant (ProductModel) to the cart (MySQL integer IDs).
     *
     * @param int $productModelId
     * @param int $qty
     * @param array $options
     */
    public function add(int $productModelId, int $qty = 1, array $options = []): void
    {
        $items  = $this->items();
        $lineId = $this->makeLineKey($productModelId, $options);

        if (isset($items[$lineId])) {
            $items[$lineId]['qty'] += $qty;
            $this->putItems($items);
            return;
        }

        $model   = ProductModel::findOrFail($productModelId);
        $product = $model->product;

        $basePrice  = (float) $model->price;
        $discount   = (float) ($product?->discount ?? 0);
        $finalPrice = $discount > 0
            ? round($basePrice * (1 - $discount / 100), 2)
            : $basePrice;

        $items[$lineId] = [
            'line_id'    => $lineId,
            // changed to store integer IDs (no string casting)
            'model_id'   => (int) $model->getKey(),
            'product_id' => $product ? (int) $product->getKey() : null,
            'name'       => $product?->product_name ?? $model->model_name ?? 'Item',
            'model_name' => $model->model_name,
            'image'      => $product?->image ?? null,
            'price'      => $finalPrice,
            'qty'        => $qty,
            'options'    => $options,
        ];

        $this->putItems($items);
    }

    /**
     * Update quantity for a specific cart line.
     *
     * @param string $lineId The cart line key (model_id + options hash)
     */
    public function updateQty(string $lineId, int $qty): void
    {
        $items = $this->items();

        if (!isset($items[$lineId])) {
            return;
        }

        if ($qty <= 0) {
            unset($items[$lineId]);
        } else {
            $items[$lineId]['qty'] = $qty;
        }

        $this->putItems($items);
    }

    /**
     * Remove a specific cart line.
     *
     * @param string $lineId The cart line key (model_id + options hash)
     */
    public function remove(string $lineId): void
    {
        $items = $this->items();
        unset($items[$lineId]);
        $this->putItems($items);
    }

    public function clear(): void
    {
        if ($this->isAuthenticated()) {
            $cart = $this->userCart();
            if ($cart && !$cart->locked) { // skip if locked
                $cart->items = [];
                if (Schema::hasColumn('user_carts', 'subtotal')) {
                    $cart->subtotal = 0;
                }
                if (Schema::hasColumn('user_carts', 'total')) {
                    $cart->total = 0;
                }
                $cart->save();
            }
        }
        Session::forget($this->sessionKey);
    }

    public function total(): float
    {
        return collect($this->items())->reduce(
            fn(float $carry, array $i) => $carry + ((float) $i['price'] * (int) $i['qty']),
            0.0
        );
    }

    public function count(): int
    {
        return array_sum(array_map(fn($i) => (int) $i['qty'], $this->items()));
    }

    // Lock the authenticated user's cart (no-op for guests)
    public function lock(): bool
    {
        $cart = $this->userCart();
        return $cart ? $cart->lock() : true;
    }

    // Unlock the authenticated user's cart (no-op for guests)
    public function unlock(): bool
    {
        $cart = $this->userCart();
        return $cart ? $cart->unlock() : true;
    }
}
