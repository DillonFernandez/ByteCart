<!-- Nav Bar (Blade)
     Responsive site navigation: top bar, logo, search, cart/account, and slide-out menus for mobile/desktop. -->
<nav class="bg-white text-gray-900">
    @php $searchNonce = \Illuminate\Support\Str::random(6); @endphp

    <!-- Top bar: welcome + quick links -->
    <div class="w-full hidden md:block" style="background:#f8f9fa;" class="text-sm border-b border-gray-200">
        <div class="mx-auto flex items-center justify-between py-2 px-16">
            <span class="text-gray-700 text-sm">Welcome to ByteCart Sri Lanka</span>
            <div class="flex items-center gap-4 text-sm">
                <a href="https://maps.app.goo.gl/CLLZdYDUAN5pxLZo9" target="_blank" rel="noopener" class="flex items-center gap-1 text-gray-600 hover:text-[#0479FF]">
                    <img src="{{ asset('icons/pin.webp') }}" alt="" class="w-4 h-4" />
                    Store Locator
                </a>
                <span style="color:#e3e4e4;">|</span>
                <a class="flex items-center gap-1 text-gray-600 hover:text-[#0479FF]">
                    <img src="{{ asset('icons/delivery truck.webp') }}" alt="" class="w-4 h-4" />
                    Track Your Order
                </a>
                <span style="color:#e3e4e4;">|</span>
                <a href="{{ route('shop-all') }}" class="flex items-center gap-1 text-gray-600 hover:text-[#0479FF]">
                    <img src="{{ asset('icons/shop.webp') }}" alt="" class="w-4 h-4" />
                    Shop
                </a>
                <span style="color:#e3e4e4;">|</span>
                @php
                $user = Auth::user();
                if ($user) {
                if ($user->roles === 'admin') {
                $accountUrl = route('dashboard');
                } elseif ($user->roles === 'customer') {
                $accountUrl = route('account');
                } else {
                $accountUrl = route('login');
                }
                } else {
                $accountUrl = route('login');
                }
                @endphp
                <a href="{{ $accountUrl }}" class="flex items-center gap-1 text-gray-600 hover:text-[#0479FF]">
                    <img src="{{ asset('icons/account.webp') }}" alt="" class="h-4 w-4" />
                    @auth
                    {{ Auth::user()->name }}@if(Auth::user()->roles === 'admin') - Admin @endif
                    @else
                    My Account
                    @endauth
                </a>
            </div>
        </div>
    </div>
    <!-- Main navbar: logo, search, cart/account -->
    <div class="mx-auto flex items-center justify-between py-5 px-16 relative">
        <!-- Hamburger Icon (Mobile, very left corner) -->
        <div class="absolute left-4 md:hidden z-20">
            <button class="flex items-center text-gray-900 focus:outline-none p-2" onclick="openNav()"
                style="background:none;border:none;">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-7" fill="none" viewBox="0 0 24 24"
                    stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
                </svg>
            </button>
        </div>
        <!-- Account and Cart Icons (Mobile, very right corner) -->
        <div class="absolute right-4 md:hidden flex items-center gap-2 z-20">
            @php
            $user = Auth::user();
            if ($user) {
            if ($user->roles === 'admin') {
            $accountUrl = route('dashboard');
            } elseif ($user->roles === 'customer') {
            $accountUrl = route('account');
            } else {
            $accountUrl = route('login');
            }
            } else {
            $accountUrl = route('login');
            }
            @endphp
            <a href="{{ $accountUrl }}" class="flex items-center">
                <img src="{{ asset('icons/account m.webp') }}" alt="Account" class="h-8 w-8" />
            </a>
            <a href="{{ route('cart') }}" class="relative flex items-center">
                <img src="{{ asset('icons/cart.webp') }}" alt="Cart" class="h-8 w-8" />
                <div class="absolute -top-1 -right-1">
                    <livewire:cart-total />
                </div>
            </a>
        </div>
        <!-- Logo -->
        <div class="flex items-center gap-2 shrink-0 mx-auto md:mx-0">
            <a href="/" class="flex items-center gap-2">
                <img src="{{ asset('logo/logo.webp') }}" alt="ByteCart Logo"
                    class="h-10 md:h-12 w-auto transition-transform duration-300 hover:scale-105">
            </a>
            <!-- Hamburger Icon (Desktop) -->
            <button class="hidden md:flex items-center text-gray-900 focus:outline-none p-2" onclick="openNav()"
                style="background:none;border:none;">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-7" fill="none" viewBox="0 0 24 24"
                    stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
                </svg>
            </button>
        </div>
        <!-- Search Bar (Desktop) -->
        <div class="hidden md:flex flex-1 items-center ml-[30px] mr-[30px]">
            <form autocomplete="off" role="search" onsubmit="return false;" class="flex w-full relative" id="search-bar-desktop">
                @csrf
                <!-- soak autofill -->
                <input type="text" autocomplete="off" tabindex="-1" style="position:absolute;opacity:0;height:0;width:0;border:0;padding:0;">
                <input type="text" id="search-bar-input-desktop"
                    name="tmp_{{ $searchNonce }}"
                    autocomplete="off" data-autocomplete="off" aria-autocomplete="none"
                    autocorrect="off" autocapitalize="none" spellcheck="false" inputmode="search" enterkeyhint="search"
                    placeholder="Search for the Latest iPad"
                    readonly
                    onfocus="assignRandomName(this);releaseSearchReadonly(this);"
                    class="w-full px-4 py-2 rounded-l-full bg-white text-gray-700 border border-gray-300 text-base focus:outline-none focus:border-[#0479FF]" />
                <button type="button" id="search-bar-btn-desktop" class="px-4 py-2 rounded-r-full bg-[#0479FF] flex items-center justify-center">
                    <img src="{{ asset('icons/search.webp') }}" alt="Search" class="h-6 w-6" />
                </button>
                <div id="search-bar-results-desktop" class="absolute top-full left-0 w-full bg-white border border-gray-200 rounded-b-xl shadow-lg z-30 hidden"></div>
                <input type="password" autocomplete="new-password" style="position:absolute;opacity:0;height:0;width:0;border:0;padding:0;">
            </form>
        </div>
        <!-- Cart (Right, Desktop only) -->
        <div class="hidden md:flex items-center gap-4 ml-2 shrink-0">
            <a href="{{ route('cart') }}" class="relative flex items-center">
                <img src="{{ asset('icons/cart.webp') }}" alt="Cart" class="h-8 w-8" />
                <div class="absolute -top-1 -right-1">
                    <livewire:cart-total />
                </div>
            </a>
        </div>
    </div>
    <!-- Mobile Search Bar (below logo, only on mobile) -->
    <div class="flex md:hidden items-center px-4 pb-3">
        <form autocomplete="off" role="search" onsubmit="return false;" class="flex w-full relative" id="search-bar-mobile">
            @csrf
            <input type="text" autocomplete="off" tabindex="-1" style="position:absolute;opacity:0;height:0;width:0;border:0;padding:0;">
            <input type="text" id="search-bar-input-mobile"
                name="m_{{ $searchNonce }}"
                autocomplete="off" data-autocomplete="off" aria-autocomplete="none"
                autocorrect="off" autocapitalize="none" spellcheck="false" inputmode="search" enterkeyhint="search"
                placeholder="Search for the Latest iPad"
                readonly
                onfocus="assignRandomName(this);releaseSearchReadonly(this);"
                class="w-full px-4 py-2 rounded-l-full bg-white text-gray-700 border border-gray-300 text-base focus:outline-none focus:border-[#0479FF]" />
            <button type="button" id="search-bar-btn-mobile" class="px-4 py-2 rounded-r-full bg-[#0479FF] flex items-center justify-center">
                <img src="{{ asset('icons/search.webp') }}" alt="Search" class="h-6 w-6" />
            </button>
            <div id="search-bar-results-mobile" class="absolute top-full left-0 w-full bg-white border border-gray-200 rounded-b-xl shadow-lg z-30 hidden"></div>
            <input type="password" autocomplete="new-password" style="position:absolute;opacity:0;height:0;width:0;border:0;padding:0;">
        </form>
    </div>
    <!-- Slide-out sidenav menu (desktop/mobile) -->
    <div id="mySidenav" class="sidenav custom-sidenav">
        <a href="javascript:void(0)" class="closebtn" onclick="closeNav()">&times;</a>
        <a href="/" class="sidenav-link">Home</a>
        <div class="sidenav-dropdown">
            <a href="javascript:void(0)" onclick="toggleDropdown('shopDropdown')" class="sidenav-link">Shop <span class="dropdown-arrow">&#9662;</span></a>
            <div id="shopDropdown" class="dropdown-content">
                <a href="{{ route('shop-all') }}" class="dropdown-link">All Products</a>
                @foreach(\App\Models\Products::pluck('product_category')->unique()->sort() as $cat)
                <a href="{{ route('shop.category', ['category' => $cat]) }}" class="dropdown-link">{{ $cat }}</a>
                @endforeach
            </div>
        </div>
        <div class="sidenav-dropdown">
            <a href="javascript:void(0)" onclick="toggleDropdown('brandsDropdown')" class="sidenav-link">Brands <span class="dropdown-arrow">&#9662;</span></a>
            <div id="brandsDropdown" class="dropdown-content">
                @foreach(\App\Models\Products::pluck('brand_name')->unique()->sort() as $brand)
                <a href="{{ route('shop-all', ['brand' => $brand]) }}" class="dropdown-link">{{ $brand }}</a>
                @endforeach
            </div>
        </div>
        <a href="{{ route('shop-all', ['new_stock' => 1]) }}" class="sidenav-link">New Products</a>
        <a href="{{ route('shop-all', ['discounted' => 1]) }}" class="sidenav-link">Discount Products</a>
        <a href="{{ route('contact-us') }}" class="sidenav-link">Contact Us</a>
    </div>
    <style>
        /* Styles: sidenav, dropdowns, and search UI */
        .custom-sidenav {
            height: 100%;
            width: 0;
            position: fixed;
            z-index: 1000;
            top: 0;
            left: 0;
            background: #fff;
            box-shadow: 0 4px 24px rgba(0, 0, 0, 0.12);
            overflow-x: hidden;
            transition: 0.4s cubic-bezier(.4, 0, .2, 1);
            padding-top: 40px;
        }

        .custom-sidenav .closebtn {
            position: absolute;
            top: 12px;
            right: 18px;
            font-size: 32px;
            color: #333;
            background: none;
            border: none;
            cursor: pointer;
        }

        .sidenav-link {
            padding: 14px 32px;
            font-size: 1.15rem;
            font-weight: 600;
            color: #222;
            display: block;
            border-radius: 9px;
            /* was 8px */
            margin: 6px 12px;
            transition: background 0.2s, color 0.2s;
            text-decoration: none;
        }

        .sidenav-link:hover {
            background: #f3f6fa;
            color: #0479FF;
        }

        .sidenav-dropdown {
            margin-bottom: 8px;
        }

        .dropdown-arrow {
            float: right;
            font-size: 1rem;
            margin-left: 8px;
        }

        .dropdown-content {
            display: none;
            background: #f8f9fa;
            border-radius: 9px;
            /* was 8px */
            margin: 4px 24px 8px 24px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
            padding: 6px 0;
            transition: max-height 0.3s;
        }

        .dropdown-link {
            padding: 10px 24px;
            font-size: 1rem;
            color: #444;
            display: block;
            border-radius: 4.5px;
            /* was 6px */
            margin: 2px 0;
            text-decoration: none;
            transition: background 0.2s, color 0.2s;
        }

        .dropdown-link:hover {
            background: #eaf3ff;
            color: #0479FF;
        }

        .search-result-item {
            /* Remove margin-bottom to eliminate extra spacing */
            box-sizing: border-box;
        }

        #search-bar-results-desktop,
        #search-bar-results-mobile {
            max-height: 340px;
            overflow-y: auto;
        }

        mark.search-highlight {
            background: none;
            color: inherit;
            border-radius: 0;
            padding: 0;
            font-weight: inherit;
        }

        /* Border-radius hierarchy: 18px for search inputs/buttons/results */
        #search-bar-input-desktop {
            border-top-left-radius: 18px;
            border-bottom-left-radius: 18px;
        }

        #search-bar-btn-desktop {
            border-top-right-radius: 18px;
            border-bottom-right-radius: 18px;
        }

        #search-bar-results-desktop {
            border-bottom-left-radius: 18px;
            border-bottom-right-radius: 18px;
        }

        #search-bar-input-mobile {
            border-top-left-radius: 18px;
            border-bottom-left-radius: 18px;
        }

        #search-bar-btn-mobile {
            border-top-right-radius: 18px;
            border-bottom-right-radius: 18px;
        }

        #search-bar-results-mobile {
            border-bottom-left-radius: 18px;
            border-bottom-right-radius: 18px;
        }
    </style>
    <script>
        // Navigation JS: sidenav open/close, dropdown toggles, and search autocomplete

        // Sidenav controls
        function openNav() {
            document.getElementById("mySidenav").style.width = "320px";
        }

        function closeNav() {
            document.getElementById("mySidenav").style.width = "0";
            document.getElementById('shopDropdown').style.display = 'none';
            document.getElementById('brandsDropdown').style.display = 'none';
        }

        // Dropdown toggling
        function toggleDropdown(id) {
            var el = document.getElementById(id);
            el.style.display = (el.style.display === 'block') ? 'none' : 'block';
        }

        // Search bar: setup, fetch suggestions, render, and navigation
        function setupSearchBar(inputId, btnId, resultsId) {
            const input = document.getElementById(inputId);
            const resultsDiv = document.getElementById(resultsId);
            const searchBtn = document.getElementById(btnId);
            let timer = null;
            let results = [];

            function showResults(items) {
                if (!items.length) {
                    resultsDiv.innerHTML = '<div class="p-4 text-gray-400 text-sm">No results found</div>';
                    resultsDiv.classList.remove('hidden');
                    return;
                }
                // Get search words
                const searchVal = input.value.trim();
                const words = searchVal.length ? searchVal.split(/\s+/).filter(Boolean) : [];

                function highlight(text) {
                    if (!words.length) return text;
                    // Only highlight exact word matches (word boundaries)
                    let pattern = words.map(w => w.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('|');
                    return text.replace(new RegExp(`\\b(${pattern})\\b`, 'gi'), '<span class="font-bold text-[#0479FF]">$1</span>');
                }
                resultsDiv.innerHTML = items.map((item, idx) => {
                    let priceHtml = '';
                    if (item.discount > 0) {
                        if (item.min_price !== item.max_price) {
                            priceHtml = `<span class='line-through text-gray-400 text-xs'>$${item.min_price} - $${item.max_price}</span> <span class='ml-1 text-gray-800 font-medium'>$${item.discounted_min} - $${item.discounted_max}</span>`;
                        } else {
                            priceHtml = `<span class='line-through text-gray-400 text-xs'>$${item.min_price}</span> <span class='ml-1 text-gray-800 font-medium'>$${item.discounted_min}</span>`;
                        }
                    } else {
                        if (item.min_price !== item.max_price) {
                            priceHtml = `<span class='text-gray-800 font-medium'>$${item.min_price} - $${item.max_price}</span>`;
                        } else {
                            priceHtml = `<span class='text-gray-800 font-medium'>$${item.min_price}</span>`;
                        }
                    }
                    return `
                    <div class="search-result-item flex items-center gap-3 px-4 py-3 cursor-pointer transition hover:bg-[#f3f6fa] ${idx !== 0 ? 'border-t border-gray-100' : ''}" data-id="${item.id}">
                        <img src="/${item.image}" alt="" class="w-10 flex-shrink-0" />
                        <div class="flex flex-col flex-1 min-w-0">
                            <div class="font-medium text-base text-gray-900 truncate">${highlight(item.product_name)}</div>
                            <div class="text-xs text-gray-500 truncate">${item.brand_name}</div>
                            <div class="text-sm mt-1">${priceHtml}</div>
                        </div>
                    </div>
                    `;
                }).join('');
                resultsDiv.classList.remove('hidden');
                Array.from(resultsDiv.children).forEach((el, idx) => {
                    el.onclick = function() {
                        window.location.href = `/product/${items[idx].id}`;
                    };
                });
            }
            if (!input) return;
            input.addEventListener('input', function(e) {
                const val = input.value.trim();
                clearTimeout(timer);
                if (val.length < 2) {
                    resultsDiv.classList.add('hidden');
                    return;
                }
                timer = setTimeout(() => {
                    fetch(`/search-bar/suggest?q=${encodeURIComponent(val)}`)
                        .then(r => r.json())
                        .then(data => {
                            results = data;
                            showResults(data);
                        });
                }, 200);
            });
            input.addEventListener('keydown', function(e) {
                if (e.key === 'Enter') {
                    const val = input.value.trim();
                    if (val.length > 0) {
                        window.location.href = `/shop-all?search=${encodeURIComponent(val)}`;
                    }
                }
            });
            if (searchBtn) {
                searchBtn.addEventListener('click', function() {
                    const val = input.value.trim();
                    if (val.length > 0) {
                        window.location.href = `/shop-all?search=${encodeURIComponent(val)}`;
                    }
                });
            }
            document.addEventListener('click', function(e) {
                if (!resultsDiv.contains(e.target) && e.target !== input) {
                    resultsDiv.classList.add('hidden');
                }
            });
        }
        setupSearchBar('search-bar-input-desktop', 'search-bar-btn-desktop', 'search-bar-results-desktop');
        setupSearchBar('search-bar-input-mobile', 'search-bar-btn-mobile', 'search-bar-results-mobile');

        // Input helpers: random name assignment and readonly release
        function assignRandomName(el) {
            if (!el.dataset.named) {
                el.name = 'q_' + Math.random().toString(36).slice(2);
                el.dataset.named = '1';
            }
        }

        function releaseSearchReadonly(el) {
            if (el.hasAttribute('readonly')) {
                el.removeAttribute('readonly');
                const v = el.value;
                el.value = '';
                requestAnimationFrame(() => el.value = v);
                setTimeout(() => {
                    el.setAttribute('autocomplete', 'off');
                }, 30);
            }
        }
        ['search-bar-input-desktop', 'search-bar-input-mobile'].forEach(id => {
            const el = document.getElementById(id);
            if (!el) return;
            el.addEventListener('keydown', e => {
                // Prevent browser suggestion list navigation from opening (ArrowDown often triggers)
                if (e.key === 'ArrowDown' && e.target.value === '') {
                    e.preventDefault();
                }
                if (e.key === 'Enter') {
                    e.preventDefault();
                    const val = el.value.trim();
                    if (val.length) {
                        window.location.href = '/shop-all?search=' + encodeURIComponent(val);
                    }
                }
            });
        });
        // Extra hardening on load
        document.addEventListener('DOMContentLoaded', () => {
            ['search-bar-input-desktop', 'search-bar-input-mobile'].forEach(id => {
                const el = document.getElementById(id);
                if (!el) return;
                el.setAttribute('autocomplete', 'off');
                el.setAttribute('aria-autocomplete', 'none');
            });

            // Populate search inputs with current ?search= query (if present)
            const params = new URLSearchParams(window.location.search);
            const q = params.get('search');
            if (q) {
                ['search-bar-input-desktop', 'search-bar-input-mobile'].forEach(id => {
                    const el = document.getElementById(id);
                    if (el) {
                        el.removeAttribute('readonly');
                        el.value = q;
                    }
                });
            }
        });
    </script>
</nav>