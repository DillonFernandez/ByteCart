<?php

/**
 * CustomerController
 *
 * Manages customer users:
 * - List customers with optional search and safe output
 * - Update customers with validation, sanitization, and optional password hashing
 * - Delete customers
 * Returns a view for listing and JSON for mutations.
 */

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules;

class CustomerController extends Controller
{
    /**
     * List customers with optional search; sanitizes inputs/outputs and renders the view.
     */
    public function index(Request $request)
    {
        // Input: sanitize search query
        $search = $request->input('search');
        // Sanitize search input
        if (is_string($search)) {
            $search = strip_tags($search);
        }

        // Query: customers by role + optional search filter
        $customersQuery = User::where('roles', 'customer');
        if ($search) {
            $customersQuery->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%");
            });
        }
        $customers = $customersQuery->get();

        // Output prep: sanitize attributes for safe rendering
        $customers->transform(function ($customer) {
            $customer->name = strip_tags((string) $customer->name);
            $customer->email = strip_tags((string) $customer->email);
            return $customer;
        });

        // Render: return view with customers and search term
        return view('manage-customers', compact('customers', 'search'));
    }

    /**
     * Update a customer by id; validates, sanitizes, hashes password if present, and returns JSON.
     */
    public function update(Request $request, $id)
    {
        // Lookup: fetch customer by id constrained to role
        $customer = User::where('roles', 'customer')->findOrFail($id);

        // Validation: build rules and validate request
        $rules = [
            'name' => ['required', 'string', 'max:255'],
            'email' => [
                'required',
                'string',
                'lowercase',
                'email',
                'max:255',
                'unique:users,email,' . $customer->id,
            ],
        ];
        if ($request->filled('password')) {
            $rules['password'] = ['required', 'string', Rules\Password::defaults()];
        }
        $validated = $request->validate($rules);

        // Transform: hash password and sanitize fields
        if ($request->filled('password')) {
            $validated['password'] = Hash::make($validated['password']);
        }

        // Sanitize before saving
        if (array_key_exists('name', $validated)) {
            $validated['name'] = strip_tags($validated['name']);
        }
        if (array_key_exists('email', $validated)) {
            $validated['email'] = strip_tags($validated['email']);
        }

        // Persist: update the customer
        $customer->update($validated);

        // Respond: sanitize output and return JSON
        $customer->name = strip_tags((string) $customer->name);
        $customer->email = strip_tags((string) $customer->email);

        return response()->json(['success' => true, 'customer' => $customer]);
    }

    /**
     * Delete a customer by id and return a JSON result.
     */
    public function destroy($id)
    {
        // Delete: lookup, delete, and respond with success
        $customer = User::where('roles', 'customer')->findOrFail($id);
        $customer->delete();
        return response()->json(['success' => true]);
    }
}
