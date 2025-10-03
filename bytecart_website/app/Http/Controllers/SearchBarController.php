<?php

/**
 * SearchBarController
 *
 * Provides product suggestions for the search bar:
 * - Sanitizes input query
 * - Searches products by name, brand, or category
 * - Formats and sanitizes results for JSON response
 */

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class SearchBarController extends Controller
{
    /**
     * Return product suggestions based on sanitized search query.
     */
    public function suggest(Request $request)
    {
        // Input: sanitize and process query string
        $query = trim(strip_tags((string) $request->input('q', '')));
        if (strlen($query) < 2) {
            return response()->json([]);
        }

        // Split and sanitize each word in the query
        $words = preg_split('/\s+/', $query);
        $words = array_values(array_filter(array_map(function ($w) {
            return trim(strip_tags((string) $w));
        }, $words), fn($w) => $w !== ''));

        // Build product query using sanitized words
        $products = \App\Models\Products::query();
        foreach ($words as $word) {
            $products->where(function ($q) use ($word) {
                $q->where('product_name', 'like', "%$word%")
                    ->orWhere('brand_name', 'like', "%$word%")
                    ->orWhere('product_category', 'like', "%$word%");
            });
        }

        // Fetch results with models
        $results = $products->with('models')->limit(8)->get();

        // Sanitize and format fields for JSON response
        $data = $results->map(function ($product) {
            $minPrice = $product->models->min('price');
            $maxPrice = $product->models->max('price');
            $discount = $product->discount ?? 0;
            $discountedMin = $discount > 0 ? round($minPrice * (1 - $discount / 100), 2) : $minPrice;
            $discountedMax = $discount > 0 ? round($maxPrice * (1 - $discount / 100), 2) : $maxPrice;

            return [
                'id' => $product->id,
                'product_name' => strip_tags((string) $product->product_name),
                'brand_name' => strip_tags((string) $product->brand_name),
                'image' => is_string($product->image) ? strip_tags($product->image) : $product->image,
                'min_price' => $minPrice,
                'max_price' => $maxPrice,
                'discount' => $discount,
                'discounted_min' => $discountedMin,
                'discounted_max' => $discountedMax,
            ];
        });

        // Respond with suggestions
        return response()->json($data);
    }
}
