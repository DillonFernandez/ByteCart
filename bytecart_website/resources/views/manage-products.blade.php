@php
$user = auth()->user();
if (!$user || !in_array('admin', (array)($user->roles ?? []))) {
\Illuminate\Support\Facades\Auth::guard('web')->logout();
\Illuminate\Support\Facades\Session::invalidate();
\Illuminate\Support\Facades\Session::regenerateToken();
header('Location: ' . route('login'));
exit;
}
@endphp

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>ByteCart - Admin | Manage Products</title>
    <link rel="icon" type="image/x-icon" href="{{ asset('logo/x-icon.webp') }}">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <style>
        /* Pagination styles (aligned with shop/manage-admins/orders) */
        .pager-container {
            display: flex;
            justify-content: center;
            margin: 0;
            padding: 0;
        }

        .pager-wrap {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 0.75rem;
            /* bg/rounded/shadow handled via Tailwind classes on the element */
            padding: 14px 18px;
            width: 100%;
            max-width: none;
            margin: 0;
        }

        .pager {
            display: flex;
            align-items: center;
            gap: 6px;
            flex-wrap: wrap;
            justify-content: center;
        }

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
            box-shadow: 0 2px 8px rgba(59, 130, 246, .3);
        }

        .pager .disabled {
            opacity: .4;
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
            font-size: .875rem;
            flex-shrink: 0;
        }

        @media (max-width: 640px) {
            .pager-wrap {
                flex-direction: column;
                padding: 18px;
            }

            .pager {
                order: 2;
                gap: 4px;
            }

            .pager-info {
                order: 1;
                text-align: center;
                font-size: 0.875rem;
                margin-bottom: 10px;
            }
        }

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
    </style>
</head>

