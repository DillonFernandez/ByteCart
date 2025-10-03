@php
$user = auth()->user();
if (!$user || ($user->roles ?? '') !== 'customer') {
\Illuminate\Support\Facades\Auth::guard('web')->logout();
\Illuminate\Support\Facades\Session::invalidate();
\Illuminate\Support\Facades\Session::regenerateToken();
header('Location: ' . route('login'));
exit;
}
@endphp
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>{{ $user->name ?? 'Account Settings' }} | Account Settings</title>
    <link rel="icon" type="image/x-icon" href="{{ asset('logo/x-icon.webp') }}">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <style>
        .account-settings-container {
            display: flex;
            flex-direction: column;
            gap: 2rem;
        }

        @media (max-width: 767px) {
            .account-settings-container {
                gap: 0rem;
            }

            .page-header {
                margin-bottom: 1rem;
            }
        }

        .account-content {
            width: 100%;
        }

        .page-header {
            margin-bottom: 2rem;
        }

        .page-title {
            font-size: 2rem;
            font-weight: 700;
            color: #1e293b;
            margin: 0 0 0.5rem 0;
            text-align: center;
        }

        .page-subtitle {
            color: #64748b;
            font-size: 1rem;
            margin: 0;
            text-align: center;
        }

        .info-banner {
            background: linear-gradient(135deg, #dbeafe 0%, #bfdbfe 100%);
            border: 1px solid #93c5fd;
            border-radius: 18px;
            padding: 1.5rem;
            margin-bottom: 2rem;
        }

        .info-banner-title {
            font-weight: 600;
            color: #1e40af;
            margin-bottom: 0.5rem;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .info-banner-text {
            color: #1e40af;
            line-height: 1.6;
            margin: 0;
        }

        .help-section {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 18px;
            padding: 1.5rem;
            margin-bottom: 2rem;
        }

        .help-title {
            font-size: 1.125rem;
            font-weight: 600;
            color: #1e293b;
            margin: 0 0 1rem 0;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .help-list {
            list-style: none;
            padding: 0;
            margin: 0 0 1rem 0;
        }

        .help-list li {
            display: flex;
            align-items: flex-start;
            gap: 0.75rem;
            margin-bottom: 0.75rem;
            color: #475569;
            line-height: 1.5;
        }

        .help-list li:before {
            content: '✓';
            color: #16a34a;
            font-weight: 600;
            flex-shrink: 0;
            margin-top: 0.125rem;
        }

        .support-link {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            color: #2563eb;
            text-decoration: none;
            font-weight: 500;
            transition: color 0.2s;
        }

        .support-link:hover {
            color: #1d4ed8;
            text-decoration: underline;
        }

        .settings-grid {
            display: grid;
            gap: 1.5rem;
            grid-template-columns: 1fr;
        }

        .settings-card {
            background: white;
            border: none;
            border-radius: 18px;
            padding: 2rem;
            box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);
            transition: box-shadow 0.2s;
        }

        .settings-card--danger {
            background: #fee2e2;
        }

        .divider {
            height: 1px;
            background: linear-gradient(to right, transparent, #e2e8f0, transparent);
            margin: 2rem 0;
        }

        .icon {
            width: 20px;
            height: 20px;
            flex-shrink: 0;
        }

        @media (min-width: 768px) {
            .account-settings-container {
                flex-direction: row;
                align-items: flex-start;
                gap: 3rem;
            }

            .account-content {
                flex: 1;
            }

            .page-title,
            .page-subtitle {
                text-align: left;
            }

            .settings-grid {
                grid-template-columns: repeat(2, 1fr);
                gap: 2rem;
            }

            .settings-card--full {
                grid-column: 1 / -1;
            }
        }

        @media (min-width: 1024px) {
            .account-settings-container {
                gap: 4rem;
            }
        }
    </style>
</head>

<body class="bg-white">
    @livewire('nav-bar')
    <x-app-layout>
        <div class="bg-white w-full mx-auto pb-8 pt-5 px-4 sm:px-16 sm:pb-10 sm:pt-5">
            <div class="account-settings-container">
                <!-- Desktop/Mobile Navigation -->
                @livewire('account-navbar')

                <!-- Main Content -->
                <div class="account-content">
                    <!-- Page Header -->
                    <div class="page-header">
                        <h1 class="page-title">Account Settings</h1>
                        <p class="page-subtitle">Manage your account security and personal information</p>
                    </div>

                    <!-- Info Banner -->
                    <div class="info-banner">
                        <div class="info-banner-title">
                            Secure Account Management
                        </div>
                        <p class="info-banner-text">
                            Keep your account secure by regularly updating your password, enabling two-factor authentication, and reviewing your account settings. All changes are automatically saved and encrypted.
                        </p>
                    </div>

                    <!-- Help Section -->
                    <div class="help-section">
                        <h3 class="help-title">
                            Security Tips & Support
                        </h3>
                        <ul class="help-list">
                            <li>Use a strong, unique password with at least 8 characters</li>
                            <li>Enable two-factor authentication for enhanced security</li>
                            <li>Review and manage active browser sessions regularly</li>
                            <li>Keep your contact information up to date</li>
                            <li>Contact support if you notice any suspicious activity</li>
                        </ul>
                        <a class="support-link">
                            <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
                                <polyline points="22,6 12,13 2,6" />
                            </svg>
                            Contact Account Support
                        </a>
                    </div>

                    <!-- Settings Grid -->
                    <div class="settings-grid">
                        <div class="settings-card">
                            @livewire('profile.update-profile-information-form')
                        </div>

                        <div class="settings-card">
                            @livewire('profile.update-password-form')
                        </div>

                        <div class="settings-card">
                            @livewire('profile.two-factor-authentication-form')
                        </div>

                        <div class="settings-card">
                            @livewire('profile.logout-other-browser-sessions-form')
                        </div>

                        <div class="divider settings-card--full"></div>

                        <div class="settings-card settings-card--danger settings-card--full">
                            @livewire('profile.delete-user-form')
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </x-app-layout>
    @livewire('footer')
</body>

</html>