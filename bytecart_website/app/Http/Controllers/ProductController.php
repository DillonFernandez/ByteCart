<?php

/**
 * ProductController
 *
 * Manages product CRUD for admins and product listings for the shop:
 * - Admin: list/filter, create (with image/models), update (upsert models), delete
 * - Shop: list/filter/sort products and show product details
 * Ensures inputs are validated and sanitized before persistence or rendering.
 */

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Products;
use App\Models\ProductModel;

class ProductController extends Controller
{
    /**
     * Admin listing: filterable product list with related models.
     */
    public function index(Request $request)
    {
        // Build base query
        $query = Products::with('models');

        // Sanitize and apply filters (search, category, brand, new_stock, discounted)
        $search   = $request->filled('search') ? strip_tags((string)$request->search) : null;
        $category = $request->filled('category') ? strip_tags((string)$request->category) : null;
        $brand    = $request->filled('brand') ? strip_tags((string)$request->brand) : null;

        if ($search) {
            $query->where('product_name', 'like', '%' . $search . '%');
        }
        if ($category) {
            $query->where('product_category', $category);
        }
        if ($brand) {
            $query->where('brand_name', $brand);
        }
        if ($request->filled('new_stock')) {
            $query->where('new_stock', (bool)$request->new_stock);
        }
        if ($request->filled('discounted')) {
            if ($request->discounted == '1') {
                $query->where(function ($q) {
                    $q->where('discount', '>', 0);
                });
            } elseif ($request->discounted == '0') {
                $query->where(function ($q) {
                    $q->where('discount', '=', 0)->orWhereNull('discount');
                });
            }
        }

        // Execute query
        $products = $query->get();

        // Sanitize attributes for safe rendering (product + models)
        $sanitize = fn($v) => is_string($v) ? strip_tags($v) : $v;
        $products = $products->map(function ($p) use ($sanitize) {
            $p->product_name     = $sanitize($p->product_name);
            $p->brand_name       = $sanitize($p->brand_name);
            $p->product_category = $sanitize($p->product_category);
            $p->description      = $sanitize($p->description);
            $p->specification    = $sanitize($p->specification);
            if ($p->relationLoaded('models') && $p->models) {
                $p->models->transform(function ($m) use ($sanitize) {
                    $m->model_name = $sanitize($m->model_name);
                    $m->colors     = $sanitize($m->colors);
                    return $m;
                });
            }
            return $p;
        });

        // Render admin management view
        return view('manage-products', compact('products'));
    }

