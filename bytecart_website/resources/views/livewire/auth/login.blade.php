<?php

use Illuminate\Auth\Events\Lockout;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Session;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;
use Livewire\Attributes\Layout;
use Livewire\Attributes\Validate;
use Livewire\Volt\Component;

new #[Layout('components.layouts.auth')] class extends Component {
    #[Validate('required|string|email')]
    public string $email = '';

    #[Validate('required|string')]
    public string $password = '';

    public bool $remember = false;

    /**
     * Handle an incoming authentication request.
     */
    public function login(): void
    {
        $this->validate();

        $this->ensureIsNotRateLimited();

        if (! Auth::attempt(['email' => $this->email, 'password' => $this->password], $this->remember)) {
            RateLimiter::hit($this->throttleKey());

            throw ValidationException::withMessages([
                'email' => __('auth.failed'),
            ]);
        }

        RateLimiter::clear($this->throttleKey());
        Session::regenerate();

        // Redirect based on role
        $user = Auth::user();
        if ($user->roles === 'admin') {
            $this->redirect(route('dashboard'), navigate: true);
        } elseif ($user->roles === 'customer') {
            $this->redirectIntended(route('account', absolute: false), navigate: true);
        } else {
            Auth::logout();
            Session::invalidate();
            Session::regenerateToken();
            $this->redirect(route('home'), navigate: true);
        }
    }

    /**
     * Ensure the authentication request is not rate limited.
     */
    protected function ensureIsNotRateLimited(): void
    {
        if (! RateLimiter::tooManyAttempts($this->throttleKey(), 5)) {
            return;
        }

        event(new Lockout(request()));

        $seconds = RateLimiter::availableIn($this->throttleKey());

        throw ValidationException::withMessages([
            'email' => __('auth.throttle', [
                'seconds' => $seconds,
                'minutes' => ceil($seconds / 60),
            ]),
        ]);
    }

    /**
     * Get the authentication rate limiting throttle key.
     */
    protected function throttleKey(): string
    {
        return Str::transliterate(Str::lower($this->email) . '|' . request()->ip());
    }
}; ?>

<x-slot name="title">
    {{ __('ByteCart | Login') }}
</x-slot>

@php
$activeTab = 'login';
$registerRoute = Route::has('register') ? route('register') : null;
@endphp

<div class="w-full max-w-md bg-white bc-card p-8">
    <style>
        .bc-card {
            border-radius: 18px;
            box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);
        }

        /* Ensure input focus color is #0479FF for flux:input fields */
        flux\:input input {
            border-radius: 9px;
        }

        flux\:input input:focus,
        flux\:input input:focus-visible {
            outline: none;
            border-color: #0479FF !important;
            box-shadow: 0 0 0 2px #0479FF33;
        }
    </style>
    <!-- Tabs -->
    <div class="flex mb-6 border-b border-gray-200">
        <button
            class="flex-1 py-2 text-lg font-semibold focus:outline-none transition-colors
                    {{ $activeTab === 'login' ? 'border-b-2 border-[color:#0479FF] text-[color:#0479FF]' : 'text-gray-500' }}"
            type="button"
            onclick="document.getElementById('login-tab').style.display='block';document.getElementById('signup-tab').style.display='none';">
            {{ __('Login') }}
        </button>
        @if ($registerRoute)
        <button
            class="flex-1 py-2 text-lg font-semibold focus:outline-none transition-colors
                    {{ $activeTab === 'signup' ? 'border-b-2 border-[color:#0479FF] text-[color:#0479FF]' : 'text-gray-500' }}"
            type="button"
            onclick="window.location.href='{{ $registerRoute }}';">
            {{ __('Sign Up') }}
        </button>
        @endif
    </div>

    <!-- Login Tab -->
    <div id="login-tab">
        <div class="flex flex-col gap-6">
            <x-auth-header :title="__('Log in to your account')" :description="__('Enter your email and password below to log in')" />

            <!-- Session Status -->
            <x-auth-session-status class="text-center" :status="session('status')" />

            <form method="POST" wire:submit="login" class="flex flex-col gap-6">
                <!-- Email Address -->
                <flux:input
                    wire:model="email"
                    :label="__('Email address')"
                    type="email"
                    required
                    autofocus
                    autocomplete="email"
                    placeholder="email@example.com"
                    class="focus:border-[#0479FF] focus:ring-[#0479FF]" />

                <!-- Password -->
                <div class="relative">
                    <flux:input
                        wire:model="password"
                        :label="__('Password')"
                        type="password"
                        required
                        autocomplete="current-password"
                        :placeholder="__('Password')"
                        viewable
                        class="focus:border-[#0479FF] focus:ring-[#0479FF]" />
                </div>

                <!-- Remember Me & Forgot Password Row -->
                <div class="flex items-center justify-between">
                    <flux:checkbox wire:model="remember" :label="__('Remember me')" label-class="font-normal" />
                    @if (Route::has('password.request'))
                    <flux:link class="text-sm" :href="route('password.request')" wire:navigate>
                        {{ __('Forgot your password?') }}
                    </flux:link>
                    @endif
                </div>

                <div class="flex items-center justify-end">
                    <flux:button variant="primary" type="submit" class="w-full text-white border-none" style="background-color:#0479FF;transition:background-color 0.2s;border-radius:9px;" onmouseover="this.style.backgroundColor='#0469DF'" onmouseout="this.style.backgroundColor='#0479FF'">
                        {{ __('Log in') }}
                    </flux:button>
                </div>

                <!-- Separator and Back Button -->
                <div class="flex items-center">
                    <hr class="flex-grow border-gray-300">
                    <span class="mx-2 text-gray-500 text-sm">or</span>
                    <hr class="flex-grow border-gray-300">
                </div>
                <div class="flex items-center justify-end">
                    <a href="{{ route('home') }}" class="w-full text-center text-gray-500 text-sm hover:underline transition-colors">Back to Home</a>
                </div>
            </form>
        </div>
    </div>
    <!-- End Login Tab -->

    <!-- Sign Up Tab (hidden, handled by redirect) -->
    {{-- The sign up tab is handled by redirecting to register route --}}
</div>