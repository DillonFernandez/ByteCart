<?php

use Illuminate\Support\Facades\Route;
use Livewire\Volt\Volt;
use App\Http\Controllers\AdminController;
use App\Http\Controllers\CustomerController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\ProductModelController;
use App\Http\Controllers\WishListController;
use App\Http\Controllers\ShippingInfoController;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\SearchBarController;
use App\Http\Controllers\CartController;
use App\Http\Controllers\AdminOrderController;
use App\Http\Controllers\CustomerOrderController;

Route::get('/', function () {
    return view('welcome');
})->name('home');

Route::view('dashboard', 'dashboard')
    ->middleware(['auth:sanctum', 'verified'])
    ->name('dashboard');

Route::view('account', 'account')
    ->middleware(['auth:sanctum', 'verified'])
    ->name('account');

Route::middleware(['auth:sanctum'])->group(function () {
    Route::redirect('settings', 'settings/profile');

    Volt::route('settings/profile', 'settings.profile')->name('settings.profile');
    Volt::route('settings/password', 'settings.password')->name('settings.password');
    Volt::route('settings/appearance', 'settings.appearance')->name('settings.appearance');
});

require __DIR__ . '/auth.php';

Route::middleware([
    'auth:sanctum',
    config('jetstream.auth_session'),
    'verified',
])->group(function () {
    Route::get('/dashboard', function () {
        return view('dashboard');
    })->name('dashboard');
});

Route::middleware(['auth:sanctum', 'verified'])->group(function () {
    Route::get('manage-admins', [AdminController::class, 'index'])->name('manage-admins');
    Route::patch('manage-admins/{id}', [AdminController::class, 'update'])->name('manage-admins.update');
    Route::delete('manage-admins/{id}', [AdminController::class, 'destroy'])->name('manage-admins.destroy');
    Route::post('manage-admins', [AdminController::class, 'store'])->name('manage-admins.store');

    Route::get('manage-customers', [CustomerController::class, 'index'])->name('manage-customers');
    Route::patch('manage-customers/{id}', [CustomerController::class, 'update'])->name('manage-customers.update');
    Route::delete('manage-customers/{id}', [CustomerController::class, 'destroy'])->name('manage-customers.destroy');

    Route::get('manage-products', [ProductController::class, 'index'])->name('manage-products');
    Route::post('manage-products', [ProductController::class, 'store'])->name('manage-products.store');
    Route::patch('manage-products/{id}', [ProductController::class, 'update'])->name('manage-products.update');
    Route::post('manage-products/{id}', [ProductController::class, 'update']);
    Route::delete('manage-products/{id}', [ProductController::class, 'destroy'])->name('manage-products.destroy');

    Route::post('manage-product-models', [ProductModelController::class, 'store'])->name('manage-product-models.store');
    Route::patch('manage-product-models/{id}', [ProductModelController::class, 'update'])->name('manage-product-models.update');
    Route::delete('manage-product-models/{id}', [ProductModelController::class, 'destroy'])->name('manage-product-models.destroy');
});

Route::view('manage-orders', 'manage-orders')
    ->middleware(['auth:sanctum', 'verified'])
    ->name('manage-orders');

// Shop All page (all products)
Route::get('/shop-all', [ProductController::class, 'shop'])->name('shop-all');

// Categories page (list all categories)
Route::get('/categories', [ProductController::class, 'categories'])->name('categories');

// Shop by category
Route::get('/shop/category/{category}', [ProductController::class, 'shopByCategory'])->name('shop.category');

// About Us page
Route::view('/about-us', 'about-us')->name('about-us');

// Contact Us page
Route::view('/contact-us', 'contact-us')->name('contact-us');

// Product details page
Route::get('/product/{id}', [ProductController::class, 'show'])->name('product.show');

// Cart routes
Route::get('/cart', [CartController::class, 'index'])->name('cart');
Route::post('/cart/add', [CartController::class, 'add'])->name('cart.add');
Route::post('/cart/update', [CartController::class, 'updateQty'])->name('cart.update');
Route::post('/cart/remove', [CartController::class, 'remove'])->name('cart.remove');
Route::post('/cart/clear', [CartController::class, 'clear'])->name('cart.clear');

// Checkout routes (create orders in MySQL)
Route::get('/checkout', [\App\Http\Controllers\CheckoutController::class, 'show'])->name('checkout.show');
Route::post('/checkout', [\App\Http\Controllers\CheckoutController::class, 'place'])->name('checkout.place');

Route::middleware(['auth:sanctum', 'verified'])->group(function () {
    Route::view('my-order', 'my-order')->name('my-order');
    Route::view('account-settings', 'account-settings')->name('account-settings');
    Route::view('wish-list', 'wish-list')->name('wish-list');
    Route::get('shipping-info', [ShippingInfoController::class, 'show'])->name('shipping-info');
    Route::post('shipping-info', [ShippingInfoController::class, 'update'])->name('shipping-info.update');
    Route::view('payment-methods', 'payment-methods')->name('payment-methods');
    Route::post('payment-methods', [PaymentController::class, 'store'])->name('payment-methods.store');
    Route::post('payment-methods/clear-card', [PaymentController::class, 'clearCard'])->name('payment-methods.clear-card');

    Route::post('wish-list/add', [WishListController::class, 'add'])->name('wish-list.add');
    Route::post('wish-list/remove', [WishListController::class, 'remove'])->name('wish-list.remove');
    Route::post('wish-list/check', [WishListController::class, 'check'])->name('wish-list.check');

    // Customer: cancel order (before shipped)
    Route::post('/orders/{order}/cancel', [CustomerOrderController::class, 'cancel'])
        ->name('orders.cancel')
        ->middleware('auth');

    // Customer: mark order as delivered
    Route::post('/orders/{order}/delivered', [CustomerOrderController::class, 'markDelivered'])
        ->name('orders.delivered')
        ->middleware('auth');
});

// Admin: update order status (Shipped / Out for delivery)
Route::post('/admin/orders/{order}/status', [AdminOrderController::class, 'updateStatus'])
    ->name('admin.orders.updateStatus')
    ->middleware('auth');

// AJAX search for live search bar
Route::get('/search-bar/suggest', [SearchBarController::class, 'suggest'])->name('search-bar.suggest');
