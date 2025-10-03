<?php

/**
 * AdminController (Laravel)
 * 
 * Manages CRUD for admin users:
 * - List admins with optional search
 * - Create/update with validation, sanitization, and password hashing
 * - Delete admin accounts
 * 
 * Notes:
 * - Sanitizes user-facing fields before rendering or returning JSON
 * - Uses JSON responses for mutations; returns a view for listing
 */

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules;

class AdminController extends Controller
{
    /**
     * List admin users with optional search; sanitizes inputs/outputs and renders the view.
     */
    public function index(Request $request)
    {
        // Sanitize input
        $search = $request->input('search');
        if (is_string($search)) {
            $search = strip_tags($search);
        }

        // Build query and apply search filter
        $adminsQuery = User::where('roles', 'admin');
        if ($search) {
            $adminsQuery->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%");
            });
        }
        $admins = $adminsQuery->get();

        // Fetch and sanitize results
        $admins->transform(function ($admin) {
            $admin->name = strip_tags((string) $admin->name);
            $admin->email = strip_tags((string) $admin->email);
            return $admin;
        });

        // Render view
        return view('manage-admins', compact('admins', 'search'));
    }

    /**
     * Update an admin by id; validates, sanitizes, optionally hashes password, and returns JSON.
     */
    public function update(Request $request, $id)
    {
        // Lookup admin
        $admin = User::where('roles', 'admin')->findOrFail($id);

        // Build validation rules
        $rules = [
            'name' => ['required', 'string', 'max:255'],
            'email' => [
                'required',
                'string',
                'lowercase',
                'email',
                'max:255',
                'unique:users,email,' . $admin->id,
            ],
        ];
        if ($request->filled('password')) {
            $rules['password'] = ['required', 'string', Rules\Password::defaults()];
        }

        // Validate request
        $validated = $request->validate($rules);

        // Sanitize fields and hash password if provided
        if (array_key_exists('name', $validated)) {
            $validated['name'] = strip_tags($validated['name']);
        }
        if (array_key_exists('email', $validated)) {
            $validated['email'] = strip_tags($validated['email']);
        }
        if ($request->filled('password')) {
            $validated['password'] = \Illuminate\Support\Facades\Hash::make($validated['password']);
        }

        // Persist changes
        $admin->update($validated);

        // Sanitize response and return JSON
        $admin->name = strip_tags((string) $admin->name);
        $admin->email = strip_tags((string) $admin->email);

        return response()->json(['success' => true, 'admin' => $admin]);
    }

    /**
     * Delete an admin by id and return a JSON result.
     */
    public function destroy($id)
    {
        // Lookup and delete admin, then return JSON success
        $admin = User::where('roles', 'admin')->findOrFail($id);
        $admin->delete();
        return response()->json(['success' => true]);
    }

    /**
     * Create a new admin; validates, sanitizes, hashes password, sets role, and returns JSON.
     */
    public function store(Request $request)
    {
        // Validate request
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => [
                'required',
                'string',
                'lowercase',
                'email',
                'max:255',
                'unique:users,email',
            ],
            'password' => ['required', 'string', 'confirmed', Rules\Password::defaults()],
        ]);

        // Sanitize and prepare data (including hashing, role assignment)
        $validated['name'] = strip_tags($validated['name']);
        $validated['email'] = strip_tags($validated['email']);
        $validated['password'] = Hash::make($validated['password']);
        $validated['roles'] = 'admin';

        // Create admin
        $admin = User::create($validated);

        // Sanitize response and return JSON
        $admin->name = strip_tags((string) $admin->name);
        $admin->email = strip_tags((string) $admin->email);

        return response()->json(['success' => true, 'admin' => $admin]);
    }
}
