<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>ByteCart | Shop Products</title>
    <link rel="icon" type="image/x-icon" href="{{ asset('logo/x-icon.webp') }}">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <style>
        /* Header styles */
        .shop-header {
            background: linear-gradient(90deg, #2563eb22 0%, #f3f4f6 100%);
            border-radius: 18px;
            padding: 2.2rem 2rem 1.5rem 2rem;
            margin-bottom: 2.5rem;
            box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.07);
            display: flex;
            align-items: center;
            gap: 1.2rem;
        }

        .shop-header-icon {
            width: 48px;
            height: 48px;
            aspect-ratio: 1/1;
            background: #2563eb22;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .shop-header-title {
            font-size: 2.1rem;
            font-weight: 700;
            color: #1e293b;
            margin-bottom: 0.2rem;
        }

        .shop-header-subtitle {
            font-size: 1.1rem;
            color: #64748b;
            font-weight: 500;
        }

        /* Improved filter sidebar styles */
        .filter-sidebar {
            background: #fff;
            border-radius: 18px;
            /* unified shadow with product card, all-around */
            box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);
            padding: 1.1rem 1.2rem;
            margin-bottom: 2rem;
            height: 1200px;
            transition: box-shadow 0.2s;
        }

        .filter-sidebar:hover {
            box-shadow: 0 8px 32px 0 rgba(30, 41, 59, 0.18);
        }

        @media (min-width: 1024px) {
            .filter-sidebar {
                min-width: 260px;
                max-width: 300px;
                margin-right: 1.5rem;
                margin-bottom: 0;
                position: sticky;
                top: 32px;
            }
        }

        .filter-section {
            margin-bottom: 1.1rem;
            padding-bottom: 1.1rem;
            border-bottom: 1px solid #e5e7eb;
        }

        .filter-section:last-child {
            border-bottom: none;
            margin-bottom: 0;
            padding-bottom: 0;
        }

        .filter-section-title {
            font-size: 1rem;
            font-weight: 600;
            margin-bottom: 0.5rem;
            letter-spacing: 0.01em;
            display: flex;
            align-items: center;
            gap: 0.4em;
        }

        .filter-section-title::before {
            content: '';
            display: inline-block;
            width: 5px;
            height: 16px;
            border-radius: 4.5px;
            background: #2563eb22;
            margin-right: 0.4em;
        }

        .filter-label {
            display: flex;
            align-items: center;
            gap: 0.4em;
            font-size: 0.95em;
            padding: 0.12em 0.08em;
            border-radius: 4.5px;
            transition: background 0.15s;
            margin-bottom: 0.5em;
        }

        .filter-label:hover {
            background: #f3f4f6;
        }

        .filter-input {
            margin-right: 0.4em;
            padding: 0.25em 0.5em;
            border-radius: 9px;
            border: 1px solid #e5e7eb;
            font-size: 0.97em;
            background: #fafbfc;
            outline: none;
        }

        .filter-input:focus {
            border-color: #2563eb55;
            background: #f0f4ff;
        }

        .filter-range-inputs {
            display: flex;
            gap: 0.4em;
        }

        .filter-range-inputs input {
            flex: 1 1 0;
            min-width: 0;
        }

        .filter-actions {
            display: flex;
            gap: 0.5em;
            margin-top: 1.1rem;
        }

        .filter-btn {
            padding: 0.6rem 1.5rem;
            border-radius: 9px;
            font-weight: 600;
            border: none;
            cursor: pointer;
        }

        .filter-btn-reset {
            background: #e5e7eb;
            color: #374151;
        }

        /* Apply button (desktop) */
        .filter-btn-apply {
            background: #2563eb;
            color: #fff;
        }

        .filter-btn-apply:hover {
            background: #1d4ed8;
        }

        /* Inline desktop price range row */
        .price-range-row {
            display: flex;
            align-items: center;
            gap: 0.45em;
            margin-bottom: 0.2rem;
        }

        .price-range-row input {
            flex: 1 1 0;
            min-width: 0;
        }

        .price-sep {
            color: #64748b;
            font-weight: 600;
            user-select: none;
        }

        .price-apply-btn {
            background: #2563eb;
            color: #fff;
            border: none;
            padding: 0.55rem 0.9rem;
            border-radius: 8px;
            font-size: 0.8rem;
            font-weight: 600;
            cursor: pointer;
            line-height: 1;
            white-space: nowrap;
        }

        .price-apply-btn:hover {
            background: #1d4ed8;
        }

        .filter-scroll {
            max-height: 110px;
            overflow-y: auto;
            padding-right: 2px;
        }

        @media (max-width: 1023px) {
            .filter-sidebar {
                max-width: 380px;
                margin: 0 auto 2rem auto;
                position: static;
                top: auto;
            }
        }

        /* Remove extra whitespace from form elements */
        .filter-sidebar input,
        .filter-sidebar select {
            margin-bottom: 0;
        }

        .filter-sidebar label {
            margin-bottom: 0;
        }

        .filter-search-group {
            display: flex;
            align-items: center;
            background: #f3f4f6;
            border-radius: 9px;
            padding: 0.1em 0.5em;
            margin-bottom: 0.5em;
            border: 1px solid #e5e7eb;
        }

        .filter-search-icon {
            display: inline-block;
            width: 16px;
            height: 16px;
            margin-right: 0.3em;
            color: #94a3b8;
        }

        .filter-search-input {
            border: none;
            background: transparent;
            outline: none;
            font-size: 0.97em;
            width: 100%;
            padding: 0.3em 0;
        }

        .filter-search-input::placeholder {
            color: #94a3b8;
            opacity: 1;
        }

        /* Custom radio/checkbox styles for black when selected */
        .filter-radio,
        .filter-checkbox {
            accent-color: #000000;
        }

        /* Product grid styles */
        .custom-card-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
            gap: 2.2rem 1.7rem;
            margin-bottom: 2.5rem;
        }

        @media (max-width: 1023px) {
            .custom-card-grid {
                margin-top: -30px;
            }
        }

        @media (min-width: 1024px) {
            .custom-card-grid {
                margin-top: -24px;
            }
        }

        /* Floating filter button for mobile */
        .mobile-filter-btn {
            display: none;
            position: fixed;
            bottom: 24px;
            right: 24px;
            z-index: 50;
            background: #2563eb;
            color: #fff;
            border-radius: 50%;
            width: 56px;
            height: 56px;
            box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.18);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 2rem;
            cursor: pointer;
            border: none;
        }

        @media (max-width: 1023px) {
            .mobile-filter-btn {
                display: flex;
            }
        }

        /* Mobile filter modal/drawer */
        .mobile-filter-modal {
            display: none;
            position: fixed;
            z-index: 100;
            left: 0;
            top: 0;
            width: 100vw;
            height: 100vh;
            background: rgba(0, 0, 0, 0.5);
            backdrop-filter: blur(4px);
            -webkit-backdrop-filter: blur(4px);
            align-items: flex-end;
            justify-content: center;
        }

        .mobile-filter-modal.active {
            display: flex;
        }

        .mobile-filter-content {
            background: #fff;
            border-radius: 24px 24px 0 0;
            box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);
            width: 100%;
            max-width: 100%;
            margin-bottom: 0;
            padding: 1.2rem 1.2rem 6rem 1.2rem;
            min-height: 60vh;
            max-height: 90vh;
            overflow-y: auto;
            position: relative;
        }

        .mobile-filter-close {
            position: absolute;
            top: 18px;
            right: 18px;
            background: #f3f4f6;
            border-radius: 50%;
            width: 36px;
            height: 36px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.3rem;
            color: #64748b;
            border: none;
            cursor: pointer;
            z-index: 10;
        }

        /* Floating apply and reset buttons inside modal */
        .mobile-filter-actions {
            position: fixed;
            bottom: 24px;
            left: 50%;
            transform: translateX(-50%);
            z-index: 200;
            display: none;
            gap: 1rem;
            justify-content: center;
            width: auto;
            padding: 0 1rem;
        }

        .mobile-filter-modal.active .mobile-filter-actions {
            display: flex;
        }

        .mobile-filter-apply-btn,
        .mobile-filter-reset-btn {
            background: #2563eb;
            color: #fff;
            border-radius: 999px;
            padding: 0.9rem 2.2rem;
            font-size: 1.1rem;
            font-weight: 700;
            box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.18);
            border: none;
            cursor: pointer;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            min-width: 100px;
        }

        .mobile-filter-reset-btn {
            background: #e5e7eb;
            color: #374151;
        }

        @media (min-width: 1024px) {

            .mobile-filter-modal,
            .mobile-filter-btn,
            .mobile-filter-actions {
                display: none !important;
            }
        }

        /* Hide sidebar on mobile */
        @media (max-width: 1023px) {
            .filter-sidebar {
                display: none;
            }
        }

        /* Pills for filter options */
        .filter-pills {
            display: flex;
            flex-wrap: wrap;
            gap: 0.5em;
            margin-bottom: 0.5em;
        }

        .filter-pill {
            display: inline-flex;
            align-items: center;
            padding: 0.32em 1em;
            font-size: 0.93em;
            border-radius: 999px;
            background: #f3f4f6;
            color: #374151;
            border: 1px solid #e5e7eb;
            cursor: pointer;
            transition: background 0.18s, color 0.18s, border-color 0.18s;
            font-weight: 500;
            margin-bottom: 0.2em;
            outline: none;
            position: relative;
            user-select: none;
        }

        .filter-pill.selected,
        .filter-pill:active {
            background: #2563eb;
            color: #fff;
            border-color: #2563eb;
        }

        .filter-pill input[type="radio"] {
            display: none;
        }

        /* Hide checkbox/radio for pills in mobile filter modal */
        .mobile-filter-content .filter-pill input[type="checkbox"],
        .mobile-filter-content .filter-pill input[type="radio"] {
            display: none;
        }

        /* Desktop pills override */
        @media (min-width: 1024px) {
            .filter-pills {
                gap: 0.32em;
                margin-bottom: 0.3em;
            }

            .filter-pill {
                padding: 0.18em 0.7em;
                font-size: 0.82em;
                margin-bottom: 0.15em;
                min-height: 1.7em;
            }

            .filter-pills-scroll {
                max-height: 90px;
            }
        }

        /* Pills container scroll for long lists */
        .filter-pills-scroll {
            max-height: 110px;
            overflow-y: auto;
            padding-right: 2px;
        }

        /* Pagination styles */
        .pager-wrap {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 0.75rem;
            background: #fff;
            border-radius: 18px;
            padding: 14px 18px;
            box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);
            width: 100%;
            max-width: none;
            /* was fit-content */
            margin: 0;
            /* was 0 auto */
        }

        .pager {
            display: flex;
            align-items: center;
            gap: 6px;
            flex-wrap: wrap;
            justify-content: center;
        }

        /* Showing X–Y of Z text (no bg/radius/shadow) */
        .pager-info {
            color: #475569;
            font-weight: 600;
            font-size: 0.9rem;
            line-height: 1;
            white-space: nowrap;
            flex: 0 0 auto;
            padding: 0 4px;
        }

        .pager a,
        .pager span.pager-btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 36px;
            height: 36px;
            border-radius: 50%;
            border: 1px solid #e5e7eb;
            background: #fff;
            color: #334155;
            font-weight: 600;
            text-decoration: none;
            transition: all .2s ease;
            font-size: 0.875rem;
            line-height: 1;
            flex-shrink: 0;
        }

        .pager a:hover:not(.disabled) {
            border-color: #3b82f6;
            background: #eff6ff;
            color: #3b82f6;
            transform: translateY(-1px);
        }

        .pager .active {
            background: #3b82f6 !important;
            border-color: #3b82f6 !important;
            color: #fff !important;
            box-shadow: 0 2px 8px rgba(59, 130, 246, 0.3);
        }

        .pager .disabled {
            opacity: 0.4;
            pointer-events: none;
            cursor: not-allowed;
        }

        .pager-ellipsis {
            width: 36px;
            height: 36px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            color: #94a3b8;
            font-weight: 700;
            font-size: 0.875rem;
            flex-shrink: 0;
        }

        .pager-meta {
            display: flex;
            align-items: center;
            gap: 6px;
            color: #475569;
            font-weight: 600;
            font-size: 0.875rem;
            white-space: nowrap;
            flex-shrink: 0;
        }

        .pager-meta select {
            appearance: none;
            -webkit-appearance: none;
            -moz-appearance: none;
            background: #f8fafc;
            background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='M6 8l4 4 4-4'/%3e%3c/svg%3e");
            background-position: right 8px center;
            background-repeat: no-repeat;
            background-size: 16px 16px;
            border: 1px solid #e5e7eb;
            border-radius: 999px;
            padding: 6px 28px 6px 12px;
            font-weight: 600;
            color: #1f2937;
            cursor: pointer;
            outline: none;
            font-size: 0.875rem;
            min-width: 60px;
        }

        .pager-meta select:hover {
            border-color: #3b82f6;
            background-color: #eff6ff;
        }

        .pager-meta select:focus {
            border-color: #3b82f6;
            box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
        }

        .pager-container {
            display: flex;
            justify-content: center;
            margin: 0;
            padding: 0;
            /* remove side padding so it spans the full container width */
        }

        /* Mobile specific adjustments */
        @media (max-width: 640px) {
            .pager-wrap {
                /* stack info above buttons on mobile */
                flex-direction: column;
                padding: 18px;
            }

            .pager {
                order: 2;
                /* was 1 - buttons below info on mobile */
                gap: 4px;
            }

            .pager-info {
                order: 1;
                /* was 2 - info first on mobile */
                text-align: center;
                font-size: 0.875rem;
                margin-bottom: 10px;
            }
        }

        /* Very small screens */
        @media (max-width: 480px) {
            .pager {
                gap: 2px;
            }

            .pager a,
            .pager span.pager-btn,
            .pager-ellipsis {
                width: 30px;
                height: 30px;
                font-size: 0.75rem;
            }
        }

        /* Tablet adjustments */
        @media (min-width: 641px) and (max-width: 1023px) {
            .pager-wrap {
                flex-direction: row;
                gap: 0.875rem;
            }

            .pager {
                gap: 5px;
            }
        }

        /* Desktop */
        @media (min-width: 1024px) {
            .pager-container {
                margin: 0;
                padding: 0;
                /* ensure no padding on desktop */
            }
        }

        /* Slide-up animation for the mobile filter (aligns with account navbar) */
        @keyframes slideUp {
            from {
                transform: translateY(100%);
                /* removed opacity fade */
            }

            to {
                transform: translateY(0);
                /* removed opacity fade */
            }
        }

        /* Animate the drawer when modal activates */
        .mobile-filter-modal.active .mobile-filter-content {
            animation: slideUp 0.2s ease-in;
            will-change: transform;
            /* removed opacity */
        }

        /* Slide-down animation for closing */
        @keyframes slideDown {
            from {
                transform: translateY(0);
            }

            to {
                transform: translateY(100%);
            }
        }

        /* Apply slide-down when closing (keep visible until animation ends) */
        .mobile-filter-modal.closing .mobile-filter-content {
            animation: slideDown 0.2s ease-in forwards;
        }
    </style>
    {{-- Add any other meta or CSS includes here --}}
