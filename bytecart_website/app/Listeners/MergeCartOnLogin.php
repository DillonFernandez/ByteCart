<?php

/**
 * MergeCartOnLogin
 *
 * Merges session cart items into the authenticated user's persistent cart on login:
 * - No-op if session cart is empty
 * - Create or load the user's cart
 * - Skip merge if cart is locked (checkout in progress)
 * - Merge quantities per model
 * - Recalculate totals when supported
 * - Persist and clear session cart
 */

namespace App\Listeners;

use Illuminate\Auth\Events\Login;
use App\Models\UserCart;
use Illuminate\Support\Facades\Schema;

class MergeCartOnLogin
{
    /**
     * Handle login event by merging session cart into the user's stored cart.
     */
    public function handle(Login $event): void
    {
        // Early exit: nothing to merge
        $sessionItems = session('cart.items', []);
        if (empty($sessionItems)) {
            return;
        }

        // Resolve user id and load/create persistent cart
        $userId = (int) $event->user->getAuthIdentifier();
        $cart = UserCart::firstOrCreate(
            ['user_id' => $userId],
            ['items' => [], 'subtotal' => 0, 'total' => 0, 'locked' => false]
        );

        // Guard: skip merge if cart is locked (e.g., during checkout)
        if ($cart->locked) {
            session()->forget('cart.items');
            return;
        }

        // Merge session items into existing cart items (sum quantities per model)
        $items = is_array($cart->items) ? $cart->items : [];
        foreach ($sessionItems as $modelId => $payload) {
            if (isset($items[$modelId])) {
                $items[$modelId]['qty'] = (int) ($items[$modelId]['qty'] ?? 0) + (int) ($payload['qty'] ?? 0);
            } else {
                $items[$modelId] = $payload;
            }
        }
        $cart->items = $items;

        // Recalculate totals if columns exist and cart service supports it
        if (Schema::hasColumn('user_carts', 'subtotal') && Schema::hasColumn('user_carts', 'total')) {
            $cartService = app('cart');
            if (method_exists($cartService, 'calculateSubAndGrandTotals')) {
                [$sub, $grand] = $cartService->calculateSubAndGrandTotals($items);
                $cart->subtotal = $sub;
                $cart->total = $grand;
            }
        }

        // Persist merged cart and clear session cart
        $cart->save();
        session()->forget('cart.items');
    }
}
