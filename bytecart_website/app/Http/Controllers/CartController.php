<?php

/**
 * CartController
 *
 * Manages cart lifecycle operations:
 * - View cart
 * - Add items (with validation, sanitization, and stock checks)
 * - Update quantities
 * - Remove items
 * - Clear cart
 */

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\ProductModel;
use App\Support\Cart\CartFacade as Cart;

class CartController extends Controller
{
    /**
     * Render the cart: fetch items, sanitize option values, compute totals, and display the view.
     */
    public function index()
    {
        $items = Cart::items();
        // Sanitize user-submitted option values before rendering
        if (is_array($items)) {
            $items = array_map(function ($item) {
                if (is_array($item) && isset($item['options']) && is_array($item['options']) && isset($item['options']['color'])) {
                    $item['options']['color'] = strip_tags((string) $item['options']['color']);
                }
                return $item;
            }, $items);
        }
        $total = Cart::total();
        $count = Cart::count();

        return view('cart', compact('items', 'total', 'count'));
    }

    /**
     * Add a product model to the cart (validate, sanitize, stock-check, and respond with JSON).
     */
    public function add(Request $request)
    {
        // Validate request payload
        $data = $request->validate([
            // changed from string (Mongo style) to integer + exists for MySQL
            'model_id' => ['required', 'integer', 'exists:product_models,id'],
            'qty'      => ['required', 'integer', 'min:1'],
            'color'    => ['nullable', 'string', 'max:50'],
        ]);

        // Normalize and sanitize inputs (model_id, color)
        $data['model_id'] = (int) $data['model_id'];
        if (array_key_exists('color', $data) && $data['color'] !== null) {
            $data['color'] = strip_tags((string) $data['color']);
        }

        // Load model and derive requested quantity
        $model = ProductModel::findOrFail($data['model_id']);
        $qty = (int) $data['qty'];

        // Check available stock before adding to cart
        if (!is_null($model->stock) && (int) $model->stock < $qty) {
            return response()->json([
                'success' => false,
                'message' => 'Requested quantity exceeds available stock.',
            ], 422);
        }

        // Build options payload (e.g., color)
        $options = [];
        if (isset($data['color']) && $data['color'] !== '') {
            $options['color'] = $data['color'];
        }

        // Add to cart and return JSON response
        Cart::add($model->getKey(), $qty, $options);

        return response()->json([
            'success'    => true,
            'message'    => 'Added to cart.',
            'cart_count' => Cart::count(),
            'cart_total' => Cart::total(),
        ]);
    }

    /**
     * Update the quantity of a cart line (validate, check existence/stock, apply, redirect).
     */
    public function updateQty(Request $request)
    {
        // Validate request payload
        $data = $request->validate([
            'line_id' => ['required', 'string'],
            'qty'     => ['required', 'integer', 'min:1'],
        ]);

        // Sanitize line identifier
        $data['line_id'] = strip_tags((string) $data['line_id']);

        $items = Cart::items();
        // Ensure the cart line exists
        if (!isset($items[$data['line_id']])) {
            return redirect()->route('cart')->withErrors(['cart' => 'Cart line not found.']);
        }

        // Optionally verify stock for the new quantity
        $modelId = $items[$data['line_id']]['model_id'] ?? null;
        if ($modelId) {
            $model = ProductModel::find($modelId);
            if ($model && !is_null($model->stock) && (int) $model->stock < (int) $data['qty']) {
                return back()
                    ->withErrors(['qty' => 'Requested quantity exceeds available stock.'])
                    ->withInput();
            }
        }

        // Apply update and redirect with status
        Cart::updateQty($data['line_id'], (int) $data['qty']);

        return redirect()->route('cart')->with('status', 'Quantity updated.');
    }

    /**
     * Remove a line from the cart (validate, sanitize, remove, redirect).
     */
    public function remove(Request $request)
    {
        // Validate and sanitize line identifier
        $data = $request->validate([
            'line_id' => ['required', 'string'],
        ]);
        $data['line_id'] = strip_tags((string) $data['line_id']);

        // Remove item and redirect with status
        Cart::remove($data['line_id']);

        return redirect()->route('cart')->with('status', 'Item removed.');
    }

    /**
     * Clear all items from the cart and redirect with status.
     */
    public function clear()
    {
        // Clear cart and redirect
        Cart::clear();

        return redirect()->route('cart')->with('status', 'Cart cleared.');
    }
}