</head>

<body>
    @livewire('nav-bar')

    @php
    // Local search filtering (fallback if controller not yet updated)
    $searchQuery = trim(request('search', ''));
    $displayProducts = $products;

    if ($searchQuery !== '' && $products) {
    // Support both Collection and LengthAwarePaginator
    $collection = method_exists($products, 'getCollection') ? $products->getCollection() : $products;
    $words = preg_split('/\s+/', $searchQuery);
    $filtered = $collection->filter(function($p) use ($words) {
    $hay = strtolower(($p->product_name ?? '') . ' ' . ($p->brand_name ?? '') . ' ' . ($p->product_category ?? ''));
    foreach ($words as $w) {
    if ($w === '') continue;
    if (strpos($hay, strtolower($w)) === false) return false;
    }
    return true;
    });

    if (method_exists($products, 'setCollection')) {
    // If paginator, replace its internal collection for iteration (count() will reflect filtered size)
    $products->setCollection($filtered);
    $displayProducts = $products;
    } else {
    $displayProducts = $filtered;
    }
    }

    // Ensure $displayProducts is paginated (28 per page) when it's a Collection
    if (!($displayProducts instanceof \Illuminate\Pagination\LengthAwarePaginator)) {
    $collection = $displayProducts instanceof \Illuminate\Support\Collection ? $displayProducts : collect($displayProducts);
    $page = max(1, (int) request()->get('page', 1));
    $perPage = 28;
    $total = $collection->count();
    $results = $collection->slice(($page - 1) * $perPage, $perPage)->values();

    $displayProducts = new \Illuminate\Pagination\LengthAwarePaginator(
    $results,
    $total,
    $perPage,
    $page,
    ['path' => request()->url(), 'query' => request()->query()]
    );
    }

    // Result count (total when paginated)
    $resultCount = ($displayProducts instanceof \Illuminate\Pagination\LengthAwarePaginator)
    ? $displayProducts->total()
    : ($displayProducts?->count() ?? 0);

    // Showing range values
    $showingFrom = $displayProducts instanceof \Illuminate\Pagination\LengthAwarePaginator ? ($displayProducts->firstItem() ?? 0) : 0;
    $showingTo = $displayProducts instanceof \Illuminate\Pagination\LengthAwarePaginator ? ($displayProducts->lastItem() ?? 0) : 0;
    $totalItems = $displayProducts instanceof \Illuminate\Pagination\LengthAwarePaginator ? $displayProducts->total() : 0;

    // Small helper for page URL with preserved query
    $pageUrl = function(int $page) {
    return request()->fullUrlWithQuery(['page' => $page]);
    };

    // Helper to compute numbered pages with ellipses
    $pages = [];
    if ($displayProducts instanceof \Illuminate\Pagination\LengthAwarePaginator) {
    $last = $displayProducts->lastPage();
    $current = $displayProducts->currentPage();

    if ($last <= 7) {
        $pages=range(1, $last);
        } else {
        $pages=[1, 2];

        if ($current> 4) $pages[] = '...';

        // Show only current when near start to mimic the screenshot (1, 2, 3, …, 10)
        if ($current > 2 && $current < $last - 1) {
            if ($current> 3) $pages[] = $current - 1;
            $pages[] = $current;
            if ($current < $last - 2) $pages[]=$current + 1;
                } elseif ($current===3) {
                $pages[]=3;
                }

                if ($current < $last - 3) $pages[]='...' ;

                if (!in_array($last, $pages)) $pages[]=$last;

                // De-duplicate while preserving order
                $seen=[];
                $pages=array_values(array_filter($pages, function($p) use (&$seen) {
                $k=is_int($p) ? "n$p" : "e$p" ;
                if (isset($seen[$k])) return false;
                $seen[$k]=true;
                return true;
                }));
                }
                }
                @endphp

                <!-- Floating Filter Button (mobile only) -->
                <button class="mobile-filter-btn" id="openFilterBtn" aria-label="Open Filters">
                    <svg width="28" height="28" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path d="M4 6h16M6 12h12M8 18h8" stroke="currentColor" stroke-linecap="round" />
                    </svg>
                </button>

                <!-- Mobile Filter Modal -->
                <div class="mobile-filter-modal" id="mobileFilterModal">
                    <div class="mobile-filter-content">
                        <button class="mobile-filter-close" id="closeFilterBtn" aria-label="Close Filters">
                            <svg width="22" height="22" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                                <line x1="6" y1="6" x2="18" y2="18" stroke="currentColor" />
                                <line x1="6" y1="18" x2="18" y2="6" stroke="currentColor" />
                            </svg>
                        </button>
                        <!-- Filter Sidebar (mobile version, no auto-submit) -->
                        <form id="mobileFilterForm" method="GET" action="{{ route('shop-all') }}">
                            @csrf
                            <h3 class="text-xl font-bold border-b pb-2 mb-7 tracking-tight">Filters</h3>
                            <!-- Sort By Pills (single select, radio) -->
                            <div class="filter-section">
                                <div class="filter-section-title">Sort By</div>
                                <div class="filter-pills">
                                    <label class="filter-pill {{ $filterData['sort']=='' ? 'selected' : '' }}">
                                        <input type="radio" name="sort" value="" {{ $filterData['sort']=='' ? 'checked' : '' }}>
                                        Default
                                    </label>
                                    <label class="filter-pill {{ $filterData['sort']=='low_high' ? 'selected' : '' }}">
                                        <input type="radio" name="sort" value="low_high" {{ $filterData['sort']=='low_high' ? 'checked' : '' }}>
                                        Price: Low to High
                                    </label>
                                    <label class="filter-pill {{ $filterData['sort']=='high_low' ? 'selected' : '' }}">
                                        <input type="radio" name="sort" value="high_low" {{ $filterData['sort']=='high_low' ? 'checked' : '' }}>
                                        Price: High to Low
                                    </label>
                                    <label class="filter-pill {{ $filterData['sort']=='newest' ? 'selected' : '' }}">
                                        <input type="radio" name="sort" value="newest" {{ $filterData['sort']=='newest' ? 'checked' : '' }}>
                                        Newest Arrivals
                                    </label>
                                    <label class="filter-pill {{ $filterData['sort']=='oldest' ? 'selected' : '' }}">
                                        <input type="radio" name="sort" value="oldest" {{ $filterData['sort']=='oldest' ? 'checked' : '' }}>
                                        Oldest Arrivals
                                    </label>
                                </div>
                            </div>
                            <!-- Category (mobile now single-select like desktop) -->
                            <div class="filter-section">
                                <div class="filter-section-title">Category</div>
                                <div class="filter-search-group">
                                    <svg class="filter-search-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <circle cx="11" cy="11" r="8" stroke-width="2"></circle>
                                        <line x1="21" y1="21" x2="16.65" y2="16.65" stroke-width="2"></line>
                                    </svg>
                                    <input type="text" class="filter-search-input" placeholder="Search category..." oninput="filterCategoryOptions(this.value, true)">
                                </div>
                                <div class="filter-pills filter-pills-scroll" id="mobile-category-options">
                                    <label class="filter-pill {{ $filterData['category']=='' ? 'selected' : '' }}">
                                        <input type="radio" name="category" value="" {{ $filterData['category']=='' ? 'checked' : '' }}>
                                        All Categories
                                    </label>
                                    @foreach(collect($categories)->sort()->all() as $cat)
                                    <label class="filter-pill {{ $filterData['category']==$cat ? 'selected' : '' }}">
                                        <input type="radio" name="category" value="{{ $cat }}" {{ $filterData['category']==$cat ? 'checked' : '' }}>
                                        {{ $cat }}
                                    </label>
                                    @endforeach
                                </div>
                            </div>
                            <!-- Brand (mobile single-select) -->
                            <div class="filter-section">
                                <div class="filter-section-title">Brand</div>
                                <div class="filter-search-group">
                                    <svg class="filter-search-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <circle cx="11" cy="11" r="8" stroke-width="2"></circle>
                                        <line x1="21" y1="21" x2="16.65" y2="16.65" stroke-width="2"></line>
                                    </svg>
                                    <input type="text" class="filter-search-input" placeholder="Search brand..." oninput="filterBrandOptions(this.value, true)">
                                </div>
                                <div class="filter-pills filter-pills-scroll" id="mobile-brand-options">
                                    <label class="filter-pill {{ $filterData['brand']=='' ? 'selected' : '' }}">
                                        <input type="radio" name="brand" value="" {{ $filterData['brand']=='' ? 'checked' : '' }}>
                                        All Brands
                                    </label>
                                    @foreach(collect($brands)->sort()->all() as $brand)
                                    <label class="filter-pill {{ $filterData['brand']==$brand ? 'selected' : '' }}">
                                        <input type="radio" name="brand" value="{{ $brand }}" {{ $filterData['brand']==$brand ? 'checked' : '' }}>
                                        {{ $brand }}
                                    </label>
                                    @endforeach
                                </div>
                            </div>
                            <!-- Color (mobile single-select) -->
                            <div class="filter-section">
                                <div class="filter-section-title">Color</div>
                                <div class="filter-search-group">
                                    <svg class="filter-search-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <circle cx="11" cy="11" r="8" stroke-width="2"></circle>
                                        <line x1="21" y1="21" x2="16.65" y2="16.65" stroke-width="2"></line>
                                    </svg>
                                    <input type="text" class="filter-search-input" placeholder="Search color..." oninput="filterColorOptions(this.value, true)">
                                </div>
                                <div class="filter-pills filter-pills-scroll" id="mobile-color-options">
                                    <label class="filter-pill {{ $filterData['color']=='' ? 'selected' : '' }}">
                                        <input type="radio" name="color" value="" {{ $filterData['color']=='' ? 'checked' : '' }}>
                                        All Colors
                                    </label>
                                    @foreach(collect($colors)->sort()->all() as $color)
                                    <label class="filter-pill {{ $filterData['color']==$color ? 'selected' : '' }}">
                                        <input type="radio" name="color" value="{{ $color }}" {{ $filterData['color']==$color ? 'checked' : '' }}>
                                        {{ $color }}
                                    </label>
                                    @endforeach
                                </div>
                            </div>
                            <div class="filter-section">
                                <div class="filter-section-title">Price Range ($)</div>
                                <div class="filter-range-inputs mb-3">
                                    <input type="number" name="min_price" class="filter-input" placeholder="Min"
                                        value="{{ $filterData['min_price'] }}">
                                    <input type="number" name="max_price" class="filter-input" placeholder="Max"
                                        value="{{ $filterData['max_price'] }}">
                                </div>
                            </div>
                            <div class="filter-section">
                                <div class="filter-section-title">Availability</div>
                                <label class="filter-label">
                                    <input type="checkbox" name="availability" value="1" class="filter-checkbox"
                                        {{ $filterData['availability'] ? 'checked' : '' }}>
                                    In Stock Only
                                </label>
                            </div>
                            <div class="filter-actions" style="display:none"></div>
                        </form>
                    </div>
                    <!-- Floating Apply and Reset Buttons (moved outside content for proper positioning) -->
                    <div class="mobile-filter-actions">
                        <button type="submit" form="mobileFilterForm" class="mobile-filter-apply-btn">Apply</button>
                        <a href="{{ route('shop-all') }}" class="mobile-filter-reset-btn">Reset</a>
                    </div>
                </div>
                <div class="w-full mx-auto pb-8 pt-5 px-4 sm:px-16 sm:pb-10 sm:pt-5" style="margin-bottom:0;">
                    <!-- Desktop layout: Filter | Header + Product cards -->
                    <div class="hidden lg:flex gap-8">
                        <!-- Filter Sidebar (desktop only, left) -->
                        <form class="filter-sidebar w-full lg:w-1/4" method="GET" action="{{ route('shop-all') }}">
                            @csrf
                            <h3 class="text-xl font-bold border-b pb-2 mb-7 tracking-tight">Filters</h3>
                            <!-- Sort By Pills (single select, radio) -->
                            <div class="filter-section">
                                <div class="filter-section-title">Sort By</div>
                                <div class="filter-pills">
                                    <label class="filter-pill {{ $filterData['sort']=='' ? 'selected' : '' }}">
                                        <input type="radio" name="sort" value="" {{ $filterData['sort']=='' ? 'checked' : '' }} onchange="this.form.submit()">
                                        Default
                                    </label>
                                    <label class="filter-pill {{ $filterData['sort']=='low_high' ? 'selected' : '' }}">
                                        <input type="radio" name="sort" value="low_high" {{ $filterData['sort']=='low_high' ? 'checked' : '' }} onchange="this.form.submit()">
                                        Price: Low to High
                                    </label>
                                    <label class="filter-pill {{ $filterData['sort']=='high_low' ? 'selected' : '' }}">
                                        <input type="radio" name="sort" value="high_low" {{ $filterData['sort']=='high_low' ? 'checked' : '' }} onchange="this.form.submit()">
                                        Price: High to Low
                                    </label>
                                    <label class="filter-pill {{ $filterData['sort']=='newest' ? 'selected' : '' }}">
                                        <input type="radio" name="sort" value="newest" {{ $filterData['sort']=='newest' ? 'checked' : '' }} onchange="this.form.submit()">
                                        Newest Arrivals
                                    </label>
                                    <label class="filter-pill {{ $filterData['sort']=='oldest' ? 'selected' : '' }}">
                                        <input type="radio" name="sort" value="oldest" {{ $filterData['sort']=='oldest' ? 'checked' : '' }} onchange="this.form.submit()">
                                        Oldest Arrivals
                                    </label>
                                </div>
                            </div>
                            <!-- Category Pills (multi-select, checkbox) -->
                            <div class="filter-section">
                                <div class="filter-section-title">Category</div>
                                <div class="filter-search-group">
                                    <svg class="filter-search-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <circle cx="11" cy="11" r="8" stroke-width="2"></circle>
                                        <line x1="21" y1="21" x2="16.65" y2="16.65" stroke-width="2"></line>
                                    </svg>
                                    <input type="text" class="filter-search-input" placeholder="Search category..." oninput="filterCategoryOptions(this.value)">
                                </div>
                                <div class="filter-pills filter-pills-scroll" id="category-options">
                                    <label class="filter-pill {{ $filterData['category']=='' ? 'selected' : '' }}">
                                        <input type="radio" name="category" value="" {{ $filterData['category']=='' ? 'checked' : '' }} onchange="this.form.submit()">
                                        All Categories
                                    </label>
                                    @foreach(collect($categories)->sort()->all() as $cat)
                                    <label class="filter-pill {{ $filterData['category']==$cat ? 'selected' : '' }}">
                                        <input type="radio" name="category" value="{{ $cat }}" {{ $filterData['category']==$cat ? 'checked' : '' }} onchange="this.form.submit()">
                                        {{ $cat }}
                                    </label>
                                    @endforeach
                                </div>
                            </div>
                            <!-- Brand Pills (multi-select, checkbox) -->
                            <div class="filter-section">
                                <div class="filter-section-title">Brand</div>
                                <div class="filter-search-group">
                                    <svg class="filter-search-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <circle cx="11" cy="11" r="8" stroke-width="2"></circle>
                                        <line x1="21" y1="21" x2="16.65" y2="16.65" stroke-width="2"></line>
                                    </svg>
                                    <input type="text" class="filter-search-input" placeholder="Search brand..." oninput="filterBrandOptions(this.value)">
                                </div>
                                <div class="filter-pills filter-pills-scroll" id="brand-options">
                                    <label class="filter-pill {{ $filterData['brand']=='' ? 'selected' : '' }}">
                                        <input type="radio" name="brand" value="" {{ $filterData['brand']=='' ? 'checked' : '' }} onchange="this.form.submit()">
                                        All Brands
                                    </label>
                                    @foreach(collect($brands)->sort()->all() as $brand)
                                    <label class="filter-pill {{ $filterData['brand']==$brand ? 'selected' : '' }}">
                                        <input type="radio" name="brand" value="{{ $brand }}" {{ $filterData['brand']==$brand ? 'checked' : '' }} onchange="this.form.submit()">
                                        {{ $brand }}
                                    </label>
                                    @endforeach
                                </div>
                            </div>
                            <!-- Color Pills (multi-select, checkbox) -->
                            <div class="filter-section">
                                <div class="filter-section-title">Color</div>
                                <div class="filter-search-group">
                                    <svg class="filter-search-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <circle cx="11" cy="11" r="8" stroke-width="2"></circle>
                                        <line x1="21" y1="21" x2="16.65" y2="16.65" stroke-width="2"></line>
                                    </svg>
                                    <input type="text" class="filter-search-input" placeholder="Search color..." oninput="filterColorOptions(this.value)">
                                </div>
                                <div class="filter-pills filter-pills-scroll" id="color-options">
                                    <label class="filter-pill {{ $filterData['color']=='' ? 'selected' : '' }}">
                                        <input type="radio" name="color" value="" {{ $filterData['color']=='' ? 'checked' : '' }} onchange="this.form.submit()">
                                        All Colors
                                    </label>
                                    @foreach(collect($colors)->sort()->all() as $color)
                                    <label class="filter-pill {{ $filterData['color']==$color ? 'selected' : '' }}">
                                        <input type="radio" name="color" value="{{ $color }}" {{ $filterData['color']==$color ? 'checked' : '' }} onchange="this.form.submit()">
                                        {{ $color }}
                                    </label>
                                    @endforeach
                                </div>
                            </div>
                            <div class="filter-section">
                                <div class="filter-section-title">Price Range ($)</div>
                                <div class="price-range-row">
                                    <input type="number" name="min_price" class="filter-input" placeholder="Min" value="{{ $filterData['min_price'] }}">
                                    <span class="price-sep">–</span>
                                    <input type="number" name="max_price" class="filter-input" placeholder="Max" value="{{ $filterData['max_price'] }}">
                                    <button type="submit" class="price-apply-btn" title="Apply price range">Apply</button>
                                </div>
                            </div>
                            <div class="filter-section">
                                <div class="filter-section-title">Availability</div>
                                <label class="filter-label">
                                    <input type="checkbox" name="availability" value="1" class="filter-checkbox"
                                        {{ $filterData['availability'] ? 'checked' : '' }}>
                                    In Stock Only
                                </label>
                            </div>
                            <div class="filter-actions">
                                <button type="submit" class="filter-btn filter-btn-apply flex-1">Apply</button>
                                <a href="{{ route('shop-all') }}" class="filter-btn filter-btn-reset text-center flex-1">Reset</a>
                            </div>
                        </form>
                        <!-- Right column: Header + Product Grid -->
                        <div class="flex-1 flex flex-col">
                            <!-- Attractive Header Section (desktop only) -->
                            <div class="shop-header mb-0 lg:mb-[40px]">
                                <div class="shop-header-icon">
                                    <svg width="32" height="32" fill="none" stroke="#2563eb" stroke-width="2" viewBox="0 0 24 24">
                                        <rect x="3" y="7" width="18" height="13" rx="3" fill="#2563eb22" />
                                        <path d="M3 7V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v2" stroke="#2563eb" />
                                    </svg>
                                </div>
                                <div>
                                    @if($searchQuery !== '')
                                    <div class="shop-header-title">
                                        Search results for "{{ $searchQuery }}"
                                    </div>
                                    <div class="shop-header-subtitle">
                                        @if($resultCount > 0)
                                        {{ $resultCount }} product{{ $resultCount === 1 ? '' : 's' }} found
                                        @else
                                        No results found. Try different keywords.
                                        @endif
                                    </div>
                                    @else
                                    <div class="shop-header-title">Shop Products</div>
                                    <div class="shop-header-subtitle">
                                        Discover our wide range of electronics. Use filters to quickly find exactly what you’re looking for!
                                    </div>
                                    @endif
                                </div>
                            </div>
                            <!-- Product Grid -->
                            <div class="flex items-center justify-between mb-6 flex-wrap gap-4">
                                <!-- Remove sort dropdown from here -->
                                {{-- @foreach(request()->except('sort') as $key => $value)
                    <input type="hidden" name="{{ $key }}" value="{{ $value }}">
                                @endforeach
                                <select name="sort" id="sort" class="filter-input w-auto" onchange="this.form.submit()">
                                    <option value="">Default</option>
                                    <option value="low_high" {{ $filterData['sort']=='low_high' ? 'selected' : '' }}>Price: Low to High</option>
                                    <option value="high_low" {{ $filterData['sort']=='high_low' ? 'selected' : '' }}>Price: High to Low</option>
                                    <option value="newest" {{ $filterData['sort']=='newest' ? 'selected' : '' }}>Newest Arrivals</option>
                                    <option value="oldest" {{ $filterData['sort']=='oldest' ? 'selected' : '' }}>Oldest Arrivals</option>
                                </select> --}}
                            </div>
                            <div class="custom-card-grid">
                                @forelse($displayProducts as $product)
                                @include('livewire.product-card', ['product' => $product])
                                @empty
                                <div class="col-span-full no-products-msg text-center">
                                    @if($searchQuery !== '')
                                    No products match "{{ $searchQuery }}".
                                    @else
                                    No products found. Try adjusting your filters!
                                    @endif
                                </div>
                                @endforelse
                            </div>

                            {{-- Pagination (desktop) --}}
                            @if($displayProducts instanceof \Illuminate\Pagination\LengthAwarePaginator && $displayProducts->lastPage() > 1)
                            <div class="pager-container">
                                <div class="pager-wrap w-full">
                                    <div class="pager-info">Showing {{ $showingFrom }}–{{ $showingTo }} Out Of {{ $totalItems }}</div>
                                    <div class="pager">
                                        {{-- First --}}
                                        <a href="{{ $pageUrl(1) }}" class="pager-btn {{ $displayProducts->onFirstPage() ? 'disabled' : '' }}" aria-label="First page">
                                            «
                                        </a>
                                        {{-- Previous --}}
                                        <a href="{{ $displayProducts->previousPageUrl() ?: $pageUrl(1) }}" class="pager-btn {{ $displayProducts->onFirstPage() ? 'disabled' : '' }}" aria-label="Previous page">
                                            ‹
                                        </a>

                                        {{-- Numbers + ellipsis --}}
                                        @foreach($pages as $p)
                                        @if($p === '...')
                                        <span class="pager-ellipsis">…</span>
                                        @else
                                        @if($p == $displayProducts->currentPage())
                                        <span class="pager-btn active">{{ $p }}</span>
                                        @else
                                        <a href="{{ $pageUrl($p) }}" class="pager-btn">{{ $p }}</a>
                                        @endif
                                        @endif
                                        @endforeach

                                        {{-- Next --}}
                                        <a href="{{ $displayProducts->nextPageUrl() ?: $pageUrl($displayProducts->lastPage()) }}" class="pager-btn {{ $displayProducts->currentPage() == $displayProducts->lastPage() ? 'disabled' : '' }}" aria-label="Next page">
                                            ›
                                        </a>
                                        {{-- Last --}}
                                        <a href="{{ $pageUrl($displayProducts->lastPage()) }}" class="pager-btn {{ $displayProducts->currentPage() == $displayProducts->lastPage() ? 'disabled' : '' }}" aria-label="Last page">
                                            »
                                        </a>
                                    </div>
                                </div>
                            </div>
                            @endif
                        </div>
                    </div>
                    <!-- End desktop layout -->

                    <!-- Mobile layout (unchanged) -->
                    <div class="flex flex-col lg:hidden gap-8" style="margin-bottom:0;">
                        <!-- Attractive Header Section (mobile only) -->
                        <div class="shop-header">
                            <div class="shop-header-icon">
                                <svg width="32" height="32" fill="none" stroke="#2563eb" stroke-width="2" viewBox="0 0 24 24">
                                    <rect x="3" y="7" width="18" height="13" rx="3" fill="#2563eb22" />
                                    <path d="M3 7V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v2" stroke="#2563eb" />
                                </svg>
                            </div>
                            <div>
                                @if($searchQuery !== '')
                                <div class="shop-header-title">
                                    "{{ $searchQuery }}"
                                </div>
                                <div class="shop-header-subtitle">
                                    @if($resultCount > 0)
                                    {{ $resultCount }} product{{ $resultCount === 1 ? '' : 's' }} found
                                    @else
                                    No results found
                                    @endif
                                </div>
                                @else
                                <div class="shop-header-title">Shop Products</div>
                                <div class="shop-header-subtitle">
                                    Browse our full collection. Use filters to find what you need!
                                </div>
                                @endif
                            </div>
                        </div>
                        <div class="custom-card-grid" style="margin-bottom:0;">
                            @forelse($displayProducts as $product)
                            @include('livewire.product-card', ['product' => $product])
                            @empty
                            <div class="col-span-full no-products-msg text-center">
                                @if($searchQuery !== '')
                                No products match "{{ $searchQuery }}".
                                @else
                                No products found. Try adjusting your filters!
                                @endif
                            </div>
                            @endforelse
                        </div>

                        {{-- Pagination (mobile) --}}
                        @if($displayProducts instanceof \Illuminate\Pagination\LengthAwarePaginator && $displayProducts->lastPage() > 1)
                        <div class="pager-container">
                            <div class="pager-wrap w-full">
                                <div class="pager-info">Showing {{ $showingFrom }}–{{ $showingTo }} Out Of {{ $totalItems }}</div>
                                <div class="pager">
                                    <a href="{{ $pageUrl(1) }}" class="pager-btn {{ $displayProducts->onFirstPage() ? 'disabled' : '' }}" aria-label="First page">«</a>
                                    <a href="{{ $displayProducts->previousPageUrl() ?: $pageUrl(1) }}" class="pager-btn {{ $displayProducts->onFirstPage() ? 'disabled' : '' }}" aria-label="Previous page">‹</a>

                                    @foreach($pages as $p)
                                    @if($p === '...')
                                    <span class="pager-ellipsis">…</span>
                                    @else
                                    @if($p == $displayProducts->currentPage())
                                    <span class="pager-btn active">{{ $p }}</span>
                                    @else
                                    <a href="{{ $pageUrl($p) }}" class="pager-btn">{{ $p }}</a>
                                    @endif
                                    @endif
                                    @endforeach

                                    <a href="{{ $displayProducts->nextPageUrl() ?: $pageUrl($displayProducts->lastPage()) }}" class="pager-btn {{ $displayProducts->currentPage() == $displayProducts->lastPage() ? 'disabled' : '' }}" aria-label="Next page">›</a>
                                    <a href="{{ $pageUrl($displayProducts->lastPage()) }}" class="pager-btn {{ $displayProducts->currentPage() == $displayProducts->lastPage() ? 'disabled' : '' }}" aria-label="Last page">»</a>
                                </div>
                            </div>
                        </div>
                        @endif
                    </div>
                    <!-- End mobile layout -->
                </div>

                <script>
                    // Brand search filter
                    function filterBrandOptions(search, mobile = false) {
                        let selector = mobile ? '#mobile-brand-options label' : '#brand-options label';
                        let options = document.querySelectorAll(selector);
                        options.forEach(opt => {
                            if (opt.textContent.toLowerCase().includes(search.toLowerCase())) {
                                opt.style.display = '';
                            } else {
                                opt.style.display = 'none';
                            }
                        });
                    }
                    // Category search filter
                    function filterCategoryOptions(search, mobile = false) {
                        let selector = mobile ? '#mobile-category-options label' : '#category-options label';
                        let options = document.querySelectorAll(selector);
                        options.forEach(opt => {
                            if (opt.textContent.toLowerCase().includes(search.toLowerCase())) {
                                opt.style.display = '';
                            } else {
                                opt.style.display = 'none';
                            }
                        });
                    }
                    // Color search filter
                    function filterColorOptions(search, mobile = false) {
                        let selector = mobile ? '#mobile-color-options label' : '#color-options label';
                        let options = document.querySelectorAll(selector);
                        options.forEach(opt => {
                            if (opt.textContent.toLowerCase().includes(search.toLowerCase())) {
                                opt.style.display = '';
                            } else {
                                opt.style.display = 'none';
                            }
                        });
                    }

                    // Mobile filter modal logic
                    document.addEventListener('DOMContentLoaded', function() {
                        var openBtn = document.getElementById('openFilterBtn');
                        var closeBtn = document.getElementById('closeFilterBtn');
                        var modal = document.getElementById('mobileFilterModal');
                        var panel = modal ? modal.querySelector('.mobile-filter-content') : null;

                        function openModal() {
                            if (!modal) return;
                            modal.classList.remove('closing');
                            modal.classList.add('active');
                            document.body.style.overflow = 'hidden';
                        }

                        function closeModal() {
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
                                // Fallback
                                modal.classList.remove('active', 'closing');
                                document.body.style.overflow = '';
                            }
                        }

                        if (openBtn && closeBtn && modal) {
                            openBtn.addEventListener('click', openModal);
                            closeBtn.addEventListener('click', closeModal);
                            // Close modal on background click
                            modal.addEventListener('click', function(e) {
                                if (e.target === modal) closeModal();
                            });
                        }
                    });

                    // UPDATED: Simplified mobile pill selection (now radios only for category/brand/color)
                    document.addEventListener('DOMContentLoaded', function() {
                        const mobileContainer = document.querySelector('.mobile-filter-content');
                        if (!mobileContainer) return;

                        // Sync initial selected classes (in case of back navigation)
                        mobileContainer.querySelectorAll('.filter-pill input[type="radio"]').forEach(r => {
                            const l = r.closest('.filter-pill');
                            if (l) l.classList.toggle('selected', r.checked);
                        });

                        mobileContainer.addEventListener('change', function(e) {
                            const input = e.target;
                            if (input.type === 'radio' && input.closest('.filter-pill')) {
                                const name = input.name;
                                mobileContainer.querySelectorAll('input[name="' + name + '"]').forEach(r => {
                                    r.closest('.filter-pill')?.classList.remove('selected');
                                });
                                input.closest('.filter-pill')?.classList.add('selected');
                            }
                        });
                    });
                </script>

                @livewire('footer')
</body>

</html>