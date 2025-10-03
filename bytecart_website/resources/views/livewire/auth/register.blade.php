<?php

use App\Models\User;
use Illuminate\Auth\Events\Registered;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules;
use Livewire\Attributes\Layout;
use Livewire\Volt\Component;

new #[Layout('components.layouts.auth')] class extends Component {
    public string $name = '';
    public string $email = '';
    public string $password = '';
    public string $password_confirmation = '';

    /**
     * Handle an incoming registration request.
     */
    public function register(): void
    {
        $validated = $this->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'lowercase', 'email', 'max:255', 'unique:' . User::class],
            'password' => ['required', 'string', 'confirmed', Rules\Password::defaults()],
        ]);

        $validated['password'] = Hash::make($validated['password']);
        $validated['roles'] = 'customer'; // set default role

        event(new Registered(($user = User::create($validated))));

        Auth::login($user);

        $this->redirectIntended(route('account', absolute: false), navigate: true); // redirect to account
    }
}; ?>

<x-slot name="title">
    {{ __('ByteCart | Register') }}
</x-slot>

@php
$activeTab = 'signup';
$loginRoute = Route::has('login') ? route('login') : null;
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
        @if ($loginRoute)
        <button
            class="flex-1 py-2 text-lg font-semibold focus:outline-none transition-colors
                    {{ $activeTab === 'login' ? 'border-b-2 border-[color:#0479FF] text-[color:#0479FF]' : 'text-gray-500' }}"
            type="button"
            onclick="window.location.href='{{ $loginRoute }}';">
            {{ __('Login') }}
        </button>
        @endif
        <button
            class="flex-1 py-2 text-lg font-semibold focus:outline-none transition-colors
                    {{ $activeTab === 'signup' ? 'border-b-2 border-[color:#0479FF] text-[color:#0479FF]' : 'text-gray-500' }}"
            type="button"
            onclick="document.getElementById('register-tab').style.display='block';">
            {{ __('Sign Up') }}
        </button>
    </div>

    <!-- Register Tab -->
    <div id="register-tab">
        <div class="flex flex-col gap-6">
            <x-auth-header :title="__('Create an account')" :description="__('Enter your details below to create your account')" />

            <!-- Session Status -->
            <x-auth-session-status class="text-center" :status="session('status')" />

            <form method="POST" wire:submit="register" class="flex flex-col gap-6">
                <!-- Name -->
                <flux:input
                    wire:model="name"
                    :label="__('Name')"
                    type="text"
                    required
                    autofocus
                    autocomplete="name"
                    :placeholder="__('Full name')" />

                <!-- Email Address -->
                <flux:input
                    wire:model="email"
                    :label="__('Email address')"
                    type="email"
                    required
                    autocomplete="email"
                    placeholder="email@example.com" />

                <!-- Password -->
                <flux:input
                    wire:model="password"
                    :label="__('Password')"
                    type="password"
                    required
                    autocomplete="new-password"
                    :placeholder="__('Password')"
                    viewable />

                <!-- Confirm Password -->
                <flux:input
                    wire:model="password_confirmation"
                    :label="__('Confirm password')"
                    type="password"
                    required
                    autocomplete="new-password"
                    :placeholder="__('Confirm password')"
                    viewable />

                <div class="flex items-center justify-end">
                    <flux:button type="submit" variant="primary" class="w-full text-white border-none" style="background-color:#0479FF;transition:background-color 0.2s;border-radius:9px;" onmouseover="this.style.backgroundColor='#0469DF'" onmouseout="this.style.backgroundColor='#0479FF'">
                        {{ __('Create account') }}
                    </flux:button>
                </div>

                <!-- Separator and Back Button -->
                <div class="flex items-center">
                    <hr class="flex-grow border-gray-300">
                    <span class="mx-2 text-gray-500 text-sm">or</span>
                    <hr class="flex-grow border-gray-300">
                </div>
                <div class="flex items-center justify-end">
                    <a href="{{ route('home') }}" class="w-full text-center text-gray-500 text-sm hover:underline transition-colors">Back to Home Page</a>
                </div>
            </form>
        </div>
    </div>
    <!-- End Register Tab -->
</div>