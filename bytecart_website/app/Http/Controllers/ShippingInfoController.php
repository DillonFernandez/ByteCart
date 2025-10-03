<?php

/**
 * ShippingInfoController
 *
 * Manages customer shipping and billing information:
 * - Show form with sanitized user data
 * - Validate, sanitize, and persist updates
 * - Enforce authenticated customer access
 */

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Redirect;

class ShippingInfoController extends Controller
{
    /**
     * Display the shipping/billing form for the authenticated customer.
     */
    public function show()
    {
        $user = Auth::user();
        // Authorization: require authenticated customer model
        if (!$user instanceof \App\Models\User) {
            return Redirect::route('home')->withErrors('User model not found.');
        }
        if (!$user || ($user->roles ?? '') !== 'customer') {
            Auth::guard('web')->logout();
            session()->invalidate();
            session()->regenerateToken();
            return Redirect::route('home');
        }

        // Sanitize: prepare user fields for safe rendering
        $safeUser = clone $user;
        foreach (
            [
                'phone_number',
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
            ] as $field
        ) {
            if (isset($safeUser->$field) && is_string($safeUser->$field)) {
                $safeUser->$field = strip_tags($safeUser->$field);
            }
        }

        // Render: show form with sanitized user data
        return view('shipping-info', ['user' => $safeUser]);
    }

    /**
     * Update the shipping and billing info for the authenticated customer.
     */
    public function update(Request $request)
    {
        $user = Auth::user();
        // Authorization: require authenticated customer model
        if (!$user instanceof \App\Models\User || ($user->roles ?? '') !== 'customer') {
            Auth::guard('web')->logout();
            session()->invalidate();
            session()->regenerateToken();
            return Redirect::route('home');
        }
        // Normalize: strip spaces from phone number
        if ($request->has('phone_number')) {
            $request->merge([
                'phone_number' => preg_replace('/\s+/', '', $request->input('phone_number'))
            ]);
        }
        // Validate: enforce field constraints with custom messages
        $validated = $request->validate([
            'phone_number' => 'required|regex:/^[0-9]{10}$/',
            'billing_street_address' => 'required|string|max:255',
            'billing_apartment_suite' => 'nullable|string|max:255',
            'billing_city' => 'required|string|max:255',
            'billing_district' => 'required|string|max:255',
            'billing_zip_code' => 'required|regex:/^[0-9]{5}$/',
            'shipping_street_address' => 'required|string|max:255',
            'shipping_apartment_suite' => 'nullable|string|max:255',
            'shipping_city' => 'required|string|max:255',
            'shipping_district' => 'required|string|max:255',
            'shipping_zip_code' => 'required|regex:/^[0-9]{5}$/',
            'is_billing_same_as_shipping' => 'nullable|boolean',
        ], [
            'phone_number.regex'     => 'Phone number must be exactly 10 digits (0-9). Spaces are allowed.',
            'billing_zip_code.regex' => 'Billing ZIP must be exactly 5 digits (0-9).',
            'shipping_zip_code.regex' => 'Shipping ZIP must be exactly 5 digits (0-9).',
        ]);

        // Sanitize: strip tags and normalize boolean flags
        $sanitized = $validated;
        foreach ($sanitized as $key => $value) {
            if (is_string($value)) {
                $sanitized[$key] = strip_tags($value);
            }
        }
        $sanitized['is_billing_same_as_shipping'] = $request->has('is_billing_same_as_shipping');

        // Persist: save updates to the user profile
        foreach ($sanitized as $key => $value) {
            $user->$key = $value;
        }
        $user->save();

        // Respond: redirect with success message
        return redirect()->route('shipping-info')->with('success', 'Shipping info updated successfully.');
    }
}