    /**
     * Create a product and its models (validate, sanitize, handle image, persist).
     */
    public function store(Request $request)
    {
        // Validate request payload
        try {
            $data = $request->validate([
                'product_name' => 'required|string',
                'brand_name' => 'required|string',
                'product_category' => 'required|string',
                'description' => 'nullable|string',
                'specification' => 'nullable|string',
                'discount' => 'nullable|numeric|min:0|max:100',
                'image' => 'required|file|mimes:webp',
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            if ($request->expectsJson()) {
                return response()->json(['errors' => $e->errors()], 422);
            }
            throw $e;
        }

        // Sanitize inputs before saving
        $data['product_name']     = strip_tags((string)$data['product_name']);
        $data['brand_name']       = strip_tags((string)$data['brand_name']);
        $data['product_category'] = strip_tags((string)$data['product_category']);
        if (array_key_exists('description', $data) && $data['description'] !== null) {
            $data['description'] = strip_tags((string)$data['description']);
        }
        if (array_key_exists('specification', $data) && $data['specification'] !== null) {
            $data['specification'] = strip_tags((string)$data['specification']);
        }

        // Normalize boolean/discount fields
        $data['new_stock'] = $request->boolean('new_stock');
        $data['discount'] = isset($data['discount']) && $data['discount'] !== '' ? $data['discount'] : 0;

        // Handle product image upload
        if ($request->hasFile('image')) {
            $imgFile = $request->file('image');
            if ($imgFile->isValid()) {
                $filename = uniqid() . '.' . $imgFile->getClientOriginalExtension();
                $imgFile->move(public_path('product-images'), $filename);
                $data['image'] = 'product-images/' . $filename;
            }
        }

        // Persist product and optional models
        try {
            $product = Products::create($data);

            if ($request->has('models')) {
                foreach ($request->models as $model) {
                    \App\Models\ProductModel::create([
                        'product_id' => $product->id,
                        'model_name' => isset($model['model_name']) ? strip_tags((string)$model['model_name']) : '',
                        'price'      => $model['price'],
                        'stock'      => $model['stock'],
                        'colors'     => isset($model['colors']) ? strip_tags((string)$model['colors']) : '',
                    ]);
                }
            }

            // Respond (JSON or redirect)
            if ($request->expectsJson()) {
                return response()->json(['success' => true, 'product_id' => $product->id]);
            }
            return redirect()->route('manage-products');
        } catch (\Exception $ex) {
            if ($request->expectsJson()) {
                return response()->json(['error' => $ex->getMessage()], 500);
            }
            return redirect()->route('manage-products')->with('error', 'Create failed.');
        }
    }

    /**
     * Update a product and upsert its models.
     */
    public function update(Request $request, $id)
    {
        // Load product with models
        $product = Products::with('models')->findOrFail($id);

        // Validate request including nested models
        try {
            $data = $request->validate([
                'product_name' => 'required|string',
                'brand_name' => 'required|string',
                'product_category' => 'required|string',
                'description' => 'nullable|string',
                'specification' => 'nullable|string',
                'discount' => 'nullable|numeric|min:0|max:100',
                'image' => 'nullable|file|mimes:webp',
                'models' => 'nullable|array',
                'models.*.id' => 'nullable|integer|exists:product_models,id',
                'models.*.model_name' => 'required|string',
                'models.*.price' => 'required|numeric',
                'models.*.stock' => 'required|integer',
                'models.*.colors' => 'nullable|string',
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            if ($request->expectsJson()) {
                return response()->json(['errors' => $e->errors()], 422);
            }
            throw $e;
        }

        // Sanitize inputs before saving
        $data['product_name']     = strip_tags((string)$data['product_name']);
        $data['brand_name']       = strip_tags((string)$data['brand_name']);
        $data['product_category'] = strip_tags((string)$data['product_category']);
        if (array_key_exists('description', $data) && $data['description'] !== null) {
            $data['description'] = strip_tags((string)$data['description']);
        }
        if (array_key_exists('specification', $data) && $data['specification'] !== null) {
            $data['specification'] = strip_tags((string)$data['specification']);
        }

        // Normalize boolean/discount and handle image upload
        $data['discount'] = isset($data['discount']) && $data['discount'] !== '' ? $data['discount'] : 0;
        $data['new_stock'] = $request->boolean('new_stock');

        if ($request->hasFile('image')) {
            $imgFile = $request->file('image');
            if ($imgFile->isValid()) {
                $filename = uniqid() . '.' . $imgFile->getClientOriginalExtension();
                $imgFile->move(public_path('product-images'), $filename);
                $data['image'] = 'product-images/' . $filename;
            }
        }

        // Persist product changes
        try {
            $product->update($data);

            // Upsert incoming models and remove omitted ones
            if ($request->has('models')) {
                $incoming = $request->input('models', []);
                $keepIds = [];

                foreach ($incoming as $m) {
                    $payload = [
                        'model_name' => strip_tags((string)($m['model_name'] ?? '')),
                        'price'      => isset($m['price']) ? (float)$m['price'] : 0,
                        'stock'      => isset($m['stock']) ? (int)$m['stock'] : 0,
                        'colors'     => isset($m['colors']) ? strip_tags((string)$m['colors']) : '',
                    ];

                    if (!empty($m['id'])) {
                        // Update existing model only if it belongs to this product
                        $existing = \App\Models\ProductModel::where('product_id', $product->id)
                            ->where('id', (int)$m['id'])
                            ->first();

                        if ($existing) {
                            $existing->update($payload);
                            $keepIds[] = (int)$existing->id;
                            continue;
                        }
                    }

                    // Create new model
                    $created = \App\Models\ProductModel::create(array_merge($payload, [
                        'product_id' => (int)$product->id,
                    ]));
                    $keepIds[] = (int)$created->id;
                }

                // Delete models that were removed in the UI
                if (!empty($keepIds)) {
                    \App\Models\ProductModel::where('product_id', $product->id)
                        ->whereNotIn('id', $keepIds)
                        ->delete();
                } else {
                    // If models array is empty, remove all
                    $product->models()->delete();
                }
            }

            // Respond (JSON or redirect)
            if ($request->expectsJson()) {
                return response()->json(['success' => true]);
            }
            return redirect()->route('manage-products');
        } catch (\Exception $ex) {
            if ($request->expectsJson()) {
                return response()->json(['error' => $ex->getMessage()], 500);
            }
            return redirect()->route('manage-products')->with('error', 'Update failed.');
        }
    }

    /**
     * Delete a product and its related models.
     */
    public function destroy($id)
    {
        // Remove product and relations, then respond
        $product = Products::findOrFail($id);
        $product->models()->delete();
        $product->delete();

        if (request()->expectsJson()) {
            return response()->json(['success' => true]);
        }
        return redirect()->route('manage-products');
    }

    /**
     * Shop listing: filter, sort, and display products with model-based constraints.
     */
    public function shop(Request $request)
    {
        // Build base query with relations
        $query = Products::with('models');

        // Sanitize and apply top-level filters (category, brand, new_stock, discounted, newest)
        $category     = $request->filled('category') ? strip_tags((string)$request->category) : null;
        $brand        = $request->filled('brand') ? strip_tags((string)$request->brand) : null;
        $discounted   = $request->filled('discounted') ? strip_tags((string)$request->discounted) : null;
        $newest       = $request->filled('newest') ? strip_tags((string)$request->newest) : null;
        $availability = $request->filled('availability') ? strip_tags((string)$request->availability) : null;
        $colorFilter  = $request->filled('color') ? strip_tags((string)$request->color) : null;
        $sort         = $request->filled('sort') ? strip_tags((string)$request->sort) : null;

        if ($category) {
            $query->where('product_category', $category);
        }
        if ($brand) {
            $query->where('brand_name', $brand);
        }
        if ($request->filled('new_stock')) {
            $query->where('new_stock', true);
        }
        if ($discounted !== null && $discounted !== '') {
            if ($discounted == '1') {
                $query->where('discount', '>', 0);
            } elseif ($discounted == '0') {
                $query->where(function ($q) {
                    $q->where('discount', '=', 0)->orWhereNull('discount');
                });
            }
        }
        if ($newest) {
            $query->orderBy('created_at', 'desc');
        }

        // Execute query to get products
        $products = $query->get();

        // Post-filter by models (color, price range, availability)
        if ($colorFilter) {
            $products = $products->filter(function ($product) use ($colorFilter) {
                return $product->models->contains(function ($model) use ($colorFilter) {
                    return stripos((string)$model->colors, $colorFilter) !== false;
                });
            });
        }
        if ($request->filled('min_price') || $request->filled('max_price')) {
            $min = $request->filled('min_price') ? floatval($request->min_price) : null;
            $max = $request->filled('max_price') ? floatval($request->max_price) : null;
            $products = $products->filter(function ($product) use ($min, $max) {
                return $product->models->contains(function ($model) use ($min, $max) {
                    $ok = true;
                    if (!is_null($min)) $ok = $ok && ($model->price >= $min);
                    if (!is_null($max)) $ok = $ok && ($model->price <= $max);
                    return $ok;
                });
            });
        }
        if ($availability) {
            $products = $products->filter(function ($product) {
                return $product->models->contains(function ($model) {
                    return $model->stock > 0;
                });
            });
        }

        // Sort products by price, newest, or oldest
        if ($sort) {
            if ($sort == 'low_high') {
                $products = $products->sortBy(function ($product) {
                    return $product->models->min('price');
                });
            } elseif ($sort == 'high_low') {
                $products = $products->sortByDesc(function ($product) {
                    return $product->models->max('price');
                });
            } elseif ($sort == 'newest') {
                $products = $products->sortByDesc('created_at');
            } elseif ($sort == 'oldest') {
                $products = $products->sortBy('created_at');
            }
        }

        // Sanitize attributes for rendering (product + models)
        $sanitize = fn($v) => is_string($v) ? strip_tags($v) : $v;
        $products = $products->map(function ($p) use ($sanitize) {
            $p->product_name     = $sanitize($p->product_name);
            $p->brand_name       = $sanitize($p->brand_name);
            $p->product_category = $sanitize($p->product_category);
            $p->description      = $sanitize($p->description);
            $p->specification    = $sanitize($p->specification);
            if ($p->relationLoaded('models') && $p->models) {
                $p->models->transform(function ($m) use ($sanitize) {
                    $m->model_name = $sanitize($m->model_name);
                    $m->colors     = $sanitize($m->colors);
                    return $m;
                });
            }
            return $p;
        });

        // Prepare filter options and selected filter values
        $categories = Products::pluck('product_category')->map(fn($v) => is_string($v) ? strip_tags($v) : $v)->unique()->values();
        $brands = Products::pluck('brand_name')->map(fn($v) => is_string($v) ? strip_tags($v) : $v)->unique()->values();
        $colors = \App\Models\ProductModel::pluck('colors')->filter()->flatMap(function ($item) {
            return array_map('trim', explode(',', $item));
        })->map(fn($v) => strip_tags((string)$v))->unique()->values();

        $filterData = [
            'category' => $category ?? '',
            'brand' => $brand ?? '',
            'min_price' => $request->min_price ?? '',
            'max_price' => $request->max_price ?? '',
            'newest' => $newest ?? '',
            'availability' => $availability ?? '',
            'discounted' => $discounted ?? '',
            'color' => $colorFilter ?? '',
            'sort' => $sort ?? '',
        ];

        // Render shop view
        return view('shop', compact('products', 'categories', 'brands', 'colors', 'filterData'));
    }

    /**
     * Shop listing by category.
     */
    public function shopByCategory($category)
    {
        // Sanitize category and fetch products with models
        $category = strip_tags((string)$category);

        $products = Products::with('models')->where('product_category', $category)->get();

        // Sanitize attributes for rendering (product + models)
        $sanitize = fn($v) => is_string($v) ? strip_tags($v) : $v;
        $products = $products->map(function ($p) use ($sanitize) {
            $p->product_name     = $sanitize($p->product_name);
            $p->brand_name       = $sanitize($p->brand_name);
            $p->product_category = $sanitize($p->product_category);
            $p->description      = $sanitize($p->description);
            $p->specification    = $sanitize($p->specification);
            if ($p->relationLoaded('models') && $p->models) {
                $p->models->transform(function ($m) use ($sanitize) {
                    $m->model_name = $sanitize($m->model_name);
                    $m->colors     = $sanitize($m->colors);
                    return $m;
                });
            }
            return $p;
        });

        // Build option lists and default filter selections
        $categories = Products::pluck('product_category')->map(fn($v) => is_string($v) ? strip_tags($v) : $v)->unique()->values();
        $brands = Products::pluck('brand_name')->map(fn($v) => is_string($v) ? strip_tags($v) : $v)->unique()->values();
        $colors = \App\Models\ProductModel::pluck('colors')->filter()->flatMap(function ($item) {
            return array_map('trim', explode(',', $item));
        })->map(fn($v) => strip_tags((string)$v))->unique()->values();

        $filterData = [
            'category' => $category,
            'brand' => '',
            'min_price' => '',
            'max_price' => '',
            'newest' => '',
            'availability' => '',
            'discounted' => '',
            'color' => '',
            'sort' => '',
        ];

        // Render shop view
        return view('shop', compact('products', 'categories', 'brands', 'colors', 'filterData', 'category'));
    }

    /**
     * Show all product categories.
     */
    public function categories()
    {
        // Fetch distinct categories and render categories view
        $categories = Products::pluck('product_category')->map(fn($v) => is_string($v) ? strip_tags($v) : $v)->unique()->values();
        return view('categories', compact('categories'));
    }

    /**
     * Product details page with related products.
     */
    public function show($id)
    {
        // Load product and related products in same category
        $product = Products::with('models')->findOrFail($id);
        $relatedProducts = Products::with('models')
            ->where('product_category', $product->product_category)
            ->where('id', '!=', $id)
            ->limit(4)
            ->get();

        // Sanitize attributes for rendering (product + related + their models)
        $sanitize = fn($v) => is_string($v) ? strip_tags($v) : $v;
        $product->product_name     = $sanitize($product->product_name);
        $product->brand_name       = $sanitize($product->brand_name);
        $product->product_category = $sanitize($product->product_category);
        $product->description      = $sanitize($product->description);
        $product->specification    = $sanitize($product->specification);
        if ($product->relationLoaded('models') && $product->models) {
            $product->models->transform(function ($m) use ($sanitize) {
                $m->model_name = $sanitize($m->model_name);
                $m->colors     = $sanitize($m->colors);
                return $m;
            });
        }
        $relatedProducts = $relatedProducts->map(function ($p) use ($sanitize) {
            $p->product_name     = $sanitize($p->product_name);
            $p->brand_name       = $sanitize($p->brand_name);
            $p->product_category = $sanitize($p->product_category);
            $p->description      = $sanitize($p->description);
            $p->specification    = $sanitize($p->specification);
            if ($p->relationLoaded('models') && $p->models) {
                $p->models->transform(function ($m) use ($sanitize) {
                    $m->model_name = $sanitize($m->model_name);
                    $m->colors     = $sanitize($m->colors);
                    return $m;
                });
            }
            return $p;
        });

        // Render product detail view
        return view('product', compact('product', 'relatedProducts'));
    }
}
