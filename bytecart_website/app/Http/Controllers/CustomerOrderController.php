<?php

/**
 * CustomerOrderController
 *
 * Allows customers to manage their orders:
 * - Cancel orders (with stock restoration) before they are processed
 * - Mark orders as delivered when eligible
 * Enforces customer ownership, updates status in MongoDB, and returns flash messages.
 */

namespace App\Http\Controllers;

use App\Models\Order;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class CustomerOrderController extends Controller
{
    /**
     * Cancel an order: authorize, enforce status rules, restore stock, update status, and respond.
     */
    public function cancel(Request $request, Order $order)
    {
        $user = Auth::user();
        // Authorization: require authenticated customer who owns the order
        if (!$user || ($user->roles ?? '') !== 'customer' || (int)$order->user_id !== (int)$user->id) {
            abort(403);
        }

        // Transition rule: disallow cancel once shipped/out for delivery/delivered/canceled
        if (in_array($order->order_status, ['shipped', 'out for delivery', 'delivered', 'canceled'], true)) {
            return back()->withErrors(['status' => 'Order cannot be canceled at this stage.']);
        }

        // Inventory: restore stock within a MySQL transaction
        DB::connection('mysql')->transaction(function () use ($order) {
            $this->revertStock($order);
        });

        // Persistence: set order status to canceled in Mongo
        $order->order_status = 'canceled';
        $order->save();

        // Response: return sanitized confirmation message
        $cleanOrderNumber = strip_tags((string) $order->order_number);
        return back()->with('status', 'Order #' . $cleanOrderNumber . ' has been canceled.');
    }

    /**
     * Mark an order as delivered when eligible and respond with confirmation.
     */
    public function markDelivered(Request $request, Order $order)
    {
        $user = Auth::user();
        // Authorization: require authenticated customer who owns the order
        if (!$user || ($user->roles ?? '') !== 'customer' || (int)$order->user_id !== (int)$user->id) {
            abort(403);
        }

        // Transition rule: only allow when shipped or out for delivery
        if (!in_array($order->order_status, ['out for delivery', 'shipped'], true)) {
            return back()->withErrors(['status' => 'You can only mark orders as delivered after they are shipped.']);
        }

        // Persistence: update status to delivered in Mongo
        $order->order_status = 'delivered';
        $order->save();

        // Response: return sanitized thank-you message
        $cleanOrderNumber = strip_tags((string) $order->order_number);
        return back()->with('status', 'Thanks! Order #' . $cleanOrderNumber . ' marked as delivered.');
    }

    /**
     * Restore inventory for each order item (variant first, then product).
     */
    private function revertStock(Order $order): void
    {
        // Ensure items relation is loaded
        $order->loadMissing('items');

        foreach ($order->items as $item) {
            $qty = (int) ($item->qty ?? 0);
            // Skip non-positive quantities
            if ($qty <= 0) {
                continue;
            }

            // Variant-level stock increment (preferred)
            if (!empty($item->product_model_id)) {
                $this->incrementFirstAvailableStockColumn('product_models', (int)$item->product_model_id, $qty);
            }

            // Product-level stock increment (also/fallback)
            if (!empty($item->product_id)) {
                $this->incrementFirstAvailableStockColumn('products', (int)$item->product_id, $qty);
            }
        }
    }

    /**
     * Increment the first available stock-like column for a row.
     * Tries (in order): stock, available_stock, inventory, quantity, qty, stock_qty, in_stock
     */
    private function incrementFirstAvailableStockColumn(string $table, int $id, int $qty): void
    {
        // Validate inputs and ensure target row exists
        if ($id <= 0 || $qty <= 0) return;
        if (!DB::table($table)->where('id', $id)->exists()) return;

        // Try known stock columns in order and increment the first found
        $candidates = ['stock', 'available_stock', 'inventory', 'quantity', 'qty', 'stock_qty', 'in_stock'];

        foreach ($candidates as $col) {
            if (Schema::hasColumn($table, $col)) {
                DB::table($table)->where('id', $id)->increment($col, $qty);
                break;
            }
        }
    }
}