<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Manage Products') }}
        </h2>
    </x-slot>

    <div class="w-full mx-auto pb-5 pt-5 px-4 sm:px-16 sm:pb-10 sm:pt-10">
        @if (session('status'))
        <div id="status-message" class="mb-4 p-3 rounded-[18px] bg-green-50 text-green-700 border border-green-200">
            {{ session('status') }}
        </div>
        @endif
        @if ($errors->any())
        <div id="error-messages" class="mb-4 p-3 rounded-[18px] bg-red-50 text-red-700 border border-red-200">
            <ul class="list-disc ml-6">
                @foreach ($errors->all() as $error)
                <li class="text-sm">{{ $error }}</li>
                @endforeach
            </ul>
        </div>
        @endif

        @php
        // Normalize to a paginator (20 per page) if not already paginated.
        $displayProducts = $products ?? collect();
        if (!($displayProducts instanceof \Illuminate\Pagination\LengthAwarePaginator)) {
        $collection = $displayProducts instanceof \Illuminate\Support\Collection ? $displayProducts : collect($displayProducts);

        // NEW: Filter by availability (in/out/low stock) using per-model stock flags
        $availability = request()->get('availability');
        if (in_array($availability, ['in', 'out', 'low'], true)) {
        $collection = $collection->filter(function ($product) use ($availability) {
        $models = $product->models ?? [];
        $iterable = $models instanceof \Illuminate\Support\Collection || is_array($models)
        ? $models
        : (method_exists($product, 'models') ? $product->models : []);
        $hasAnyOut = false;
        $hasAnyIn = false;
        $hasAnyLow = false;

        $counted = 0;
        foreach ($iterable as $m) {
        $counted++;
        $stock = (int) (is_array($m) ? ($m['stock'] ?? 0) : ($m->stock ?? 0));
        if ($stock <= 0) $hasAnyOut=true;
            if ($stock> 0) $hasAnyIn = true;
            if ($stock > 0 && $stock <= 5) $hasAnyLow=true;
                }
                // If no models at all, consider it "out"
                if ($counted===0) $hasAnyOut=true;

                return match ($availability) { 'out'=> $hasAnyOut,
                'in' => $hasAnyIn,
                'low' => $hasAnyLow,
                default => true,
                };
                })->values();
                }

                $page = max(1, (int) request()->get('page', 1));
                $perPage = 20;
                $total = $collection->count();
                $results = $collection->slice(($page - 1) * $perPage, $perPage)->values();
                $displayProducts = new \Illuminate\Pagination\LengthAwarePaginator(
                $results, $total, $perPage, $page,
                ['path' => request()->url(), 'query' => request()->query()]
                );
                }
                // Pager helpers
                $showingFrom = $displayProducts instanceof \Illuminate\Pagination\LengthAwarePaginator ? ($displayProducts->firstItem() ?? 0) : 0;
                $showingTo = $displayProducts instanceof \Illuminate\Pagination\LengthAwarePaginator ? ($displayProducts->lastItem() ?? 0) : 0;
                $totalItems = $displayProducts instanceof \Illuminate\Pagination\LengthAwarePaginator ? $displayProducts->total() : 0;
                $pageUrl = function(int $page) { return request()->fullUrlWithQuery(['page' => $page]); };

                $pages = [];
                if ($displayProducts instanceof \Illuminate\Pagination\LengthAwarePaginator) {
                $last = $displayProducts->lastPage();
                $current = $displayProducts->currentPage();
                if ($last <= 7) {
                    $pages=range(1, $last);
                    } else {
                    $pages=[1, 2];
                    if ($current> 4) $pages[] = '...';
                    if ($current > 2 && $current < $last - 1) {
                        if ($current> 3) $pages[] = $current - 1;
                        $pages[] = $current;
                        if ($current < $last - 2) $pages[]=$current + 1;
                            } elseif ($current===3) {
                            $pages[]=3;
                            }
                            if ($current < $last - 3) $pages[]='...' ;
                            if (!in_array($last, $pages)) $pages[]=$last;

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

                            <div class="bg-white rounded-[18px] p-6 mb-8" style="box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);">
                            <form method="GET" action="{{ route('manage-products') }}" id="productSearchForm">
                                @csrf
                                <div class="flex items-center justify-between mb-4">
                                    <h3 class="text-lg font-semibold text-gray-900">Filter Products</h3>
                                    <div class="hidden md:flex items-center gap-2">
                                        @php
                                        // NEW: include 'availability' in the active filters check
                                        $filtersActive = request()->has('search') || request()->has('category') || request()->has('brand') || request()->has('new_stock') || request()->has('discounted') || request()->has('availability');
                                        @endphp
                                        <!-- Changed: button -> anchor to guarantee navigation -->
                                        <a href="{{ route('manage-products') }}"
                                            id="clearProductFiltersBtn"
                                            class="inline-flex items-center px-4 py-2 border border-gray-300 text-gray-700 font-medium rounded-[9px] hover:bg-gray-50 transition-colors {{ $filtersActive ? '' : 'opacity-50' }}"
                                            aria-disabled="{{ $filtersActive ? 'false' : 'true' }}">
                                            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                                            </svg>
                                            Reset Filters
                                        </a>
                                        <button type="button" id="addProductBtn" class="inline-flex items-center px-4 py-2 bg-[#0479FF] hover:bg-[#0469DF] text-white font-medium rounded-[9px] transition-colors">
                                            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                                            </svg>
                                            Add Product
                                        </button>
                                    </div>
                                </div>

                                <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                                    <div class="space-y-2">
                                        <!-- Changed: fix label 'for' to match input id -->
                                        <label for="productSearchInput" class="block text-sm font-medium text-gray-700">
                                            Search Products
                                        </label>
                                        <div class="relative">
                                            <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                                                </svg>
                                            </div>
                                            <input
                                                type="text"
                                                name="search"
                                                value="{{ request('search') }}"
                                                class="block w-full pl-10 pr-3 py-2.5 border border-gray-300 rounded-[9px] focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                                                placeholder="Search by product name..."
                                                autocomplete="off"
                                                id="productSearchInput">
                                        </div>
                                        <p class="text-xs text-gray-500">Search by product name</p>
                                    </div>

                                    <div class="space-y-2">
                                        <label for="category" class="block text-sm font-medium text-gray-700">
                                            Category
                                        </label>
                                        <select name="category" id="productCategorySelect" class="block w-full px-3 py-2.5 border border-gray-300 rounded-[9px] focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors">
                                            <option value="">All Categories</option>
                                            @php
                                            $sortedCategories = array_filter(array_unique(($products->pluck('product_category')->toArray() ?? [])));
                                            $selectedCategory = request('category');
                                            if ($selectedCategory && !in_array($selectedCategory, $sortedCategories, true)) {
                                            $sortedCategories[] = $selectedCategory;
                                            }
                                            sort($sortedCategories, SORT_NATURAL | SORT_FLAG_CASE);
                                            @endphp
                                            @foreach($sortedCategories as $cat)
                                            <option value="{{ $cat }}" @if(request('category')==$cat) selected @endif>{{ $cat }}</option>
                                            @endforeach
                                        </select>
                                        <p class="text-xs text-gray-500">Filter by product category</p>
                                    </div>

                                    <div class="space-y-2">
                                        <label for="brand" class="block text-sm font-medium text-gray-700">
                                            Brand
                                        </label>
                                        <select name="brand" id="productBrandSelect" class="block w-full px-3 py-2.5 border border-gray-300 rounded-[9px] focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors">
                                            <option value="">All Brands</option>
                                            @php
                                            $sortedBrands = array_filter(array_unique(($products->pluck('brand_name')->toArray() ?? [])));
                                            $selectedBrand = request('brand');
                                            if ($selectedBrand && !in_array($selectedBrand, $sortedBrands, true)) {
                                            $sortedBrands[] = $selectedBrand;
                                            }
                                            sort($sortedBrands, SORT_NATURAL | SORT_FLAG_CASE);
                                            @endphp
                                            @foreach($sortedBrands as $brand)
                                            <option value="{{ $brand }}" @if(request('brand')==$brand) selected @endif>{{ $brand }}</option>
                                            @endforeach
                                        </select>
                                        <p class="text-xs text-gray-500">Filter by brand name</p>
                                    </div>
                                </div>

                                <!-- CHANGED: add mt-6 for desktop gap between filter rows -->
                                <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mt-0 md:mt-6">
                                    <div class="space-y-2">
                                        <label for="new_stock" class="block text-sm font-medium text-gray-700">
                                            Stock Status
                                        </label>
                                        <select name="new_stock" id="productStockSelect" class="block w-full px-3 py-2.5 border border-gray-300 rounded-[9px] focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors">
                                            <option value="">All Stock</option>
                                            <option value="1" @if(request('new_stock')==='1' ) selected @endif>New Stock Only</option>
                                            <option value="0" @if(request('new_stock')==='0' ) selected @endif>Old Stock Only</option>
                                        </select>
                                        <p class="text-xs text-gray-500">Filter by stock status</p>
                                    </div>

                                    <div class="space-y-2">
                                        <label for="discounted" class="block text-sm font-medium text-gray-700">
                                            Discount Status
                                        </label>
                                        <select name="discounted" id="productDiscountSelect" class="block w-full px-3 py-2.5 border border-gray-300 rounded-[9px] focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors">
                                            <option value="">All Discounts</option>
                                            <option value="1" @if(request('discounted')==='1' ) selected @endif>Discounted Only</option>
                                            <option value="0" @if(request('discounted')==='0' ) selected @endif>No Discount</option>
                                        </select>
                                        <p class="text-xs text-gray-500">Filter by discount status</p>
                                    </div>

                                    <!-- NEW: Availability filter -->
                                    <div class="space-y-2">
                                        <label for="availability" class="block text-sm font-medium text-gray-700">
                                            Availability
                                        </label>
                                        <select name="availability" id="productAvailabilitySelect" class="block w-full px-3 py-2.5 border border-gray-300 rounded-[9px] focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors">
                                            <option value="">All Availability</option>
                                            <option value="in" @if(request('availability')==='in' ) selected @endif>In Stock</option>
                                            <option value="out" @if(request('availability')==='out' ) selected @endif>Out of Stock</option>
                                            <option value="low" @if(request('availability')==='low' ) selected @endif>Low Stock</option>
                                        </select>
                                        <p class="text-xs text-gray-500">Filter by model availability (any model)</p>
                                    </div>
                                </div>

                                <!-- Mobile buttons -->
                                <div class="md:hidden flex gap-3">
                                    <!-- Changed: button -> anchor -->
                                    <a href="{{ route('manage-products') }}"
                                        id="clearProductFiltersBtnMobile"
                                        class="flex-1 inline-flex items-center justify-center px-4 py-2.5 border border-gray-300 text-gray-700 font-medium rounded-[9px] hover:bg-gray-50 transition-colors {{ $filtersActive ? '' : 'opacity-50' }}"
                                        aria-disabled="{{ $filtersActive ? 'false' : 'true' }}">
                                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                                        </svg>
                                        Reset
                                    </a>
                                    <button type="button" id="addProductBtnMobile" class="flex-1 inline-flex items-center justify-center px-4 py-2.5 bg-[#0479FF] hover:bg-[#0469DF] text-white font-medium rounded-[9px] transition-colors">
                                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                                        </svg>
                                        Add Product
                                    </button>
                                </div>
                            </form>
    </div>

    <!-- Desktop Table View (hidden on mobile) -->
    <div class="hidden lg:block bg-white rounded-[18px] overflow-hidden" style="box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);">
        <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr class="text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        <th class="px-6 py-4">Product</th>
                        <th class="px-6 py-4">Category</th>
                        <th class="px-6 py-4">Stock</th>
                        <th class="px-6 py-4">Models</th>
                        <th class="px-6 py-4">Actions</th>
                    </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-100">
                    @forelse($displayProducts as $product)
                    <tr id="product-row-{{ $product->id }}" class="hover:bg-gray-50">
                        <td class="px-6 py-4">
                            <div class="flex items-center">
                                <div class="w-16 h-16 bg-gray-100 rounded-[9px] flex items-center justify-center overflow-hidden">
                                    @if(!empty($product->image))
                                    <img src="{{ asset($product->image) }}" alt="Product Image" class="max-w-full max-h-full object-contain">
                                    @else
                                    <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                                    </svg>
                                    @endif
                                </div>
                                <div class="ml-4">
                                    <div class="font-semibold text-gray-900">{{ $product->product_name }}</div>
                                    <div class="text-gray-500 text-sm">{{ $product->brand_name }}</div>
                                    @if($product->discount > 0)
                                    <div class="text-orange-600 text-sm font-medium">{{ $product->discount }}% OFF</div>
                                    @endif
                                </div>
                            </div>
                        </td>
                        <td class="px-6 py-4">
                            <span class="inline-flex px-2 py-1 rounded-full text-xs font-semibold bg-purple-100 text-purple-700">
                                {{ $product->product_category }}
                            </span>
                        </td>
                        <td class="px-6 py-4">
                            @if($product->new_stock)
                            <span class="inline-flex px-2 py-1 rounded-full text-xs font-semibold bg-green-100 text-green-700">New Stock</span>
                            @else
                            <span class="inline-flex px-2 py-1 rounded-full text-xs font-semibold bg-gray-100 text-gray-700">Old Stock</span>
                            @endif
                        </td>
                        <td class="px-6 py-4 text-gray-700 text-sm">
                            {{ count($product->models) }} {{ count($product->models) === 1 ? 'model' : 'models' }}
                        </td>
                        <td class="px-6 py-4">
                            <div class="flex items-center gap-2">
                                <button class="edit-product-btn inline-flex items-center px-3 py-2 border border-gray-300 rounded-[9px] bg-white hover:bg-gray-50 text-sm font-medium"
                                    data-id="{{ $product->id }}"
                                    data-product='@json($product)'>
                                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                                    </svg>
                                    Edit
                                </button>
                                <button class="delete-product-btn inline-flex items-center px-3 py-2 border border-red-300 rounded-[9px] bg-white hover:bg-red-50 text-sm font-medium text-red-600"
                                    data-id="{{ $product->id }}">
                                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                                    </svg>
                                    Delete
                                </button>
                            </div>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="5" class="px-6 py-12 text-center">
                            <div class="text-gray-500">
                                <div class="text-lg font-medium mb-2">No products found</div>
                                <p class="text-sm">Try adjusting your filters or search terms</p>
                                <a href="{{ route('manage-products') }}" class="text-blue-600 hover:text-blue-700 underline">Reset filters</a>
                            </div>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    {{-- Pagination (desktop only) --}}
    @if($displayProducts instanceof \Illuminate\Pagination\LengthAwarePaginator && $displayProducts->lastPage() > 1)
    <div class="hidden lg:block">
        <div class="pager-container mt-6">
            <div class="pager-wrap w-full bg-white shadow-[0_4px_24px_0_rgba(30,41,59,0.13)] rounded-[18px] overflow-hidden">
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
    </div>
    @endif

    <!-- Mobile Card View (visible on mobile) -->
    <div class="lg:hidden space-y-4">
        @forelse($displayProducts as $product)
        <div id="product-card-{{ $product->id }}" class="bg-white rounded-[18px]" style="box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);">
            <div class="p-4">
                <div class="flex items-start justify-between mb-3">
                    <div class="flex items-center">
                        <div class="w-16 h-16 bg-gray-100 rounded-[9px] flex items-center justify-center overflow-hidden">
                            @if(!empty($product->image))
                            <img src="{{ asset($product->image) }}" alt="Product Image" class="max-w-full max-h-full object-contain">
                            @else
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                            </svg>
                            @endif
                        </div>
                        <div class="ml-3">
                            <div class="font-semibold text-gray-900">{{ $product->product_name }}</div>
                            <div class="text-sm text-gray-500">{{ $product->brand_name }}</div>
                            @if($product->discount > 0)
                            <div class="text-orange-600 text-sm font-medium">{{ $product->discount }}% OFF</div>
                            @endif
                        </div>
                    </div>
                    <div class="flex flex-col gap-1">
                        <span class="inline-flex px-2 py-1 rounded-full text-xs font-semibold bg-purple-100 text-purple-700">
                            {{ $product->product_category }}
                        </span>
                        @if($product->new_stock)
                        <span class="inline-flex px-2 py-1 rounded-full text-xs font-semibold bg-green-100 text-green-700">New</span>
                        @else
                        <span class="inline-flex px-2 py-1 rounded-full text-xs font-semibold bg-gray-100 text-gray-700">Old</span>
                        @endif
                    </div>
                </div>

                <div class="mb-4 text-sm">
                    @if(count($product->models) > 0)
                    <div class="text-gray-600 mb-2">{{ count($product->models) }} {{ count($product->models) === 1 ? 'model' : 'models' }} available</div>
                    <div class="space-y-2 max-h-32 overflow-y-auto">
                        @foreach($product->models as $model)
                        <div class="bg-gray-50 rounded-[9px] p-2 text-xs">
                            <div class="font-medium">{{ $model->model_name }}</div>
                            <div class="text-gray-600">Price: ${{ $model->price }} • Stock: {{ $model->stock }}</div>
                            @if($model->colors)
                            <div class="text-gray-500">Colors: {{ $model->colors }}</div>
                            @endif
                        </div>
                        @endforeach
                    </div>
                    @else
                    <div class="text-gray-400 text-center py-2">No models available</div>
                    @endif
                </div>

                <div class="flex gap-2">
                    <button class="edit-product-btn flex-1 inline-flex items-center justify-center px-3 py-2 border border-gray-300 rounded-[9px] bg-white hover:bg-gray-50 text-sm font-medium"
                        data-id="{{ $product->id }}"
                        data-product='@json($product)'>
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                        </svg>
                        Edit
                    </button>
                    <button class="delete-product-btn flex-1 inline-flex items-center justify-center px-3 py-2 border border-red-300 rounded-[9px] bg-white hover:bg-red-50 text-sm font-medium text-red-600"
                        data-id="{{ $product->id }}">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                        </svg>
                        Delete
                    </button>
                </div>
            </div>
        </div>
        @empty
        <div class="bg-white rounded-[18px] p-8 text-center" style="box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 mx-auto mb-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
            </svg>
            <div class="text-lg font-medium text-gray-900 mb-2">No products found</div>
            <div class="text-gray-500 mb-4">Try adjusting your filters or search terms</div>
            <a href="{{ route('manage-products') }}" class="text-blue-600 hover:text-blue-700 underline">Reset filters</a>
        </div>
        @endforelse
    </div>

    {{-- Pagination (mobile only) --}}
    @if($displayProducts instanceof \Illuminate\Pagination\LengthAwarePaginator && $displayProducts->lastPage() > 1)
    <div class="pager-container mt-6 lg:hidden">
        <div class="pager-wrap w-full bg-white shadow-[0_4px_24px_0_rgba(30,41,59,0.13)] rounded-[18px] overflow-hidden">
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

    <!-- Add Product Modal -->
    <div id="addProductModal" class="fixed inset-0 z-50 bg-black bg-opacity-50 hidden">
        <div class="flex items-center justify-center min-h-screen p-4">
            <div class="bg-white rounded-[18px] shadow-2xl w-full max-w-4xl max-h-[90vh] overflow-hidden">
                <!-- Modal Header -->
                <div class="bg-gradient-to-r from-blue-600 to-blue-700 px-6 py-4 flex items-center justify-between">
                    <div class="flex items-center gap-3">
                        <div class="w-8 h-8 bg-white bg-opacity-20 rounded-[9px] flex items-center justify-center">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                            </svg>
                        </div>
                        <h3 class="text-xl font-semibold text-white">Add New Product</h3>
                    </div>
                    <button id="closeAddProductModal" class="text-white hover:text-gray-200 transition-colors">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    </button>
                </div>

                <!-- Modal Body -->
                <div class="p-6 overflow-y-auto max-h-[calc(90vh-140px)]">
                    <form id="addProductForm" class="space-y-6" autocomplete="off" enctype="multipart/form-data">
                        <!-- Basic Information Section -->
                        <div class="bg-gray-50 rounded-[9px] p-4">
                            <h4 class="text-lg font-medium text-gray-900 mb-4 flex items-center gap-2">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                                </svg>
                                Basic Information
                            </h4>
                            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                                <div class="space-y-2">
                                    <label for="addProductName" class="block text-sm font-medium text-gray-700">Product Name *</label>
                                    <input name="product_name" id="addProductName" placeholder="e.g. iPhone 15 Pro" required
                                        class="w-full px-3 py-2.5 border border-gray-300 rounded-[9px] focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors" />
                                </div>
                                <div class="space-y-2">
                                    <label for="addBrandName" class="block text-sm font-medium text-gray-700">Brand Name *</label>
                                    <input name="brand_name" id="addBrandName" placeholder="e.g. Apple" required
                                        class="w-full px-3 py-2.5 border border-gray-300 rounded-[9px] focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors" />
                                </div>
                                <div class="space-y-2">
                                    <label for="addProductCategory" class="block text-sm font-medium text-gray-700">Category *</label>
                                    <input name="product_category" id="addProductCategory" placeholder="e.g. Smartphones" required
                                        class="w-full px-3 py-2.5 border border-gray-300 rounded-[9px] focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors" />
                                </div>
                                <div class="space-y-2">
                                    <label for="addDiscount" class="block text-sm font-medium text-gray-700">Discount (%)</label>
                                    <input name="discount" id="addDiscount" type="number" step="0.01" min="0" max="100" placeholder="e.g. 10.5"
                                        class="w-full px-3 py-2.5 border border-gray-300 rounded-[9px] focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors" />
                                </div>
                            </div>

                            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
                                <div class="space-y-2">
                                    <label for="addDescription" class="block text-sm font-medium text-gray-700">Description</label>
                                    <textarea name="description" id="addDescription" rows="3" placeholder="Product description..."
                                        class="w-full px-3 py-2.5 border border-gray-300 rounded-[9px] focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors resize-none"></textarea>
                                </div>
                                <div class="space-y-2">
                                    <label for="addSpecification" class="block text-sm font-medium text-gray-700">Specifications</label>
                                    <textarea name="specification" id="addSpecification" rows="3" placeholder="Technical specifications..."
                                        class="w-full px-3 py-2.5 border border-gray-300 rounded-[9px] focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors resize-none"></textarea>
                                </div>
                            </div>

                            <div class="mt-4">
                                <div class="flex items-center gap-3">
                                    <input type="checkbox" name="new_stock" id="addNewStock" value="1" class="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500" />
                                    <label for="addNewStock" class="text-sm font-medium text-gray-700">Mark as New Stock</label>
                                </div>
                            </div>
                        </div>

                        <!-- Image Upload Section -->
                        <div class="bg-gray-50 rounded-[9px] p-4">
                            <h4 class="text-lg font-medium text-gray-900 mb-4 flex items-center gap-2">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                                </svg>
                                Product Image
                            </h4>
                            <div class="space-y-2">
                                <label class="block text-sm font-medium text-gray-700">Upload Image (.webp required) *</label>
                                <input type="file" name="image" accept=".webp" required
                                    class="w-full px-3 py-2.5 border border-gray-300 rounded-[9px] focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors file:mr-4 file:py-2 file:px-4 file:rounded-[9px] file:border-0 file:text-sm file:font-medium file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100" />
                                <p class="text-xs text-gray-500">Please upload a .webp image for optimal performance</p>
                            </div>
                        </div>

                        <!-- Models Section -->
                        <div class="bg-gray-50 rounded-[9px] p-4">
                            <div class="flex items-center justify-between mb-4">
                                <h4 class="text-lg font-medium text-gray-900 flex items-center gap-2">
                                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
                                    </svg>
                                    Product Models
                                </h4>
                                <button type="button" onclick="addModelToModal('addModelsContainer')"
                                    class="inline-flex items-center px-3 py-2 bg-blue-600 text-white text-sm font-medium rounded-[9px] hover:bg-blue-700 transition-colors">
                                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                                    </svg>
                                    Add Model
                                </button>
                            </div>
                            <div id="addModelsContainer" class="space-y-4">
                                <!-- Models will be added here dynamically -->
                            </div>
                            <div id="addModelsEmpty" class="text-center py-8 text-gray-500">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 mx-auto mb-2 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
                                </svg>
                                <p>No models added yet. Click "Add Model" to create product variants.</p>
                            </div>
                        </div>

                        <!-- Error Display -->
                        <div id="addProductGeneralError" class="hidden bg-red-50 border border-red-200 rounded-[9px] p-3">
                            <div class="flex items-center gap-2">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                                </svg>
                                <span class="text-red-700 text-sm font-medium">Error</span>
                            </div>
                            <p class="text-red-600 text-sm mt-1" id="addProductErrorText"></p>
                        </div>
                    </form>
                </div>

                <!-- Modal Footer -->
                <div class="bg-gray-50 px-6 py-4 flex items-center justify-end gap-3 border-t border-gray-200">
                    <button type="button" id="cancelAddProduct" class="px-4 py-2 text-gray-700 bg-white border border-gray-300 rounded-[9px] hover:bg-gray-50 transition-colors">
                        Cancel
                    </button>
                    <button type="submit" form="addProductForm" class="px-6 py-2 bg-blue-600 text-white rounded-[9px] hover:bg-blue-700 transition-colors flex items-center gap-2">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                        </svg>
                        Add Product
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- Edit Product Modal -->
    <div id="editProductModal" class="fixed inset-0 z-50 bg-black bg-opacity-50 hidden">
        <div class="flex items-center justify-center min-h-screen p-4">
            <div class="bg-white rounded-[18px] shadow-2xl w-full max-w-4xl max-h-[90vh] overflow-hidden">
                <!-- Modal Header -->
                <div class="bg-gradient-to-r from-orange-600 to-orange-700 px-6 py-4 flex items-center justify-between">
                    <div class="flex items-center gap-3">
                        <div class="w-8 h-8 bg-white bg-opacity-20 rounded-[9px] flex items-center justify-center">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                            </svg>
                        </div>
                        <h3 class="text-xl font-semibold text-white">Edit Product</h3>
                    </div>
                    <button id="closeEditProductModal" class="text-white hover:text-gray-200 transition-colors">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    </button>
                </div>

                <!-- Modal Body -->
                <div class="p-6 overflow-y-auto max-h-[calc(90vh-140px)]">
                    <form id="editProductForm" class="space-y-6" autocomplete="off" enctype="multipart/form-data">
                        <input type="hidden" name="product_id" id="editProductId" />

                        <!-- Basic Information Section -->
                        <div class="bg-gray-50 rounded-[9px] p-4">
                            <h4 class="text-lg font-medium text-gray-900 mb-4 flex items-center gap-2">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-orange-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                                </svg>
                                Basic Information
                            </h4>
                            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                                <div class="space-y-2">
                                    <label for="editProductName" class="block text-sm font-medium text-gray-700">Product Name *</label>
                                    <input name="product_name" id="editProductName" required
                                        class="w-full px-3 py-2.5 border border-gray-300 rounded-[9px] focus:ring-2 focus:ring-orange-500 focus:border-orange-500 transition-colors" />
                                </div>
                                <div class="space-y-2">
                                    <label for="editBrandName" class="block text-sm font-medium text-gray-700">Brand Name *</label>
                                    <input name="brand_name" id="editBrandName" required
                                        class="w-full px-3 py-2.5 border border-gray-300 rounded-[9px] focus:ring-2 focus:ring-orange-500 focus:border-orange-500 transition-colors" />
                                </div>
                                <div class="space-y-2">
                                    <label for="editProductCategory" class="block text-sm font-medium text-gray-700">Category *</label>
                                    <input name="product_category" id="editProductCategory" required
                                        class="w-full px-3 py-2.5 border border-gray-300 rounded-[9px] focus:ring-2 focus:ring-orange-500 focus:border-orange-500 transition-colors" />
                                </div>
                                <div class="space-y-2">
                                    <label for="editDiscount" class="block text-sm font-medium text-gray-700">Discount (%)</label>
                                    <input name="discount" id="editDiscount" type="number" step="0.01" min="0" max="100"
                                        class="w-full px-3 py-2.5 border border-gray-300 rounded-[9px] focus:ring-2 focus:ring-orange-500 focus:border-orange-500 transition-colors" />
                                </div>
                            </div>

                            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
                                <div class="space-y-2">
                                    <label for="editDescription" class="block text-sm font-medium text-gray-700">Description</label>
                                    <textarea name="description" id="editDescription" rows="3"
                                        class="w-full px-3 py-2.5 border border-gray-300 rounded-[9px] focus:ring-2 focus:ring-orange-500 focus:border-orange-500 transition-colors resize-none"></textarea>
                                </div>
                                <div class="space-y-2">
                                    <label for="editSpecification" class="block text-sm font-medium text-gray-700">Specifications</label>
                                    <textarea name="specification" id="editSpecification" rows="3"
                                        class="w-full px-3 py-2.5 border border-gray-300 rounded-[9px] focus:ring-2 focus:ring-orange-500 focus:border-orange-500 transition-colors resize-none"></textarea>
                                </div>
                            </div>

                            <div class="mt-4">
                                <div class="flex items-center gap-3">
                                    <input type="checkbox" name="new_stock" id="editNewStock" value="1" class="w-4 h-4 text-orange-600 border-gray-300 rounded focus:ring-orange-500" />
                                    <label for="editNewStock" class="text-sm font-medium text-gray-700">Mark as New Stock</label>
                                </div>
                            </div>
                        </div>

                        <!-- Image Upload Section -->
                        <div class="bg-gray-50 rounded-[9px] p-4">
                            <h4 class="text-lg font-medium text-gray-900 mb-4 flex items-center gap-2">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-orange-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                                </svg>
                                Product Image
                            </h4>
                            <div class="space-y-3">
                                <div class="space-y-2">
                                    <label class="block text-sm font-medium text-gray-700">Upload New Image (.webp required)</label>
                                    <input type="file" name="image" accept=".webp"
                                        class="w-full px-3 py-2.5 border border-gray-300 rounded-[9px] focus:ring-2 focus:ring-orange-500 focus:border-orange-500 transition-colors file:mr-4 file:py-2 file:px-4 file:rounded-[9px] file:border-0 file:text-sm file:font-medium file:bg-orange-50 file:text-orange-700 hover:file:bg-orange-100" />
                                    <p class="text-xs text-gray-500">Leave empty to keep current image</p>
                                </div>
                                <div id="editCurrentImageContainer" class="hidden">
                                    <label class="block text-sm font-medium text-gray-700 mb-2">Current Image</label>
                                    <div class="w-24 h-24 bg-gray-100 rounded-[9px] flex items-center justify-center overflow-hidden border">
                                        <img id="editProductImagePreview" src="" alt="Current Image" class="max-w-full max-h-full object-contain" />
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Models Section -->
                        <div class="bg-gray-50 rounded-[9px] p-4">
                            <div class="flex items-center justify-between mb-4">
                                <h4 class="text-lg font-medium text-gray-900 flex items-center gap-2">
                                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-orange-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
                                    </svg>
                                    Product Models
                                </h4>
                                <button type="button" onclick="addModelToModal('editModelsContainer')"
                                    class="inline-flex items-center px-3 py-2 bg-orange-600 text-white text-sm font-medium rounded-[9px] hover:bg-orange-700 transition-colors">
                                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                                    </svg>
                                    Add Model
                                </button>
                            </div>
                            <div id="editModelsContainer" class="space-y-4">
                                <!-- Models will be added here dynamically -->
                            </div>
                            <div id="editModelsEmpty" class="text-center py-8 text-gray-500 hidden">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 mx-auto mb-2 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
                                </svg>
                                <p>No models added yet. Click "Add Model" to create product variants.</p>
                            </div>
                        </div>

                        <!-- Error Display -->
                        <div id="editProductGeneralError" class="hidden bg-red-50 border border-red-200 rounded-[9px] p-3">
                            <div class="flex items-center gap-2">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                                </svg>
                                <span class="text-red-700 text-sm font-medium">Error</span>
                            </div>
                            <p class="text-red-600 text-sm mt-1" id="editProductErrorText"></p>
                        </div>
                    </form>
                </div>

                <!-- Modal Footer -->
                <div class="bg-gray-50 px-6 py-4 flex items-center justify-end gap-3 border-t border-gray-200">
                    <button type="button" id="cancelEditProduct" class="px-4 py-2 text-gray-700 bg-white border border-gray-300 rounded-[9px] hover:bg-gray-50 transition-colors">
                        Cancel
                    </button>
                    <button type="submit" form="editProductForm" class="px-6 py-2 bg-orange-600 text-white rounded-[9px] hover:bg-orange-700 transition-colors flex items-center gap-2">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                        </svg>
                        Save Changes
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- Success Popup Modal -->
    <div id="productSuccessPopup" class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-40 hidden px-4">
        <div class="bg-white rounded-[18px] shadow-lg p-6 w-full max-w-sm relative mx-2 flex flex-col items-center">
            <button id="closeProductSuccessPopup" class="absolute top-2 right-2 text-gray-400 hover:text-gray-600 text-xl">&times;</button>
            <h3 class="text-lg font-semibold mb-4 text-green-600">Success</h3>
            <span id="productSuccessPopupMsg" class="text-gray-700 text-center"></span>
        </div>
    </div>

    <!-- Delete Confirmation Modal -->
    <div id="deleteProductConfirmModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-40 hidden px-4">
        <div class="bg-white rounded-[18px] shadow-lg p-6 w-full max-w-sm relative mx-2">
            <button id="closeDeleteProductConfirmModal" class="absolute top-2 right-2 text-gray-400 hover:text-gray-600 text-xl">&times;</button>
            <h3 class="text-lg font-semibold mb-4 text-red-600">Delete Product</h3>
            <p class="mb-6 text-gray-700" id="deleteProductConfirmText">Are you sure you want to delete this product?</p>
            <div class="flex flex-col sm:flex-row justify-end gap-2">
                <button id="cancelDeleteProductBtn" class="px-4 py-2 bg-gray-200 text-gray-700 rounded-[9px] hover:bg-gray-300 transition w-full sm:w-auto">Cancel</button>
                <button id="confirmDeleteProductBtn" class="px-4 py-2 bg-red-500 text-white rounded-[9px] hover:bg-red-600 transition w-full sm:w-auto">Delete</button>
            </div>
        </div>
    </div>

    <script>
        // Utility for showing success popup
        function showProductSuccessPopup(message) {
            document.getElementById('productSuccessPopupMsg').textContent = message;
            document.getElementById('productSuccessPopup').classList.remove('hidden');
        }
        document.getElementById('closeProductSuccessPopup').onclick = function() {
            document.getElementById('productSuccessPopup').classList.add('hidden');
        };

        // Add Product Modal handlers
        function openAddProductModal() {
            document.getElementById('addProductModal').classList.remove('hidden');
            document.getElementById('addProductForm').reset();
            document.getElementById('addModelsContainer').innerHTML = '';
            document.getElementById('addProductGeneralError').classList.add('hidden');
            window.addModelModalIndex = 0;
            document.getElementById('addNewStock').checked = false; // Reset checkbox
        }

        document.getElementById('addProductBtn').onclick = openAddProductModal;
        document.getElementById('addProductBtnMobile').onclick = openAddProductModal;

        document.getElementById('closeAddProductModal').onclick = function() {
            document.getElementById('addProductModal').classList.add('hidden');
        };

        document.getElementById('cancelAddProduct').onclick = function() {
            document.getElementById('addProductModal').classList.add('hidden');
        };

        // Edit Product Modal logic
        document.querySelectorAll('.edit-product-btn').forEach(btn => {
            btn.onclick = function() {
                let product;
                try {
                    product = JSON.parse(this.getAttribute('data-product'));
                } catch (e) {
                    product = {};
                }
                // Debug: log product to console
                console.log('Edit product:', product);

                document.getElementById('editProductModal').classList.remove('hidden');
                document.getElementById('editProductForm').reset();
                // Fix: support both _id and id
                document.getElementById('editProductId').value = product.id || '';
                document.getElementById('editProductName').value = product.product_name || '';
                document.getElementById('editBrandName').value = product.brand_name || '';
                document.getElementById('editProductCategory').value = product.product_category || '';
                // Preserve 0 discount instead of empty
                document.getElementById('editDiscount').value = (product.discount ?? '');
                document.getElementById('editDescription').value = product.description || '';
                document.getElementById('editSpecification').value = product.specification || '';
                // New Stock checkbox
                document.getElementById('editNewStock').checked = !!product.new_stock;
                // Image preview
                let imgPreview = document.getElementById('editProductImagePreview');
                let imgContainer = document.getElementById('editCurrentImageContainer');
                if (product.image) {
                    imgPreview.src = "{{ asset('') }}" + product.image;
                    imgContainer.classList.remove('hidden');
                } else {
                    imgContainer.classList.add('hidden');
                }
                // Models
                let models = Array.isArray(product.models) ? product.models : [];
                let container = document.getElementById('editModelsContainer');
                container.innerHTML = '';
                window.editModelModalIndex = 0;
                models.forEach((model, idx) => {
                    addModelToModal('editModelsContainer', model, idx);
                    window.editModelModalIndex = idx + 1;
                });
                document.getElementById('editProductGeneralError').classList.add('hidden');
            };
        });
        document.getElementById('closeEditProductModal').onclick = function() {
            document.getElementById('editProductModal').classList.add('hidden');
        };

        document.getElementById('cancelEditProduct').onclick = function() {
            document.getElementById('editProductModal').classList.add('hidden');
        };

        // Add/Edit Model logic for modals
        function addModelToModal(containerId, model = null, idx = null) {
            if (containerId !== 'addModelsContainer' && containerId !== 'editModelsContainer') return;
            let emptyId = containerId === 'addModelsContainer' ? 'addModelsEmpty' : 'editModelsEmpty';
            document.getElementById(emptyId)?.classList.add('hidden');

            let index = idx !== null ? idx : (containerId === 'addModelsContainer' ?
                (window.addModelModalIndex || 0) :
                (window.editModelModalIndex || 0));



            const m = model || {};
            const val = (x) => (x === undefined || x === null ? '' : x);

            let container = document.getElementById(containerId);
            let div = document.createElement('div');
            div.className = "bg-white border border-gray-300 rounded-[9px] p-4 flex flex-col gap-3 relative mb-3";
            div.innerHTML = `
                <button type="button" class="remove-model-btn absolute top-2 right-2 text-red-500 hover:text-red-700 transition" title="Remove Model">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                </button>
                <!-- keep model id when editing so backend updates instead of recreating -->
                <input type="hidden" name="models[${index}][id]" value="${val(m.id)}" />
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                        <label class="font-medium text-sm mb-1">Model Name</label>
                        <input name="models[${index}][model_name]" value="${val(m.model_name)}" required placeholder="Model Name" class="border p-2 rounded-[9px] focus:outline-none focus:border-[#0479FF] w-full"/>
                    </div>
                    <div>
                        <label class="font-medium text-sm mb-1">Price</label>
                        <input name="models[${index}][price]" type="number" step="0.01" value="${val(m.price)}" required placeholder="Price" class="border p-2 rounded-[9px] focus:outline-none focus:border-[#0479FF] w-full"/>
                    </div>
                    <div>
                        <label class="font-medium text-sm mb-1">Stock</label>
                        <input name="models[${index}][stock]" type="number" value="${val(m.stock)}" required placeholder="Stock" class="border p-2 rounded-[9px] focus:outline-none focus:border-[#0479FF] w-full"/>
                    </div>
                    <div>
                        <label class="font-medium text-sm mb-1">Colors</label>
                        <input name="models[${index}][colors]" value="${val(m.colors)}" placeholder="e.g. Black, Silver" class="border p-2 rounded-[9px] focus:outline-none focus:border-[#0479FF] w-full"/>
                    </div>
                </div>
            `;
            container.appendChild(div);

            // Removal handler (re-evaluate empty state)
            div.querySelector('.remove-model-btn').addEventListener('click', function() {
                div.remove();
                if (!container.querySelector('.remove-model-btn')) {
                    document.getElementById(emptyId)?.classList.remove('hidden');
                }
            });

            if (containerId === 'addModelsContainer') {
                window.addModelModalIndex = index + 1;
            } else {
                window.editModelModalIndex = index + 1;
            }
        }

        // FIX: document.getElement -> getElementById
        const addProductForm = document.getElementById('addProductForm');
        if (addProductForm) {
            addProductForm.onsubmit = function(e) {
                e.preventDefault();
                const form = e.target;
                const formData = new FormData(form);
                formData.set('new_stock', document.getElementById('addNewStock').checked ? '1' : '0');
                document.getElementById('addProductGeneralError').classList.add('hidden');

                fetch(`{{ route('manage-products.store') }}`, {
                    method: 'POST',
                    headers: {
                        'X-CSRF-TOKEN': '{{ csrf_token() }}',
                        'Accept': 'application/json'
                    },
                    body: formData
                }).then(async res => {
                    const json = await res.json().catch(() => ({}));
                    if (res.ok && json.success) {
                        document.getElementById('addProductModal').classList.add('hidden');
                        showProductSuccessPopup('Product added successfully!');
                        setTimeout(() => window.location.reload(), 900);
                    } else if (res.status === 422) {
                        const errors = json.errors || {};
                        const msg = Object.values(errors).map(a => a.join(' ')).join(' ');
                        document.getElementById('addProductErrorText').textContent = msg || 'Validation failed.';
                        document.getElementById('addProductGeneralError').classList.remove('hidden');
                    } else {
                        document.getElementById('addProductErrorText').textContent = json.error || 'Add failed.';
                        document.getElementById('addProductGeneralError').classList.remove('hidden');
                    }
                }).catch(() => {
                    document.getElementById('addProductErrorText').textContent = 'Network error.';
                    document.getElementById('addProductGeneralError').classList.remove('hidden');
                });
            }

            // Edit Product AJAX submit
            document.getElementById('editProductForm').onsubmit = function(e) {
                e.preventDefault();
                let form = e.target;
                let formData = new FormData(form);
                formData.append('_method', 'PATCH');
                // Ensure new_stock is set correctly
                formData.set('new_stock', document.getElementById('editNewStock').checked ? '1' : '');
                document.getElementById('editProductGeneralError').classList.add('hidden');
                let productId = document.getElementById('editProductId').value;
                if (!productId) {
                    document.getElementById('editProductErrorText').textContent = 'Product ID missing. Cannot update.';
                    document.getElementById('editProductGeneralError').classList.remove('hidden');
                    return;
                }
                fetch(`{{ url('manage-products') }}/${productId}`, {
                        method: 'POST',
                        headers: {
                            'X-CSRF-TOKEN': '{{ csrf_token() }}',
                            'Accept': 'application/json'
                        },
                        body: formData
                    })
                    .then(async res => {
                        if (res.ok) {
                            document.getElementById('editProductModal').classList.add('hidden');
                            showProductSuccessPopup('Product updated successfully!');
                            setTimeout(() => window.location.reload(), 1200);
                        } else if (res.status === 422) {
                            let errorData = await res.json();
                            let errors = errorData.errors || {};
                            let errorText = Object.values(errors).map(e => e.join(' ')).join(' ');
                            document.getElementById('editProductErrorText').textContent = errorText;
                            document.getElementById('editProductGeneralError').classList.remove('hidden');
                        } else {
                            document.getElementById('editProductErrorText').textContent = 'Update failed.';
                            document.getElementById('editProductGeneralError').classList.remove('hidden');
                        }
                    })
                    .catch(() => {
                        document.getElementById('editProductErrorText').textContent = 'Update failed.';
                        document.getElementById('editProductGeneralError').classList.remove('hidden');
                    });
            };

            // Delete Product Modal logic
            let deleteProductId = null;
            document.querySelectorAll('.delete-product-btn').forEach(btn => {
                btn.onclick = function() {
                    deleteProductId = this.dataset.id;
                    document.getElementById('deleteProductConfirmModal').classList.remove('hidden');
                };
            });
            document.getElementById('closeDeleteProductConfirmModal').onclick = function() {
                document.getElementById('deleteProductConfirmModal').classList.add('hidden');
                deleteProductId = null;
            };
            document.getElementById('cancelDeleteProductBtn').onclick = function() {
                document.getElementById('deleteProductConfirmModal').classList.add('hidden');
                deleteProductId = null;
            };
            document.getElementById('confirmDeleteProductBtn').onclick = function() {
                if (!deleteProductId) return;
                fetch(`{{ url('manage-products') }}/${deleteProductId}`, {
                        method: 'DELETE',
                        headers: {
                            'X-CSRF-TOKEN': '{{ csrf_token() }}',
                            'Accept': 'application/json'
                        }
                    })
                    .then(async res => {
                        if (res.ok) {
                            document.getElementById('product-row-' + deleteProductId).remove();
                            let card = document.getElementById('product-card-' + deleteProductId);
                            if (card) card.remove();
                            document.getElementById('deleteProductConfirmModal').classList.add('hidden');
                            showProductSuccessPopup('Product deleted successfully!');
                            setTimeout(() => window.location.reload(), 1200);
                        } else {
                            document.getElementById('deleteProductConfirmModal').classList.add('hidden');
                            alert('Delete failed.');
                        }
                        deleteProductId = null;
                    })
                    .catch(() => {
                        document.getElementById('deleteProductConfirmModal').classList.add('hidden');
                        alert('Delete failed.');
                        deleteProductId = null;
                    });
            };

            // Single auto-submit for selects (preserves current values in the form)
            ['productCategorySelect', 'productBrandSelect', 'productStockSelect', 'productDiscountSelect', 'productAvailabilitySelect']
            .forEach(function(id) {
                const el = document.getElementById(id);
                if (el) el.addEventListener('change', function() {
                    document.getElementById('productSearchForm').submit();
                });
            });

            // Submit search on Enter only
            document.getElementById('productSearchInput')?.addEventListener('keydown', function(e) {
                if (e.key === 'Enter') document.getElementById('productSearchForm').submit();
            });

            // Auto-hide status and error messages
            document.addEventListener('DOMContentLoaded', function() {
                const statusBox = document.getElementById('status-message');
                const errorBox = document.getElementById('error-messages');
                [statusBox, errorBox].forEach(function(box) {
                    if (box) {
                        setTimeout(function() {
                            box.style.transition = 'opacity 0.5s ease-out';
                            box.style.opacity = '0';
                            setTimeout(function() {
                                box.style.display = 'none';
                            }, 500);
                        }, 5000);
                    }
                });
            });
        } // <-- Add this closing curly brace to close the 'if (addProductForm)' block
    </script>
</x-app-layout>