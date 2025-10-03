<?php

/**
 * ProductModelController
 *
 * Manages product models (variants):
 * - Create, update, and delete models for products
 * Validates inputs and sanitizes fields before persistence.
 */

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\ProductModel;

class ProductModelController extends Controller
{
    /**
     * Store a new product model (variant).
     */
    public function store(Request $request)
    {
        // Validate: incoming model fields and product reference
        $data = $request->validate([
            // changed from string to integer exists for MySQL
            'product_id' => 'required|integer|exists:products,id',
            'model_name' => 'required|string',
            'price' => 'required|numeric',
            'stock' => 'required|integer',
            'colors' => 'nullable|string',
            'images' => 'nullable|array',
        ]);

        // Normalize/sanitize: cast IDs, strip tags, clean images
        // MySQL FK cast
        $data['product_id'] = (int) $data['product_id'];
        $data['model_name'] = strip_tags((string)$data['model_name']);
        if (array_key_exists('colors', $data) && $data['colors'] !== null) {
            $data['colors'] = strip_tags((string)$data['colors']);
        }
        if (array_key_exists('images', $data) && is_array($data['images'])) {
            $data['images'] = array_map(fn($v) => is_string($v) ? strip_tags($v) : $v, $data['images']);
        }

        // Persist: create model and redirect
        $data['images'] = json_encode($data['images'] ?? []);
        ProductModel::create($data);
        return redirect()->route('manage-products');
    }

    /**
     * Update an existing product model.
     */
    public function update(Request $request, $id)
    {
        // Load: target model
        $model = ProductModel::findOrFail($id);

        // Validate: editable fields
        $data = $request->validate([
            'model_name' => 'required|string',
            'price' => 'required|numeric',
            'stock' => 'required|integer',
            'colors' => 'nullable|string',
            'images' => 'nullable|array',
        ]);

        // Sanitize: strip tags and clean images
        // Sanitize inputs before saving
        $data['model_name'] = strip_tags((string)$data['model_name']);
        if (array_key_exists('colors', $data) && $data['colors'] !== null) {
            $data['colors'] = strip_tags((string)$data['colors']);
        }
        if (array_key_exists('images', $data) && is_array($data['images'])) {
            $data['images'] = array_map(fn($v) => is_string($v) ? strip_tags($v) : $v, $data['images']);
        }

        // Persist: update and redirect
        $data['images'] = json_encode($data['images'] ?? []);
        $model->update($data);
        return redirect()->route('manage-products');
    }

    /**
     * Delete a product model.
     */
    public function destroy($id)
    {
        // Delete: remove model and redirect
        ProductModel::findOrFail($id)->delete();
        return redirect()->route('manage-products');
    }
}
