<?php

/**
 * WishList (Eloquent Model)
 *
 * Links a user to a product as a wish list entry:
 * - Declares table and fillable attributes
 * - Defines relations to User and Products
 */

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WishList extends Model
{
    /**
     * Table name.
     */
    protected $table = 'wish_lists';

    /**
     * Fillable attributes.
     */
    protected $fillable = [
        'user_id',
        'product_id',
    ];

    /**
     * Relation: owning user.
     */
    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'id');
    }

    /**
     * Relation: referenced product.
     */
    public function product()
    {
        return $this->belongsTo(Products::class, 'product_id', 'id');
    }
}
