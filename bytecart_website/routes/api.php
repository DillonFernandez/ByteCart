<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Actions\Fortify\CreateNewUser;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use App\Models\User;
use App\Http\Controllers\ProductController;
use App\Models\Products;

Route::post('/register', function (Request $request, CreateNewUser $creator) {
    // create the user
    $user = $creator->create($request->all());

    // log them in and create a Sanctum token
    $token = $user->createToken('mobile-app')->plainTextToken;

    return response()->json([
        'user'  => $user,
        'token' => $token,
    ]);
});

Route::post('/login', function (Request $request) {
    $request->validate([
        'email' => 'required|email',
        'password' => 'required',
    ]);

    $user = User::where('email', $request->email)->first();

    if (! $user || ! Hash::check($request->password, $user->password)) {
        return response()->json([
            'message' => 'Invalid credentials',
        ], 401);
    }

    $token = $user->createToken('mobile-app')->plainTextToken;

    return response()->json([
        'user' => $user,
        'token' => $token,
    ]);
});

Route::get('/products', function (Request $request) {
    $products = Products::with('models')->get();

    return response()->json($products);
});

Route::get('/products/{id}', function ($id) {
    $product = Products::with('models')->findOrFail($id);
    return response()->json($product);
});

Route::get('/products/search', function (Request $request) {
    $query = Products::with('models');

    if ($request->filled('q')) {
        $search = strip_tags($request->q);
        $query->where('product_name', 'like', "%{$search}%")
            ->orWhere('brand_name', 'like', "%{$search}%")
            ->orWhere('product_category', 'like', "%{$search}%");
    }

    return response()->json($query->get());
});
