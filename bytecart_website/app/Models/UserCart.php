<?php

/**
 * UserCart (Eloquent Model)
 *
 * Represents a user's shopping cart stored in MySQL:
 * - Holds serialized items with subtotal/total and a checkout lock flag
 * - Provides helpers to lock/unlock and a scope to query unlocked carts
 */

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserCart extends Model
{
    /**
     * Table name and fillable attributes.
     */
    protected $table = 'user_carts';
    protected $fillable = ['user_id', 'items', 'subtotal', 'total', 'locked'];

    /**
     * Attribute casts.
     */
    protected $casts = [
        'items'    => 'array',
        'subtotal' => 'float',
        'total'    => 'float',
        'locked'   => 'boolean',
    ];

    /**
     * Lock the cart (e.g., during checkout).
     */
    public function lock(): bool
    {
        if ($this->locked) return true;
        $this->locked = true;
        return $this->save();
    }

    /**
     * Unlock the cart after checkout or on failure.
     */
    public function unlock(): bool
    {
        if (!$this->locked) return true;
        $this->locked = false;
        return $this->save();
    }

    /**
     * Scope: only carts that are not locked.
     */
    public function scopeUnlocked($q)
    {
        return $q->where('locked', false);
    }
}
