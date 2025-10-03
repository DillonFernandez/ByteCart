<?php

/**
 * Products
 *
 * Represents a product and its variants (MySQL).
 * Declares table name, fillable/default attributes, and relation to product models.
 */

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Products extends Model
{
    /**
     * Table name.
     */
    protected $table = 'products';

    /**
     * Fillable attributes.
     */
    protected $fillable = [
        'product_name',
        'brand_name',
        'product_category',
        'description',
        'specification',
        'new_stock',
        'discount',
        'image',
    ];

    /**
     * Default attribute values.
     */
    protected $attributes = [
        'discount' => 0,
    ];

    /**
     * Relation: product models/variants for this product.
     */
    public function models()
    {
        return $this->hasMany(ProductModel::class, 'product_id', 'id');
    }
}
