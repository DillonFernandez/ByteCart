<?php

use Illuminate\Support\Facades\Password;
use Livewire\Attributes\Layout;
use Livewire\Volt\Component;

new #[Layout('components.layouts.auth')] class extends Component {
    public string $email = '';

    /**
     * Send a password reset link to the provided email address.
     */
    public function sendPasswordResetLink(): void
    {
        $this->validate([
            'email' => ['required', 'string', 'email'],
        ]);

        Password::sendResetLink($this->only('email'));

        session()->flash('status', __('A reset link will be sent if the account exists.'));
    }
}; ?>

<x-slot name="title">
    {{ __('ByteCart | Forgot Password') }}
</x-slot>

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
    <div class="flex flex-col gap-6">
        <x-auth-header :title="__('Forgot password')" :description="__('Enter your email to receive a password reset link')" />

        <!-- Session Status -->
        <x-auth-session-status class="text-center" :status="session('status')" />

        <form method="POST" wire:submit="sendPasswordResetLink" class="flex flex-col gap-6">
            <!-- Email Address -->
            <flux:input
                wire:model="email"
                :label="__('Email Address')"
                type="email"
                required
                autofocus
                placeholder="email@example.com"
                class="focus:border-[#0479FF] focus:ring-[#0479FF]" />

            <div class="flex items-center justify-end">
                <flux:button variant="primary" type="submit" class="w-full text-white border-none" style="background-color:#0479FF;transition:background-color 0.2s;border-radius:9px;" onmouseover="this.style.backgroundColor='#0469DF'" onmouseout="this.style.backgroundColor='#0479FF'">
                    {{ __('Email password reset link') }}
                </flux:button>
            </div>

            <!-- Separator and Back Button -->
            <div class="flex items-center">
                <hr class="flex-grow border-gray-300">
                <span class="mx-2 text-gray-500 text-sm">or</span>
                <hr class="flex-grow border-gray-300">
            </div>
            <div class="flex items-center justify-end">
                <a href="{{ route('login') }}" class="w-full text-center text-gray-500 text-sm hover:underline transition-colors">Back to Login</a>
            </div>
        </form>
    </div>
</div>