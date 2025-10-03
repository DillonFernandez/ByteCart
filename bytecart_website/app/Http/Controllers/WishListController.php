<?php

/**
 * WishListController
 *
 * Manages a user's wish list:
 * - Add products (idempotent)
 * - Remove products
 * - Check if a product exists in the wish list
 * Enforces authentication, sanitizes inputs, and returns JSON responses.
 */

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\WishList;
use App\Models\Products;
use Illuminate\Support\Facades\Auth;

class WishListController extends Controller
{
    /**
     * Add a product to the authenticated user's wish list.
     */
    public function add(Request $request)
    {
        // Authorization & input: get user and sanitize product_id
        $user = Auth::user();
        $productIdRaw = trim(strip_tags((string) $request->input('product_id')));
        $productId = ctype_digit($productIdRaw) ? (int)$productIdRaw : 0;

        // Guard: require authenticated user and valid product id
        if (!$user || $productId <= 0) {
            return response()->json(['error' => 'Unauthorized or missing product'], 401);
        }

        // Idempotency: check if already in wish list
        $exists = WishList::where('user_id', $user->id)->where('product_id', $productId)->first();
        if ($exists) {
            return response()->json(['success' => false, 'message' => 'Already in wish list']);
        }

        // Persist: create wish list record
        WishList::create([
            'user_id' => $user->id,
            'product_id' => $productId,
        ]);

        // Respond: JSON success
        return response()->json(['success' => true]);
    }

    /**
     * Remove a product from the authenticated user's wish list.
     */
    public function remove(Request $request)
    {
        // Authorization & input: get user and sanitize product_id
        $user = Auth::user();
        $productIdRaw = trim(strip_tags((string) $request->input('product_id')));
        $productId = ctype_digit($productIdRaw) ? (int)$productIdRaw : 0;

        // Guard: require authenticated user and valid product id
        if (!$user || $productId <= 0) {
            return response()->json(['error' => 'Unauthorized or missing product'], 401);
        }

        // Persist: delete wish list record
        WishList::where('user_id', $user->id)->where('product_id', $productId)->delete();

        // Respond: JSON success
        return response()->json(['success' => true]);
    }

    /**
     * Check if a product is in the authenticated user's wish list.
     */
    public function check(Request $request)
    {
        // Authorization & input: get user and sanitize product_id
        $user = Auth::user();
        $productIdRaw = trim(strip_tags((string) $request->input('product_id')));
        $productId = ctype_digit($productIdRaw) ? (int)$productIdRaw : 0;

        // Guard: unauthenticated/invalid => not in wish list
        if (!$user || $productId <= 0) {
            return response()->json(['in_wish_list' => false]);
        }

        // Lookup & respond: existence boolean
        $exists = WishList::where('user_id', $user->id)->where('product_id', $productId)->exists();
        return response()->json(['in_wish_list' => $exists]);
    }
}
