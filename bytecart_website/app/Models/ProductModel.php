<?php

/**
 * ProductModel
 *
 * Represents a product variant/model belonging to a product (MySQL).
 * Declares the table, fillable attributes, and parent product relation.
 */

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProductModel extends Model
{
    /**
     * Table name.
     */
    protected $table = 'product_models';

    /**
     * Fillable attributes.
     */
    protected $fillable = [
        'product_id',
        'model_name',
        'price',
        'stock',
        'colors',
        'images',
    ];

    /**
     * Relation: parent product.
     */
    public function product()
    {
        return $this->belongsTo(Products::class, 'product_id', 'id');
    }
}
