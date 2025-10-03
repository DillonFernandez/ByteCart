<?php

/**
 * OrderItem (MongoDB Eloquent Model)
 *
 * Represents a line item within a customer order stored in mongodb_orders:
 * - Declares fillable attributes and type casts
 * - Belongs to an Order via order_number
 * - Ensures MongoDB connection is configured at boot
 */

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model as EloquentModel;
use MongoDB\Laravel\Relations\BelongsTo;

class OrderItem extends EloquentModel
{
    // Storage: Mongo connection/collection and PK settings
    protected $connection = 'mongodb_orders';
    protected $collection = 'order_items';

    protected $primaryKey = '_id';
    public $incrementing = false;
    protected $keyType = 'string';

    /**
     * Fillable attributes.
     */
    protected $fillable = [
        'order_id',
        'product_id',
        'product_model_id',
        'product_name',
        'model_name',
        'color',
        'image',
        'unit_price',
        'qty',
        'line_total',
    ];

    /**
     * Casts for type safety.
     */
    protected $casts = [
        'unit_price' => 'double',
        'line_total' => 'double',
        'qty' => 'integer',
    ];

    /**
     * Order relation via order_number (avoids ObjectId join issues).
     */
    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class, 'order_number', 'order_number');
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
