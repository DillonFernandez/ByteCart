@php
$user = auth()->user();
if (!$user || ($user->roles ?? '') !== 'admin') {
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
    <title>ByteCart - Admin | Manage Admins</title>
    <link rel="icon" type="image/x-icon" href="{{ asset('logo/x-icon.webp') }}">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <style>
        /* Pagination styles (aligned with shop.blade.php) */
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
            /* bg/rounded/shadow removed to inherit Tailwind classes */
            /* background: #fff; */
            /* border-radius: 24px; */
            /* box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13); */
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
            {{ __('Manage Admins') }}
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
        $displayAdmins = $admins ?? collect();
        if (!($displayAdmins instanceof \Illuminate\Pagination\LengthAwarePaginator)) {
        $collection = $displayAdmins instanceof \Illuminate\Support\Collection ? $displayAdmins : collect($displayAdmins);
        $page = max(1, (int) request()->get('page', 1));
        $perPage = 20; // was 1
        $total = $collection->count();
        $results = $collection->slice(($page - 1) * $perPage, $perPage)->values();
        $displayAdmins = new \Illuminate\Pagination\LengthAwarePaginator(
        $results,
        $total,
        $perPage,
        $page,
        ['path' => request()->url(), 'query' => request()->query()]
        );
        }

        // Pager helpers (same pattern as shop)
        $resultCount = ($displayAdmins instanceof \Illuminate\Pagination\LengthAwarePaginator)
        ? $displayAdmins->total()
        : ($displayAdmins?->count() ?? 0);
        $showingFrom = $displayAdmins instanceof \Illuminate\Pagination\LengthAwarePaginator ? ($displayAdmins->firstItem() ?? 0) : 0;
        $showingTo = $displayAdmins instanceof \Illuminate\Pagination\LengthAwarePaginator ? ($displayAdmins->lastItem() ?? 0) : 0;
        $totalItems = $displayAdmins instanceof \Illuminate\Pagination\LengthAwarePaginator ? $displayAdmins->total() : 0;

        $pageUrl = function(int $page) {
        return request()->fullUrlWithQuery(['page' => $page]);
        };

        $pages = [];
        if ($displayAdmins instanceof \Illuminate\Pagination\LengthAwarePaginator) {
        $last = $displayAdmins->lastPage();
        $current = $displayAdmins->currentPage();
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
                    <form method="GET" action="{{ route('manage-admins') }}">
                        @csrf
                        <div class="flex items-center justify-between mb-4">
                            <h3 class="text-lg font-semibold text-gray-900">Search Admins</h3>
                            <div class="hidden md:flex items-center gap-2">
                                <a href="{{ route('manage-admins') }}" class="inline-flex items-center px-4 py-2 border border-gray-300 text-gray-700 font-medium rounded-[9px] hover:bg-gray-50 transition-colors">
                                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                                    </svg>
                                    Reset
                                </a>
                                <button type="button" id="addAdminBtn" class="inline-flex items-center px-4 py-2 bg-[#0479FF] hover:bg-[#0469DF] text-white font-medium rounded-[9px] transition-colors">
                                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                                    </svg>
                                    Add Admin
                                </button>
                            </div>
                        </div>

                        <div class="space-y-2">
                            <label for="search" class="block text-sm font-medium text-gray-700">
                                Search Admins
                            </label>
                            <div class="relative">
                                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                                    </svg>
                                </div>
                                <input
                                    type="text"
                                    id="search"
                                    name="search"
                                    value="{{ $search ?? '' }}"
                                    class="block w-full pl-10 pr-3 py-2.5 border border-gray-300 rounded-[9px] focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                                    placeholder="Search by name or email..."
                                    autocomplete="off">
                                @if (!empty($search))
                                <button type="button"
                                    class="absolute right-2 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 text-lg focus:outline-none"
                                    id="clearSearchX"
                                    tabindex="-1"
                                    aria-label="Clear search">
                                    &times;
                                </button>
                                @endif
                            </div>
                            <p class="text-xs text-gray-500">Search by admin name or email address</p>
                        </div>

                        <!-- Mobile buttons -->
                        <div class="md:hidden flex gap-3">
                            <a href="{{ route('manage-admins') }}" class="flex-1 inline-flex items-center justify-center px-4 py-2.5 border border-gray-300 text-gray-700 font-medium rounded-[9px] hover:bg-gray-50 transition-colors">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                                </svg>
                                Reset
                            </a>
                            <button type="button" id="addAdminBtnMobile" class="flex-1 inline-flex items-center justify-center px-4 py-2.5 bg-[#0479FF] hover:bg-[#0469DF] text-white font-medium rounded-[9px] transition-colors">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                                </svg>
                                Add Admin
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
                        <th class="px-6 py-4">Admin</th>
                        <th class="px-6 py-4">Role</th>
                        <th class="px-6 py-4">Created</th>
                        <th class="px-6 py-4">Last Updated</th>
                        <th class="px-6 py-4">Actions</th>
                    </tr>
                </thead>
                <tbody id="adminsTableBody" class="bg-white divide-y divide-gray-100">
                    @forelse ($displayAdmins as $admin)
                    <tr id="admin-row-{{ $admin->id }}" class="hover:bg-gray-50">
                        <td class="px-6 py-4">
                            <div class="flex items-center">
                                <div class="w-10 h-10 bg-[#0479FF] rounded-full flex items-center justify-center">
                                    <span class="text-white font-semibold text-sm">{{ strtoupper(substr($admin->name, 0, 1)) }}</span>
                                </div>
                                <div class="ml-4">
                                    <div class="font-semibold text-gray-900">{{ $admin->name }}</div>
                                    <div class="text-gray-500 text-sm">{{ $admin->email }}</div>
                                </div>
                            </div>
                        </td>
                        <td class="px-6 py-4">
                            <span class="inline-flex px-2 py-1 rounded-full text-xs font-semibold bg-blue-100 text-blue-700">
                                Administrator
                            </span>
                        </td>
                        <td class="px-6 py-4 text-gray-700 text-sm">
                            {{ $admin->created_at ? $admin->created_at->format('M j, Y') : '-' }}
                            @if($admin->created_at)
                            <div class="text-xs text-gray-500">
                                {{ $admin->created_at->format('H:i') }}
                            </div>
                            @endif
                        </td>
                        <td class="px-6 py-4 text-gray-700 text-sm">
                            {{ $admin->updated_at ? $admin->updated_at->format('M j, Y') : '-' }}
                            @if($admin->updated_at)
                            <div class="text-xs text-gray-500">
                                {{ $admin->updated_at->format('H:i') }}
                            </div>
                            @endif
                        </td>
                        <td class="px-6 py-4">
                            <div class="flex items-center gap-2">
                                <button class="edit-btn inline-flex items-center px-3 py-2 border border-gray-300 rounded-[9px] bg-white hover:bg-gray-50 text-sm font-medium"
                                    data-id="{{ $admin->id }}"
                                    data-name="{{ $admin->name }}"
                                    data-email="{{ $admin->email }}">
                                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                                    </svg>
                                    Edit
                                </button>
                                <button class="delete-btn inline-flex items-center px-3 py-2 border border-red-300 rounded-[9px] bg-white hover:bg-red-50 text-sm font-medium text-red-600"
                                    data-id="{{ $admin->id }}">
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
                                <div class="text-lg font-medium mb-2">No admins found</div>
                                <p class="text-sm">Try adjusting your search terms</p>
                                <a href="{{ route('manage-admins') }}" class="text-blue-600 hover:text-blue-700 underline">Reset search</a>
                            </div>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    {{-- Pagination (desktop) --}}
    @if($displayAdmins instanceof \Illuminate\Pagination\LengthAwarePaginator && $displayAdmins->lastPage() > 1)
    <div class="hidden lg:block">
        <div class="pager-container mt-6">
            <div class="pager-wrap w-full bg-white shadow-[0_4px_24px_0_rgba(30,41,59,0.13)] rounded-[18px] overflow-hidden">
                <div class="pager-info">Showing {{ $showingFrom }}–{{ $showingTo }} Out Of {{ $totalItems }}</div>
                <div class="pager">
                    <a href="{{ $pageUrl(1) }}" class="pager-btn {{ $displayAdmins->onFirstPage() ? 'disabled' : '' }}" aria-label="First page">«</a>
                    <a href="{{ $displayAdmins->previousPageUrl() ?: $pageUrl(1) }}" class="pager-btn {{ $displayAdmins->onFirstPage() ? 'disabled' : '' }}" aria-label="Previous page">‹</a>
                    @foreach($pages as $p)
                    @if($p === '...')
                    <span class="pager-ellipsis">…</span>
                    @else
                    @if($p == $displayAdmins->currentPage())
                    <span class="pager-btn active">{{ $p }}</span>
                    @else
                    <a href="{{ $pageUrl($p) }}" class="pager-btn">{{ $p }}</a>
                    @endif
                    @endif
                    @endforeach
                    <a href="{{ $displayAdmins->nextPageUrl() ?: $pageUrl($displayAdmins->lastPage()) }}" class="pager-btn {{ $displayAdmins->currentPage() == $displayAdmins->lastPage() ? 'disabled' : '' }}" aria-label="Next page">›</a>
                    <a href="{{ $pageUrl($displayAdmins->lastPage()) }}" class="pager-btn {{ $displayAdmins->currentPage() == $displayAdmins->lastPage() ? 'disabled' : '' }}" aria-label="Last page">»</a>
                </div>
            </div>
        </div>
    </div>
    @endif

    <!-- Mobile Card View (visible on mobile) -->
    <div id="adminsMobileList" class="lg:hidden space-y-4">
        @forelse ($displayAdmins as $admin)
        <div id="admin-card-{{ $admin->id }}" class="bg-white rounded-[18px]" style="box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);">
            <div class="p-4">
                <div class="flex items-start justify-between mb-3">
                    <div class="flex items-center">
                        <div class="w-12 h-12 bg-[#0479FF] rounded-full flex items-center justify-center">
                            <span class="text-white font-semibold">{{ strtoupper(substr($admin->name, 0, 1)) }}</span>
                        </div>
                        <div class="ml-3">
                            <div class="font-semibold text-gray-900">{{ $admin->name }}</div>
                            <div class="text-sm text-gray-500">{{ $admin->email }}</div>
                        </div>
                    </div>
                    <span class="inline-flex px-2 py-1 rounded-full text-xs font-semibold bg-blue-100 text-blue-700">
                        Admin
                    </span>
                </div>

                <div class="grid grid-cols-2 gap-4 mb-4 text-sm">
                    <div>
                        <div class="text-gray-500">Created</div>
                        <div class="font-medium">{{ $admin->created_at ? $admin->created_at->format('M j, Y') : '-' }}</div>
                    </div>
                    <div>
                        <div class="text-gray-500">Updated</div>
                        <div class="font-medium">{{ $admin->updated_at ? $admin->updated_at->format('M j, Y') : '-' }}</div>
                    </div>
                </div>

                <div class="flex gap-2">
                    <button class="edit-btn flex-1 inline-flex items-center justify-center px-3 py-2 border border-gray-300 rounded-[9px] bg-white hover:bg-gray-50 text-sm font-medium"
                        data-id="{{ $admin->id }}"
                        data-name="{{ $admin->name }}"
                        data-email="{{ $admin->email }}">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                        </svg>
                        Edit
                    </button>
                    <button class="delete-btn flex-1 inline-flex items-center justify-center px-3 py-2 border border-red-300 rounded-[9px] bg-white hover:bg-red-50 text-sm font-medium text-red-600"
                        data-id="{{ $admin->id }}">
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
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
            </svg>
            <div class="text-lg font-medium text-gray-900 mb-2">No admins found</div>
            <div class="text-gray-500 mb-4">Try adjusting your search terms</div>
            <a href="{{ route('manage-admins') }}" class="text-blue-600 hover:text-blue-700 underline">Reset search</a>
        </div>
        @endforelse
    </div>

    {{-- Pagination (mobile) --}}
    @if($displayAdmins instanceof \Illuminate\Pagination\LengthAwarePaginator && $displayAdmins->lastPage() > 1)
    <div class="pager-container mt-6 lg:hidden">
        <div class="pager-wrap w-full bg-white shadow-[0_4px_24px_0_rgba(30,41,59,0.13)] rounded-[18px] overflow-hidden">
            <div class="pager-info">Showing {{ $showingFrom }}–{{ $showingTo }} Out Of {{ $totalItems }}</div>
            <div class="pager">
                <a href="{{ $pageUrl(1) }}" class="pager-btn {{ $displayAdmins->onFirstPage() ? 'disabled' : '' }}" aria-label="First page">«</a>
                <a href="{{ $displayAdmins->previousPageUrl() ?: $pageUrl(1) }}" class="pager-btn {{ $displayAdmins->onFirstPage() ? 'disabled' : '' }}" aria-label="Previous page">‹</a>
                @foreach($pages as $p)
                @if($p === '...')
                <span class="pager-ellipsis">…</span>
                @else
                @if($p == $displayAdmins->currentPage())
                <span class="pager-btn active">{{ $p }}</span>
                @else
                <a href="{{ $pageUrl($p) }}" class="pager-btn">{{ $p }}</a>
                @endif
                @endif
                @endforeach
                <a href="{{ $displayAdmins->nextPageUrl() ?: $pageUrl($displayAdmins->lastPage()) }}" class="pager-btn {{ $displayAdmins->currentPage() == $displayAdmins->lastPage() ? 'disabled' : '' }}" aria-label="Next page">›</a>
                <a href="{{ $pageUrl($displayAdmins->lastPage()) }}" class="pager-btn {{ $displayAdmins->currentPage() == $displayAdmins->lastPage() ? 'disabled' : '' }}" aria-label="Last page">»</a>
            </div>
        </div>
    </div>
    @endif
    </div>

    <!-- Edit Modal -->
    <div id="editModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-40 hidden px-4">
        <div class="bg-white rounded-[18px] shadow-lg p-4 sm:p-8 w-full max-w-md relative mx-2" style="padding-bottom: 10px;">
            <button id="closeModal" class="absolute top-4 right-4 text-gray-400 hover:text-gray-600 text-xl">&times;</button>
            <h3 class="text-xl font-semibold mb-4">Edit Admin</h3>
            <form id="editForm" class="flex flex-col gap-4" autocomplete="off">
                <input type="hidden" name="id" id="editId">
                <div>
                    <label for="editName" class="block text-sm font-medium text-gray-700">Name</label>
                    <input type="text" name="name" id="editName" class="mt-1 block w-full border border-gray-300 rounded-[9px] px-3 py-2 focus:outline-none focus:border-[#0479FF] text-xs sm:text-sm" required>
                    <div id="editNameError" class="text-red-500 text-xs sm:text-sm mt-1 hidden"></div>
                </div>
                <div>
                    <label for="editEmail" class="block text-sm font-medium text-gray-700">Email</label>
                    <input type="email" name="email" id="editEmail" class="mt-1 block w-full border border-gray-300 rounded-[9px] px-3 py-2 focus:outline-none focus:border-[#0479FF] text-xs sm:text-sm" required>
                    <div id="editEmailError" class="text-red-500 text-xs sm:text-sm mt-1 hidden"></div>
                </div>
                <div>
                    <label for="editPassword" class="block text-sm font-medium text-gray-700">New Password</label>
                    <input type="password" name="password" id="editPassword" autocomplete="off" class="mt-1 block w-full border border-gray-300 rounded-[9px] px-3 py-2 focus:outline-none focus:border-[#0479FF] text-xs sm:text-sm">
                    <div id="editPasswordError" class="text-red-500 text-xs sm:text-sm mt-1 hidden"></div>
                </div>
                <div class="flex flex-col sm:flex-row justify-end gap-2 mt-4">
                    <button type="submit" class="px-4 py-2 bg-[#0479FF] text-white rounded-[9px] hover:bg-[#0469DF] transition w-full sm:w-auto">Save</button>
                </div>
                <div id="editError" class="text-red-500 text-xs sm:text-sm mt-2 hidden"></div>
            </form>
        </div>
    </div>

    <!-- Add Admin Modal -->
    <div id="addAdminModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-40 hidden px-4">
        <div class="bg-white rounded-[18px] shadow-lg p-4 sm:p-8 w-full max-w-md relative mx-2" style="padding-bottom: 10px;">
            <button id="closeAddAdminModal" class="absolute top-4 right-4 text-gray-400 hover:text-gray-600 text-xl">&times;</button>
            <h3 class="text-xl font-semibold mb-4">Add Admin</h3>
            <form id="addAdminForm" class="flex flex-col gap-4" autocomplete="off">
                <div>
                    <label for="addAdminName" class="block text-sm font-medium text-gray-700">Name</label>
                    <input type="text" name="name" id="addAdminName" class="mt-1 block w-full border border-gray-300 rounded-[9px] px-3 py-2 focus:outline-none focus:border-[#0479FF] text-xs sm:text-sm" required>
                    <div id="addAdminNameError" class="text-red-500 text-xs sm:text-sm mt-1 hidden"></div>
                </div>
                <div>
                    <label for="addAdminEmail" class="block text-sm font-medium text-gray-700">Email</label>
                    <input type="email" name="email" id="addAdminEmail" class="mt-1 block w-full border border-gray-300 rounded-[9px] px-3 py-2 focus:outline-none focus:border-[#0479FF] text-xs sm:text-sm" required>
                    <div id="addAdminEmailError" class="text-red-500 text-xs sm:text-sm mt-1 hidden"></div>
                </div>
                <div>
                    <label for="addAdminPassword" class="block text-sm font-medium text-gray-700">Password</label>
                    <input type="password" name="password" id="addAdminPassword" autocomplete="off" class="mt-1 block w-full border border-gray-300 rounded-[9px] px-3 py-2 focus:outline-none focus:border-[#0479FF] text-xs sm:text-sm" required>
                    <div id="addAdminPasswordError" class="text-red-500 text-xs sm:text-sm mt-1 hidden"></div>
                </div>
                <div>
                    <label for="addAdminPasswordConfirmation" class="block text-sm font-medium text-gray-700">Confirm Password</label>
                    <input type="password" name="password_confirmation" id="addAdminPasswordConfirmation" autocomplete="off" class="mt-1 block w-full border border-gray-300 rounded-[9px] px-3 py-2 focus:outline-none focus:border-[#0479FF] text-xs sm:text-sm" required>
                    <div id="addAdminPasswordConfirmationError" class="text-red-500 text-xs sm:text-sm mt-1 hidden"></div>
                </div>
                <div class="flex flex-col sm:flex-row justify-end gap-2 mt-4">
                    <button type="submit" class="px-4 py-2 bg-[#0479FF] text-white rounded-[9px] hover:bg-[#0469DF] transition w-full sm:w-auto">Add Admin</button>
                </div>
                <div id="addAdminGeneralError" class="text-red-500 text-xs sm:text-sm mt-2 hidden"></div>
            </form>
        </div>
    </div>

    <!-- Success Popup Modal -->
    <div id="successPopup" class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-40 hidden px-4">
        <div class="bg-white rounded-[18px] shadow-lg p-6 w-full max-w-sm relative mx-2 flex flex-col items-center">
            <button id="closeSuccessPopup" class="absolute top-2 right-2 text-gray-400 hover:text-gray-600 text-xl">&times;</button>
            <h3 class="text-lg font-semibold mb-4 text-green-600">Success</h3>
            <span id="successPopupMsg" class="text-gray-700 text-center"></span>
        </div>
    </div>

    <!-- Delete Confirmation Modal -->
    <div id="deleteConfirmModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-40 hidden px-4">
        <div class="bg-white rounded-[18px] shadow-lg p-6 w-full max-w-sm relative mx-2">
            <button id="closeDeleteConfirmModal" class="absolute top-2 right-2 text-gray-400 hover:text-gray-600 text-xl">&times;</button>
            <h3 class="text-lg font-semibold mb-4 text-red-600">Delete Admin</h3>
            <p class="mb-6 text-gray-700" id="deleteConfirmText">Are you sure you want to delete this admin?</p>
            <div class="flex flex-col sm:flex-row justify-end gap-2">
                <button id="cancelDeleteBtn" class="px-4 py-2 bg-gray-200 text-gray-700 rounded-[9px] hover:bg-gray-300 transition w-full sm:w-auto">Cancel</button>
                <button id="confirmDeleteBtn" class="px-4 py-2 bg-red-500 text-white rounded-[9px] hover:bg-red-600 transition w-full sm:w-auto">Delete</button>
            </div>
        </div>
    </div>

    <script>
        // Utilities for instant UI updates
        function formatDate(d) {
            const dt = d instanceof Date ? d : new Date(d);
            return dt.toLocaleDateString(undefined, {
                month: 'short',
                day: 'numeric',
                year: 'numeric'
            });
        }

        function formatTime(d) {
            const dt = d instanceof Date ? d : new Date(d);
            return dt.toLocaleTimeString(undefined, {
                hour12: false,
                hour: '2-digit',
                minute: '2-digit'
            });
        }
        async function tryParseJson(res) {
            const ct = (res.headers.get('Content-Type') || '').toLowerCase();
            if (!ct.includes('application/json')) return null;
            try {
                return await res.json();
            } catch {
                return null;
            }
        }

        // NEW: compute initial from name/email
        function getInitial(name, email) {
            const src = (name || email || '').trim();
            return src ? src.charAt(0).toUpperCase() : '?';
        }

        function renderAdminRow(admin) {
            const id = admin.id;
            const name = admin.name || '';
            const email = admin.email || '';
            const createdAt = admin.created_at || Date.now();
            const updatedAt = admin.updated_at || Date.now();
            const letter = (name || email || '?').trim().charAt(0).toUpperCase();
            return `
<tr id="admin-row-${id}" class="hover:bg-gray-50">
    <td class="px-6 py-4">
        <div class="flex items-center">
            <div class="w-10 h-10 bg-[#0479FF] rounded-full flex items-center justify-center">
                <span class="text-white font-semibold text-sm">${letter}</span>
            </div>
            <div class="ml-4">
                <div class="font-semibold text-gray-900">${name}</div>
                <div class="text-gray-500 text-sm">${email}</div>
            </div>
        </div>
    </td>
    <td class="px-6 py-4">
        <span class="inline-flex px-2 py-1 rounded-full text-xs font-semibold bg-blue-100 text-blue-700">Administrator</span>
    </td>
    <td class="px-6 py-4 text-gray-700 text-sm">
        ${formatDate(createdAt)}
        <div class="text-xs text-gray-500">${formatTime(createdAt)}</div>
    </td>
    <td class="px-6 py-4 text-gray-700 text-sm">
        ${formatDate(updatedAt)}
        <div class="text-xs text-gray-500">${formatTime(updatedAt)}</div>
    </td>
    <td class="px-6 py-4">
        <div class="flex items-center gap-2">
            <button class="edit-btn inline-flex items-center px-3 py-2 border border-gray-300 rounded-[9px] bg-white hover:bg-gray-50 text-sm font-medium"
                data-id="${id}" data-name="${name}" data-email="${email}">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                </svg>
                Edit
            </button>
            <button class="delete-btn inline-flex items-center px-3 py-2 border border-red-300 rounded-[9px] bg-white hover:bg-red-50 text-sm font-medium text-red-600"
                data-id="${id}">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                </svg>
                Delete
            </button>
        </div>
    </td>
</tr>`;
        }

        function renderAdminCard(admin) {
            const id = admin.id;
            const name = admin.name || '';
            const email = admin.email || '';
            const createdAt = admin.created_at || Date.now();
            const updatedAt = admin.updated_at || Date.now();
            const letter = (name || email || '?').trim().charAt(0).toUpperCase();
            return `
<div id="admin-card-${id}" class="bg-white rounded-[18px]" style="box-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);">
    <div class="p-4">
        <div class="flex items-start justify-between mb-3">
            <div class="flex items-center">
                <div class="w-12 h-12 bg-[#0479FF] rounded-full flex items-center justify-center">
                    <span class="text-white font-semibold">${letter}</span>
                </div>
                <div class="ml-3">
                    <div class="font-semibold text-gray-900">${name}</div>
                    <div class="text-sm text-gray-500">${email}</div>
                </div>
            </div>
            <span class="inline-flex px-2 py-1 rounded-full text-xs font-semibold bg-blue-100 text-blue-700">Admin</span>
        </div>
        <div class="grid grid-cols-2 gap-4 mb-4 text-sm">
            <div>
                <div class="text-gray-500">Created</div>
                <div class="font-medium">${formatDate(createdAt)}</div>
            </div>
            <div>
                <div class="text-gray-500">Updated</div>
                <div class="font-medium">${formatDate(updatedAt)}</div>
            </div>
        </div>
        <div class="flex gap-2">
            <button class="edit-btn flex-1 inline-flex items-center justify-center px-3 py-2 border border-gray-300 rounded-[9px] bg-white hover:bg-gray-50 text-sm font-medium"
                data-id="${id}" data-name="${name}" data-email="${email}">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                </svg>
                Edit
            </button>
            <button class="delete-btn flex-1 inline-flex items-center justify-center px-3 py-2 border border-red-300 rounded-[9px] bg-white hover:bg-red-50 text-sm font-medium text-red-600"
                data-id="${id}">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                </svg>
                Delete
            </button>
        </div>
    </div>
</div>`;
        }

        function prependAdminToUI(admin) {
            const tbody = document.getElementById('adminsTableBody');
            if (tbody) {
                const emptyRowLink = tbody.querySelector('a[href*="manage-admins"]');
                if (emptyRowLink) emptyRowLink.closest('tr')?.remove();
                tbody.insertAdjacentHTML('afterbegin', renderAdminRow(admin));
            }
            const mobileList = document.getElementById('adminsMobileList');
            if (mobileList) {
                const emptyMobileLink = mobileList.querySelector('a[href*="manage-admins"]');
                if (emptyMobileLink) emptyMobileLink.closest('div.bg-white')?.remove();
                mobileList.insertAdjacentHTML('afterbegin', renderAdminCard(admin));
            }
        }

        // Delegated click handlers so newly added items work instantly
        let deleteAdminId = null;

        document.addEventListener('click', function(e) {
            const editBtn = e.target.closest('.edit-btn');
            if (editBtn) {
                e.preventDefault();
                document.getElementById('editId').value = editBtn.dataset.id;
                document.getElementById('editName').value = editBtn.dataset.name;
                document.getElementById('editEmail').value = editBtn.dataset.email;
                document.getElementById('editPassword').value = '';
                document.getElementById('editError').classList.add('hidden');
                document.getElementById('editNameError').classList.add('hidden');
                document.getElementById('editEmailError').classList.add('hidden');
                document.getElementById('editPasswordError').classList.add('hidden');
                document.getElementById('editModal').classList.remove('hidden');
                return;
            }
            const delBtn = e.target.closest('.delete-btn');
            if (delBtn) {
                e.preventDefault();
                deleteAdminId = delBtn.dataset.id;
                document.getElementById('deleteConfirmModal').classList.remove('hidden');
                return;
            }
        });

        // Close modal handler
        document.getElementById('closeModal').onclick = function() {
            document.getElementById('editModal').classList.add('hidden');
        };

        function showSuccessPopup(message) {
            const popup = document.getElementById('successPopup');
            document.getElementById('successPopupMsg').textContent = message;
            popup.classList.remove('hidden');
        }

        document.getElementById('closeSuccessPopup').onclick = function() {
            document.getElementById('successPopup').classList.add('hidden');
        };

        // Edit form submit handler
        document.getElementById('editForm').onsubmit = function(e) {
            e.preventDefault();
            let id = document.getElementById('editId').value;
            let name = document.getElementById('editName').value;
            let email = document.getElementById('editEmail').value;
            let password = document.getElementById('editPassword').value;
            // Hide previous errors
            document.getElementById('editError').classList.add('hidden');
            document.getElementById('editNameError').classList.add('hidden');
            document.getElementById('editEmailError').classList.add('hidden');
            document.getElementById('editPasswordError').classList.add('hidden');
            let payload = {
                name,
                email
            };
            if (password) payload.password = password;

            fetch(`{{ url('manage-admins') }}/${id}`, {
                    method: 'PATCH',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRF-TOKEN': '{{ csrf_token() }}',
                        'Accept': 'application/json'
                    },
                    body: JSON.stringify(payload)
                })
                .then(async res => {
                    const data = await tryParseJson(res);
                    if (res.ok && data && data.success) {
                        // Update both desktop row and mobile card
                        let row = document.getElementById('admin-row-' + id);
                        if (row) {
                            let nameCell = row.querySelector('.font-semibold.text-gray-900');
                            let emailCell = row.querySelector('.text-gray-500.text-sm');
                            if (nameCell) nameCell.textContent = name;
                            if (emailCell) emailCell.textContent = email;

                            // NEW: update the avatar initial
                            const rowAvatar = row.querySelector('div.rounded-full span.text-white');
                            if (rowAvatar) rowAvatar.textContent = getInitial(name, email);

                            // Updated timestamp (now)
                            const now = new Date();
                            const tds = row.querySelectorAll('td');
                            if (tds[3]) {
                                tds[3].innerHTML = `${formatDate(now)}<div class="text-xs text-gray-500">${formatTime(now)}</div>`;
                            }
                            // Update data attributes for buttons
                            row.querySelectorAll('.edit-btn').forEach(btn => {
                                btn.dataset.name = name;
                                btn.dataset.email = email;
                            });
                        }

                        let card = document.getElementById('admin-card-' + id);
                        if (card) {
                            let nameDiv = card.querySelector('.font-semibold.text-gray-900');
                            let emailDiv = card.querySelector('.text-sm.text-gray-500');
                            if (nameDiv) nameDiv.textContent = name;
                            if (emailDiv) emailDiv.textContent = email;

                            // NEW: update the avatar initial
                            const cardAvatar = card.querySelector('div.rounded-full span.text-white');
                            if (cardAvatar) cardAvatar.textContent = getInitial(name, email);

                            // Updated date (now)
                            const updatedDateEl = card.querySelectorAll('.grid .font-medium')[1];
                            if (updatedDateEl) updatedDateEl.textContent = formatDate(new Date());
                            // Update data attributes for buttons
                            card.querySelectorAll('.edit-btn').forEach(btn => {
                                btn.dataset.name = name;
                                btn.dataset.email = email;
                            });
                        }
                        document.getElementById('editModal').classList.add('hidden');
                        showSuccessPopup('Admin updated successfully!');
                    } else if (res.status === 422 && data) {
                        let errors = data.errors || {};
                        if (errors.name) {
                            document.getElementById('editNameError').textContent = errors.name.join(' ');
                            document.getElementById('editNameError').classList.remove('hidden');
                        }
                        if (errors.email) {
                            document.getElementById('editEmailError').textContent = errors.email.join(' ');
                            document.getElementById('editEmailError').classList.remove('hidden');
                        }
                        if (errors.password) {
                            document.getElementById('editPasswordError').textContent = errors.password.join(' ');
                            document.getElementById('editPasswordError').classList.remove('hidden');
                        }
                        let otherErrors = Object.keys(errors).filter(k => !['name', 'email', 'password'].includes(k));
                        if (otherErrors.length) {
                            document.getElementById('editError').textContent = otherErrors.map(k => errors[k].join(' ')).join(' ');
                            document.getElementById('editError').classList.remove('hidden');
                        }
                    } else {
                        // Fallback if server didn't return JSON success (e.g., redirect)
                        window.location.reload();
                    }
                })
                .catch(() => {
                    document.getElementById('editError').textContent = 'Update failed.';
                    document.getElementById('editError').classList.remove('hidden');
                });
        };

        // Add Admin Modal handlers
        function openAddAdminModal() {
            document.getElementById('addAdminModal').classList.remove('hidden');
            document.getElementById('addAdminName').value = '';
            document.getElementById('addAdminEmail').value = '';
            document.getElementById('addAdminPassword').value = '';
            document.getElementById('addAdminPasswordConfirmation').value = '';
            document.getElementById('addAdminNameError').classList.add('hidden');
            document.getElementById('addAdminEmailError').classList.add('hidden');
            document.getElementById('addAdminPasswordError').classList.add('hidden');
            document.getElementById('addAdminPasswordConfirmationError').classList.add('hidden');
            document.getElementById('addAdminGeneralError').classList.add('hidden');
        }

        document.getElementById('addAdminBtn').onclick = openAddAdminModal;
        document.getElementById('addAdminBtnMobile').onclick = openAddAdminModal;

        document.getElementById('closeAddAdminModal').onclick = function() {
            document.getElementById('addAdminModal').classList.add('hidden');
        };

        document.getElementById('addAdminForm').onsubmit = function(e) {
            e.preventDefault();
            // Hide previous errors
            document.getElementById('addAdminNameError').classList.add('hidden');
            document.getElementById('addAdminEmailError').classList.add('hidden');
            document.getElementById('addAdminPasswordError').classList.add('hidden');
            document.getElementById('addAdminPasswordConfirmationError').classList.add('hidden');
            document.getElementById('addAdminGeneralError').classList.add('hidden');
            // Get values
            let name = document.getElementById('addAdminName').value;
            let email = document.getElementById('addAdminEmail').value;
            let password = document.getElementById('addAdminPassword').value;
            let password_confirmation = document.getElementById('addAdminPasswordConfirmation').value;

            fetch(`{{ route('manage-admins.store') }}`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRF-TOKEN': '{{ csrf_token() }}',
                        'Accept': 'application/json'
                    },
                    body: JSON.stringify({
                        name,
                        email,
                        password,
                        password_confirmation
                    })
                })
                .then(async res => {
                    const data = await tryParseJson(res);
                    if (res.ok && data && data.success) {
                        // If API returns the created admin, render it into the UI
                        if (data.admin) {
                            prependAdminToUI(data.admin);
                            document.getElementById('addAdminModal').classList.add('hidden');
                            showSuccessPopup('Admin added successfully!');
                        } else {
                            // Fallback: reload to reflect new data when API doesn't return the admin object
                            window.location.reload();
                        }
                    } else if (res.status === 422 && data) {
                        let errors = data.errors || {};
                        if (errors.name) {
                            document.getElementById('addAdminNameError').textContent = errors.name.join(' ');
                            document.getElementById('addAdminNameError').classList.remove('hidden');
                        }
                        if (errors.email) {
                            document.getElementById('addAdminEmailError').textContent = errors.email.join(' ');
                            document.getElementById('addAdminEmailError').classList.remove('hidden');
                        }
                        if (errors.password) {
                            document.getElementById('addAdminPasswordError').textContent = errors.password.join(' ');
                            document.getElementById('addAdminPasswordError').classList.remove('hidden');
                        }
                        if (errors.password_confirmation) {
                            document.getElementById('addAdminPasswordConfirmationError').textContent = errors.password_confirmation.join(' ');
                            document.getElementById('addAdminPasswordConfirmationError').classList.remove('hidden');
                        }
                        let otherErrors = Object.keys(errors).filter(k => !['name', 'email', 'password', 'password_confirmation'].includes(k));
                        if (otherErrors.length) {
                            document.getElementById('addAdminGeneralError').textContent = otherErrors.map(k => errors[k].join(' ')).join(' ');
                            document.getElementById('addAdminGeneralError').classList.remove('hidden');
                        }
                    } else {
                        // Fallback if server didn't return JSON success (e.g., redirect)
                        window.location.reload();
                    }
                })
                .catch(() => {
                    document.getElementById('addAdminGeneralError').textContent = 'Add failed.';
                    document.getElementById('addAdminGeneralError').classList.remove('hidden');
                });
        };

        // Delete button handler
        document.getElementById('closeDeleteConfirmModal').onclick = function() {
            document.getElementById('deleteConfirmModal').classList.add('hidden');
            deleteAdminId = null;
        };
        document.getElementById('cancelDeleteBtn').onclick = function() {
            document.getElementById('deleteConfirmModal').classList.add('hidden');
            deleteAdminId = null;
        };

        document.getElementById('confirmDeleteBtn').onclick = function() {
            if (!deleteAdminId) return;
            fetch(`{{ url('manage-admins') }}/${deleteAdminId}`, {
                    method: 'DELETE',
                    headers: {
                        'X-CSRF-TOKEN': '{{ csrf_token() }}',
                        'Accept': 'application/json'
                    }
                })
                .then(res => res.json())
                .then(data => {
                    if (data.success) {
                        document.getElementById('admin-row-' + deleteAdminId)?.remove();
                        document.getElementById('admin-card-' + deleteAdminId)?.remove();
                        document.getElementById('deleteConfirmModal').classList.add('hidden');
                        showSuccessPopup('Admin deleted successfully!');
                    } else {
                        document.getElementById('deleteConfirmModal').classList.add('hidden');
                        alert('Delete failed.');
                    }
                    deleteAdminId = null;
                })
                .catch(() => {
                    document.getElementById('deleteConfirmModal').classList.add('hidden');
                    alert('Delete failed.');
                    deleteAdminId = null;
                });
        };

        // Clear search button handler
        const clearBtn = document.getElementById('clearSearchX');
        if (clearBtn) {
            clearBtn.onclick = function() {
                document.getElementById('search').value = '';
                window.location.href = '{{ route("manage-admins") }}';
            };
        }

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
    </script>
</x-app-layout>