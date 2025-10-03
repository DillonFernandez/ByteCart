<?php

namespace App\Support\Cart;

use Illuminate\Support\Facades\Facade;

class CartFacade extends Facade
{
    protected static function getFacadeAccessor(): string
    {
        return 'cart';
    }
}
