<?php

/**
 * AdminOrderController
 *
 * Manages admin-only order status updates and related inventory adjustments.
 * - Validates and sanitizes inputs
 * - Enforces allowed status transitions
 * - Reverts stock on cancellation within a MySQL transaction
 * - Persists order status to Mongo and returns user-facing feedback
 */

namespace App\Http\Controllers;

use App\Models\Order;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class AdminOrderController extends Controller
{
    /**
     * Update order status (admin only): authorize, validate, apply transitions, adjust stock, persist, respond.
     */
    public function updateStatus(Request $request, Order $order)
    {
        // Authorization: require authenticated admin
        $user = Auth::user();
        if (!$user || !in_array('admin', (array)($user->roles ?? []))) {
            abort(403);
        }

        // Input: validate and sanitize desired status
        $data = $request->validate([
            'status' => 'required|string|in:shipped,out for delivery,delivered,canceled',
        ]);
        $data['status'] = strip_tags((string) $data['status']);

        // Transition rules: block updates to delivered/canceled; allow cancel if not already canceled
        if (in_array($order->order_status, ['delivered', 'canceled'], true)) {
            if ($data['status'] === 'canceled' && $order->order_status !== 'canceled') {
                // allowed
            } else {
                return back()->withErrors(['status' => 'Cannot update a ' . strip_tags((string) $order->order_status) . ' order.']);
            }
        }

        $prevStatus = (string) $order->order_status;

        // Inventory: if canceling, revert stock in a MySQL transaction
        if ($data['status'] === 'canceled' && $prevStatus !== 'canceled') {
            DB::connection('mysql')->transaction(function () use ($order) {
                $this->revertStock($order);
            });
        }

        // Persistence: save new status (Mongo)
        $order->order_status = $data['status'];
        $order->save();

        // Response: flash sanitized confirmation message
        $cleanOrderNumber = strip_tags((string) $order->order_number);
        $cleanStatus = ucwords(strip_tags((string) $order->order_status));

        return back()->with('status', 'Order #' . $cleanOrderNumber . ' set to ' . $cleanStatus . '.');
    }

    /**
     * Restore inventory for each order item (variant first, then product).
     */
    private function revertStock(Order $order): void
    {
        // Ensure items relation is loaded
        $order->loadMissing('items');

        foreach ($order->items as $item) {
            // Skip invalid quantities
            $qty = (int) ($item->qty ?? 0);
            if ($qty <= 0) {
                continue;
            }

            // Variant-level stock adjustment (preferred when product_model_id exists)
            if (!empty($item->product_model_id)) {
                $this->incrementFirstAvailableStockColumn('product_models', (int)$item->product_model_id, $qty);
            }

            // Product-level stock adjustment (also/fallback when product_id exists)
            if (!empty($item->product_id)) {
                $this->incrementFirstAvailableStockColumn('products', (int)$item->product_id, $qty);
            }
        }
    }

    /**
     * Increment the first available stock-like column for a row.
     * Columns tried (in order): stock, available_stock, inventory, quantity, qty, stock_qty, in_stock
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
