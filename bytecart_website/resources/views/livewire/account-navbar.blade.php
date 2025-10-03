<!-- Account Navbar (Blade)
     Responsive account navigation for mobile (modal) and desktop (sidebar).
     Includes links to account sections and logout, with accessible styles and controls. -->
<div class="account-navbar-container">
    <!-- Mobile FAB trigger (opens account menu) -->
    <button class="mobile-fab" id="openAccountBtn" aria-label="Open Account Menu">
        <svg class="mobile-fab__icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M3 12h18M3 6h18M3 18h18" stroke-linecap="round" stroke-linejoin="round" />
        </svg>
    </button>

    <!-- Mobile account menu modal (overlay + panel) -->
    <div class="mobile-overlay" id="mobileAccountModal">
        <div class="mobile-modal">
            <div class="mobile-modal__header">
                <h2 class="mobile-modal__title">Account Menu</h2>
                <button class="mobile-modal__close" id="closeAccountBtn" aria-label="Close Account Menu">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M18 6L6 18M6 6l12 12" stroke-linecap="round" stroke-linejoin="round" />
                    </svg>
                </button>
            </div>
            <nav class="mobile-nav">
                <ul class="nav-list">
                    <li class="nav-item">
                        <a href="{{ route('account') }}" class="nav-link {{ Route::currentRouteName() == 'account' ? 'nav-link--active' : '' }}">
                            <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z" />
                            </svg>
                            Main Page
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="{{ route('my-order') }}" class="nav-link {{ Route::currentRouteName() == 'my-order' ? 'nav-link--active' : '' }}">
                            <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M16 4h2a2 2 0 012 2v14a2 2 0 01-2 2H6a2 2 0 01-2-2V6a2 2 0 012-2h2" />
                                <rect x="8" y="2" width="8" height="4" rx="1" ry="1" />
                            </svg>
                            Orders
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="{{ route('wish-list') }}" class="nav-link {{ Route::currentRouteName() == 'wish-list' ? 'nav-link--active' : '' }}">
                            <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M20.84 4.61a5.5 5.5 0 00-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 00-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 000-7.78z" />
                            </svg>
                            Wish List
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="{{ route('account-settings') }}" class="nav-link {{ Route::currentRouteName() == 'account-settings' ? 'nav-link--active' : '' }}">
                            <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <circle cx="12" cy="12" r="3" />
                                <path d="M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 010 2.83 2 2 0 01-2.83 0l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-2 2 2 2 0 01-2-2v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 01-2.83 0 2 2 0 010-2.83l.06-.06a1.65 1.65 0 00.33-1.82 1.65 1.65 0 00-1.51-1H3a2 2 0 01-2-2 2 2 0 012-2h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 010-2.83 2 2 0 012.83 0l.06.06a1.65 1.65 0 001.82.33H9a1.65 1.65 0 001-1.51V3a2 2 0 012-2 2 2 0 012 2v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 012.83 0 2 2 0 010 2.83l-.06.06a1.65 1.65 0 00-.33 1.82V9a1.65 1.65 0 001.51 1H21a2 2 0 012 2 2 2 0 01-2 2h-.09a1.65 1.65 0 00-1.51 1z" />
                            </svg>
                            Account Settings
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="{{ route('shipping-info') }}" class="nav-link {{ Route::currentRouteName() == 'shipping-info' ? 'nav-link--active' : '' }}">
                            <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M16 3h5v5M4 20L21 3M21 16v5h-5M4 4h5v5" />
                            </svg>
                            Shipping Info
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="{{ route('payment-methods') }}" class="nav-link {{ Route::currentRouteName() == 'payment-methods' ? 'nav-link--active' : '' }}">
                            <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <rect x="1" y="4" width="22" height="16" rx="2" ry="2" />
                                <line x1="1" y1="10" x2="23" y2="10" />
                            </svg>
                            Payment Methods
                        </a>
                    </li>
                    <li class="nav-item nav-item--logout">
                        <form method="POST" action="{{ route('logout') }}" class="logout-form">
                            @csrf
                            <button type="submit" class="logout-btn">
                                <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4M16 17l5-5-5-5M21 12H9" />
                                </svg>
                                Logout
                            </button>
                        </form>
                    </li>
                </ul>
            </nav>
        </div>
    </div>

    <!-- Desktop sidebar navigation -->
    <nav class="desktop-nav">
        <div class="desktop-nav__header">
            <h2 class="desktop-nav__title">Account</h2>
        </div>
        <ul class="nav-list">
            <li class="nav-item">
                <a href="{{ route('account') }}" class="nav-link {{ Route::currentRouteName() == 'account' ? 'nav-link--active' : '' }}">
                    <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z" />
                    </svg>
                    Main Page
                </a>
            </li>
            <li class="nav-item">
                <a href="{{ route('my-order') }}" class="nav-link {{ Route::currentRouteName() == 'my-order' ? 'nav-link--active' : '' }}">
                    <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M16 4h2a2 2 0 012 2v14a2 2 0 01-2 2H6a2 2 0 01-2-2V6a2 2 0 012-2h2" />
                        <rect x="8" y="2" width="8" height="4" rx="1" ry="1" />
                    </svg>
                    Orders
                </a>
            </li>
            <li class="nav-item">
                <a href="{{ route('wish-list') }}" class="nav-link {{ Route::currentRouteName() == 'wish-list' ? 'nav-link--active' : '' }}">
                    <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M20.84 4.61a5.5 5.5 0 00-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 00-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 000-7.78z" />
                    </svg>
                    Wish List
                </a>
            </li>
            <li class="nav-item">
                <a href="{{ route('account-settings') }}" class="nav-link {{ Route::currentRouteName() == 'account-settings' ? 'nav-link--active' : '' }}">
                    <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <circle cx="12" cy="12" r="3" />
                        <path d="M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 010 2.83 2 2 0 01-2.83 0l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-2 2 2 2 0 01-2-2v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 01-2.83 0 2 2 0 010-2.83l.06-.06a1.65 1.65 0 00.33-1.82 1.65 1.65 0 00-1.51-1H3a2 2 0 01-2-2 2 2 0 012-2h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 010-2.83 2 2 0 012.83 0l.06.06a1.65 1.65 0 001.82.33H9a1.65 1.65 0 001-1.51V3a2 2 0 012-2 2 2 0 012 2v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 012.83 0 2 2 0 010 2.83l-.06.06a1.65 1.65 0 00-.33 1.82V9a1.65 1.65 0 001.51 1H21a2 2 0 012 2 2 2 0 01-2 2h-.09a1.65 1.65 0 00-1.51 1z" />
                    </svg>
                    Account Settings
                </a>
            </li>
            <li class="nav-item">
                <a href="{{ route('shipping-info') }}" class="nav-link {{ Route::currentRouteName() == 'shipping-info' ? 'nav-link--active' : '' }}">
                    <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M16 3h5v5M4 20L21 3M21 16v5h-5M4 4h5v5" />
                    </svg>
                    Shipping Info
                </a>
            </li>
            <li class="nav-item">
                <a href="{{ route('payment-methods') }}" class="nav-link {{ Route::currentRouteName() == 'payment-methods' ? 'nav-link--active' : '' }}">
                    <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <rect x="1" y="4" width="22" height="16" rx="2" ry="2" />
                        <line x1="1" y1="10" x2="23" y2="10" />
                    </svg>
                    Payment Methods
                </a>
            </li>
            <li class="nav-item nav-item--logout">
                <form method="POST" action="{{ route('logout') }}" class="logout-form">
                    @csrf
                    <button type="submit" class="logout-btn">
                        <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4M16 17l5-5-5-5M21 12H9" />
                        </svg>
                        Logout
                    </button>
                </form>
            </li>
        </ul>
    </nav>

    <style>
        /* Base */
        * {
            box-sizing: border-box;
        }

        :root {
            --bc-radius-lg: 18px;
            --bc-radius-md: 9px;
            --bc-radius-sm: 4.5px;
            --bc-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);
        }

        .account-navbar-container {
            position: relative;
        }

        /* Common navigation styles */
        .nav-list {
            list-style: none;
            padding: 0;
            margin: 0;
        }

        .nav-item {
            margin-bottom: 0.5rem;
        }

        .nav-link {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            padding: 0.75rem 1rem;
            color: #475569;
            text-decoration: none;
            border-radius: var(--bc-radius-md);
            transition: all 0.2s ease;
            font-weight: 500;
            font-size: 0.875rem;
        }

        .nav-link:hover {
            background-color: #f1f5f9;
            color: #2563eb;
        }

        .nav-link--active {
            background-color: #dbeafe;
            color: #2563eb;
        }

        .nav-icon {
            width: 20px;
            height: 20px;
            flex-shrink: 0;
        }

        /* Desktop navigation */
        .desktop-nav {
            display: none;
            width: 280px;
            background: white;
            border-radius: var(--bc-radius-lg);
            box-shadow: var(--bc-shadow);
            padding: 1.5rem;
        }

        .desktop-nav__header {
            margin-bottom: 1.5rem;
            padding-bottom: 1rem;
            border-bottom: 1px solid #e2e8f0;
        }

        .desktop-nav__title {
            margin: 0;
            font-size: 1.5rem;
            font-weight: 600;
            color: #1e293b;
        }

        /* Mobile FAB */
        .mobile-fab {
            display: flex;
            position: fixed;
            bottom: 24px;
            right: 24px;
            z-index: 50;
            align-items: center;
            justify-content: center;
            width: 56px;
            height: 56px;
            background: #2563eb;
            color: white;
            border: none;
            border-radius: 50%;
            box-shadow: var(--bc-shadow);
            cursor: pointer;
            transition: all 0.2s ease;
        }

        .mobile-fab:hover {
            background: #1d4ed8;
            transform: scale(1.05);
        }

        .mobile-fab__icon {
            width: 24px;
            height: 24px;
        }

        /* Mobile overlay and panel */
        .mobile-overlay {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            z-index: 100;
            background: rgba(0, 0, 0, 0.5);
            backdrop-filter: blur(4px);
        }

        .mobile-overlay.active {
            display: flex;
            align-items: flex-end;
            justify-content: center;
        }

        .mobile-modal {
            background: white;
            width: 100%;
            max-width: 420px;
            border-radius: var(--bc-radius-lg) var(--bc-radius-lg) 0 0;
            box-shadow: var(--bc-shadow);
            max-height: 80vh;
            overflow-y: auto;
            animation: slideUp 0.2s ease-out;
        }

        /* Enter animation (slide up) */
        @keyframes slideUp {
            from {
                transform: translateY(100%);
            }

            to {
                transform: translateY(0);
            }
        }

        /* Close animation (slide down) and state */
        @keyframes slideDown {
            from {
                transform: translateY(0);
            }

            to {
                transform: translateY(100%);
            }
        }

        /* Apply slide-down on close while overlay stays visible */
        .mobile-overlay.closing .mobile-modal {
            animation: slideDown 0.2s ease-in forwards;
        }

        .mobile-modal__header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 1.5rem 1.5rem 1rem;
            border-bottom: 1px solid #e2e8f0;
        }

        .mobile-modal__title {
            margin: 0;
            font-size: 1.25rem;
            font-weight: 600;
            color: #1e293b;
        }

        .mobile-modal__close {
            display: flex;
            align-items: center;
            justify-content: center;
            width: 40px;
            height: 40px;
            background: #f8fafc;
            border: none;
            border-radius: 50%;
            color: #64748b;
            cursor: pointer;
            transition: all 0.2s ease;
        }

        .mobile-modal__close:hover {
            background: #e2e8f0;
            color: #475569;
        }

        .mobile-modal__close svg {
            width: 20px;
            height: 20px;
        }

        .mobile-nav {
            padding: 1rem 1.5rem 2rem;
        }

        /* Logout styles */
        .nav-item--logout {
            margin-top: 1rem;
            padding-top: 1rem;
            border-top: 1px solid #e2e8f0;
        }

        .logout-form {
            margin: 0;
        }

        .logout-btn {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            width: 100%;
            padding: 0.75rem 1rem;
            background: #dc2626;
            color: white;
            border: none;
            border-radius: var(--bc-radius-md);
            font-weight: 500;
            font-size: 0.875rem;
            cursor: pointer;
            transition: all 0.2s ease;
        }

        .logout-btn:hover {
            background: #b91c1c;
        }

        /* Responsive */
        @media (min-width: 768px) {

            .mobile-fab,
            .mobile-overlay {
                display: none !important;
            }

            .desktop-nav {
                display: block;
            }
        }

        @media (max-width: 767px) {
            .desktop-nav {
                display: none !important;
            }

            .mobile-modal {
                width: 100vw;
                max-width: 100vw;
            }
        }

        /* Accessibility: focus outlines */
        .nav-link:focus,
        .mobile-fab:focus,
        .mobile-modal__close:focus,
        .logout-btn:focus {
            outline: 2px solid #2563eb;
            outline-offset: 2px;
        }

        /* Mobile touch targets */
        @media (max-width: 767px) {
            .nav-link {
                padding: 1rem;
                min-height: 48px;
            }

            .logout-btn {
                padding: 1rem;
                min-height: 48px;
            }
        }
    </style>

    <script>
        // Mobile account modal: open/close with close animation
        document.addEventListener('DOMContentLoaded', function() {
            var openBtn = document.getElementById('openAccountBtn');
            var closeBtn = document.getElementById('closeAccountBtn');
            var modal = document.getElementById('mobileAccountModal');
            var panel = modal ? modal.querySelector('.mobile-modal') : null;

            function openAccount() {
                if (!modal) return;
                modal.classList.remove('closing');
                modal.classList.add('active');
                document.body.style.overflow = 'hidden';
            }

            function closeAccount() {
                if (!modal || modal.classList.contains('closing')) return;
                modal.classList.add('closing');

                if (panel) {
                    const onEnd = () => {
                        modal.classList.remove('active', 'closing');
                        document.body.style.overflow = '';
                        panel.removeEventListener('animationend', onEnd);
                    };
                    panel.addEventListener('animationend', onEnd);
                } else {
                    // Fallback close without animation (if panel not found)
                    modal.classList.remove('active', 'closing');
                    document.body.style.overflow = '';
                }
            }

            if (openBtn && closeBtn && modal) {
                openBtn.addEventListener('click', openAccount);
                closeBtn.addEventListener('click', closeAccount);
                modal.addEventListener('click', function(e) {
                    if (e.target === modal) closeAccount();
                });
            }
        });
    </script>
</div>