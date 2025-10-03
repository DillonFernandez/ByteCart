<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Support\Cart\Cart;

class CartServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->singleton('cart', function () {
            return new Cart();
        });
    }

    public function boot(): void
    {
        //
    }
}
