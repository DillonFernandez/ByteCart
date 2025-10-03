<?php

/**
 * PaymentController
 *
 * Manages user payment methods:
 * - Validate and sanitize inputs
 * - Handle Visa/MasterCard details with encryption and optional Luhn check
 * - Persist or clear stored payment data
 */

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;

class PaymentController extends Controller
{
    /**
     * Store or update the authenticated user's payment method.
     */
    public function store(Request $request)
    {
        // Authorization: ensure user is authenticated
        $user = \Illuminate\Support\Facades\Auth::user();
        if (!$user) {
            return redirect()->route('home');
        }

        // Validate request payload
        $data = $request->validate([
            'payment_method' => 'required|string',
            'card_number' => 'nullable|string',
            'cardholder_name' => 'nullable|string',
            'expiry_date' => 'nullable|string',
            'cvv' => 'nullable|string',
            'save_card' => 'nullable',
        ]);

        // Sanitize inputs prior to processing/persistence
        if (isset($data['payment_method'])) {
            $data['payment_method'] = strip_tags((string) $data['payment_method']);
        }
        foreach (['card_number', 'cardholder_name', 'expiry_date', 'cvv'] as $k) {
            if (array_key_exists($k, $data) && $data[$k] !== null) {
                $data[$k] = strip_tags((string) $data[$k]);
            }
        }

        // Card handling: validate and encrypt Visa/MasterCard details (number, expiry, holder, CVV)
        if ($data['payment_method'] === 'Visa/MasterCard') {
            $originalEncrypted = $user->card_number;
            $rawCardInput = $data['card_number'] ?? '';
            $rawCardInput = preg_replace('/[^0-9 *]/', '', $rawCardInput);
            $data['card_number'] = $rawCardInput;
            $isMasked = strpos($rawCardInput, '*') !== false;
            $digits = preg_replace('/\D/', '', $rawCardInput);

            if ($isMasked) {
                if ($originalEncrypted) {
                    $data['card_number'] = $originalEncrypted;
                } else {
                    return back()->withErrors(['card_number' => 'Enter full card number.'])->withInput();
                }
            } else {
                $len = strlen($digits);
                if ($len < 12 || $len > 19) {
                    return back()->withErrors(['card_number' => 'Card number must be 12–19 digits.'])->withInput();
                }
                $luhnPass = true;
                try {
                    if (app()->environment('production')) {
                        $luhnPass = self::luhnCheck($digits);
                    }
                } catch (\Throwable $e) {
                    $luhnPass = false;
                }
                if (!$luhnPass) {
                    return back()->withErrors(['card_number' => 'Card number failed checksum.'])->withInput();
                }
                $data['card_number'] = encrypt($digits);
            }

            // Validate expiry (MM/YY) and not expired
            $expiryPlain = (string) ($data['expiry_date'] ?? '');
            if (!preg_match('/^(0[1-9]|1[0-2])\/\d{2}$/', $expiryPlain)) {
                return back()->withErrors(['expiry_date' => 'Invalid expiry format (MM/YY).'])->withInput();
            }
            [$mm, $yy] = explode('/', $expiryPlain);
            $expYear = 2000 + (int) $yy;
            $expMonth = (int) $mm;
            $expiryEnd = \Carbon\Carbon::create($expYear, $expMonth, 1)->endOfMonth();
            if ($expiryEnd->lt(\Carbon\Carbon::now()->startOfDay())) {
                return back()->withErrors(['expiry_date' => 'Card is expired.'])->withInput();
            }

            // Normalize cardholder name (uppercase + trim) before encrypt
            $holder = trim((string) ($data['cardholder_name'] ?? ''));
            $holder = mb_strtoupper($holder);
            if ($holder === '') {
                return back()->withErrors(['cardholder_name' => 'Cardholder name required.'])->withInput();
            }

            $data['cardholder_name'] = encrypt($holder);
            $data['expiry_date'] = encrypt($expiryPlain);

            // CVV: validate & encrypt (user requested to save CVV)
            $cvvPlain = (string) ($data['cvv'] ?? '');
            if (!preg_match('/^[0-9]{3,4}$/', $cvvPlain)) {
                return back()->withErrors(['cvv' => 'Invalid CVV.'])->withInput();
            }
            $data['cvv'] = encrypt($cvvPlain);
        } else {
            // Non-card methods: clear stored card-related fields
            $data['card_number'] = null;
            $data['cardholder_name'] = null;
            $data['expiry_date'] = null;
            $data['cvv'] = null;
            $data['save_card'] = null;
        }

        // Persist: save payment data to MySQL
        foreach ($data as $key => $value) {
            $user->$key = $value;
        }
        if ($user instanceof \App\Models\User) {
            $user->save(); // removed MongoDB fallback
        }

        // Respond: success message
        return back()->with('success', 'Payment method saved!');
    }

    /**
     * Remove any stored card details for the authenticated user.
     */
    public function clearCard(Request $request)
    {
        // Authorization: ensure user is authenticated
        $user = \Illuminate\Support\Facades\Auth::user();
        if (!$user) {
            return response()->json(['ok' => false], 401);
        }

        // Clear stored card fields and persist
        $user->card_number = null;
        $user->cardholder_name = null;
        $user->expiry_date = null;
        $user->cvv = null;
        if ($user instanceof \App\Models\User) {
            $user->save();
        }

        // Respond: JSON result
        return response()->json(['ok' => true]);
    }

    /**
     * Check a card number using the Luhn algorithm.
     */
    public static function luhnCheck($number)
    {
        $number = preg_replace('/\D/', '', $number);
        $sum = 0;
        $alt = false;
        for ($i = strlen($number) - 1; $i >= 0; $i--) {
            $n = intval($number[$i]);
            if ($alt) {
                $n *= 2;
                if ($n > 9) $n -= 9;
            }
            $sum += $n;
            $alt = !$alt;
        }
        return $sum % 10 === 0;
    }
}
