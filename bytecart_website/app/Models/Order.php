<?php

/**
 * Order (MongoDB Eloquent Model)
 *
 * Represents a customer order stored in the mongodb_orders connection:
 * - Declares fillable attributes and type casts
 * - Exposes items() relation via order_number
 * - Ensures MongoDB connection is configured at boot
 */

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model as EloquentModel;
use MongoDB\Laravel\Relations\HasMany;

class Order extends EloquentModel
{
    // Storage: Mongo connection/collection and primary key settings
    protected $connection = 'mongodb_orders';
    protected $collection = 'orders';
    protected $primaryKey = '_id';
    public $incrementing = false;
    protected $keyType = 'string';

    /**
     * Fillable attributes.
     */
    protected $fillable = [
        'user_id',
        'order_number',
        'customer_name',
        'customer_email',
        'customer_phone',
        'billing_street_address',
        'billing_apartment_suite',
        'billing_city',
        'billing_district',
        'billing_zip_code',
        'shipping_street_address',
        'shipping_apartment_suite',
        'shipping_city',
        'shipping_district',
        'shipping_zip_code',
        'is_billing_same_as_shipping',
        'subtotal',
        'shipping_fee',
        'tax',
        'total',
        'payment_method',
        'order_status',
        'notes',
        'placed_at',
    ];

    /**
     * Casts for type safety.
     */
    protected $casts = [
        'is_billing_same_as_shipping' => 'boolean',
        'subtotal' => 'double',
        'shipping_fee' => 'double',
        'tax' => 'double',
        'total' => 'double',
        'placed_at' => 'datetime',
    ];

    /**
     * Order items relation via order_number (avoids ObjectId join issues).
     */
    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class, 'order_number', 'order_number');
    }

    /**
     * Ensure Mongo connection is configured when the model boots.
     */
    protected static function boot()
    {
        parent::boot();
        static::ensureMongoConfigured();
    }

    /**
     * Provide runtime MongoDB connection config if missing.
     */
    protected static function ensureMongoConfigured(): void
    {
        if (!config('database.connections.mongodb_orders')) {
            config()->set('database.connections.mongodb_orders', [
                'driver'   => 'mongodb',
                'dsn'      => env('MONGODB_ORDERS_DSN'),
                'host'     => env('MONGODB_ORDERS_HOST', '127.0.0.1'),
                'port'     => env('MONGODB_ORDERS_PORT', 27017),
                'database' => env('MONGODB_ORDERS_DATABASE', 'bytecart_orders'),
                'username' => env('MONGODB_ORDERS_USERNAME', ''),
                'password' => env('MONGODB_ORDERS_PASSWORD', ''),
                'options'  => [
                    'database' => env('MONGODB_ORDERS_AUTH_DATABASE', 'admin'),
                    'ssl'      => env('MONGODB_ORDERS_SSL', false),
                ],
            ]);
        }
    }
}
