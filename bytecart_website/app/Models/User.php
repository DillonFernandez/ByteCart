<?php

/**
 * User (Eloquent Model)
 *
 * Represents an application user:
 * - Authentication and security traits
 * - Profile, address, and payment fields
 * - Helpers for initials and role checks
 */

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as BaseAuthenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Fortify\TwoFactorAuthenticatable;
use Laravel\Jetstream\HasProfilePhoto;
use Illuminate\Support\Str;
use Laravel\Sanctum\HasApiTokens;

class User extends BaseAuthenticatable
{
    // Traits
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasApiTokens;
    use HasFactory;
    use HasProfilePhoto;
    use Notifiable;
    use TwoFactorAuthenticatable;

    /**
     * Fillable attributes.
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'roles',
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
        'is_billing_same_as_shipping',
        'payment_method',
        'card_number',
        'cardholder_name',
        'expiry_date',
        'cvv',
        'save_card',
    ];

    /**
     * Hidden attributes for serialization.
     */
    protected $hidden = [
        'password',
        'remember_token',
        'two_factor_recovery_codes',
        'two_factor_secret',
    ];

    /**
     * Appended accessors.
     */
    protected $appends = [
        'profile_photo_url',
    ];

    /**
     * Type casts.
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    /**
     * Get the user's initials.
     */
    public function initials(): string
    {
        return Str::of($this->name)
            ->explode(' ')
            ->take(2)
            ->map(fn($word) => Str::substr($word, 0, 1))
            ->implode('');
    }

    /**
     * Determine if the user has the specified role.
     */
    public function hasRole(string $role): bool
    {
        $roles = $this->roles ?? null;

        if (is_string($roles)) {
            return strtolower($roles) === strtolower($role);
        }

        if (is_array($roles)) {
            return in_array(strtolower($role), array_map('strtolower', $roles), true);
        }

        if ($roles instanceof \Illuminate\Support\Collection) {
            return $roles->map(fn($r) => strtolower((string)$r))->contains(strtolower($role));
        }

        return false;
    }

    /**
     * Return an empty collection for tokens to avoid SQL errors on deletion.
     */
    public function getTokensAttribute()
    {
        return collect();
    }
}
