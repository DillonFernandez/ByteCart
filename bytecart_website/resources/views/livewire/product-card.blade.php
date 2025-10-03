<!-- Product Card (Blade)
     Displays a product with image, badges, pricing, brand/category, wishlist toggle, and link to details. -->

<!-- Styles: card layout, effects, grid, and responsive behavior -->
<style>
    .card {
        --card-bg: #ffffff;
        --card-accent: #0479FF;
        --card-text: #1e293b;
        --card-shadow: 0 4px 24px 0 rgba(30, 41, 59, 0.13);
        width: 100%;
        max-width: 340px;
        min-width: 180px;
        height: auto;
        background: var(--card-bg);
        border-radius: 18px;
        position: relative;
        overflow: hidden;
        transition: all 0.5s cubic-bezier(0.16, 1, 0.3, 1);
        box-shadow: var(--card-shadow);
        margin-left: auto;
        margin-right: auto;
        display: flex;
        flex-direction: column;
    }

    .card__shine {
        position: absolute;
        inset: 0;
        background: linear-gradient(120deg,
                rgba(255, 255, 255, 0) 40%,
                rgba(255, 255, 255, 0.8) 50%,
                rgba(255, 255, 255, 0) 60%);
        opacity: 0;
        transition: opacity 0.3s ease;
    }

    .card__glow {
        position: absolute;
        inset: -10px;
        background: radial-gradient(circle at 50% 0%,
                rgba(4, 121, 255, 0.18) 0%,
                rgba(4, 121, 255, 0) 70%);
        opacity: 0;
        transition: opacity 0.5s ease;
    }

    .card__content {
        padding: 1.25em;
        height: 100%;
        display: flex;
        flex-direction: column;
        gap: 0.75em;
        position: relative;
        z-index: 2;
    }

    .card__badge {
        position: absolute;
        top: 12px;
        left: 12px;
        background: #ef4444;
        color: white;
        padding: 0.25em 0.5em;
        border-radius: 4.5px;
        font-size: 0.7em;
        font-weight: 600;
        opacity: 1;
        transform: scale(1);
        transition: all 0.4s ease 0.1s;
        z-index: 2;
    }

    .card__badge--new {
        left: auto;
        right: 12px;
        background: #10b981;
        opacity: 1;
        transform: scale(1);
    }

    .card__image {
        width: 100%;
        height: 160px;
        min-height: 100px;
        max-height: 100px;
        background: linear-gradient(45deg, #e0e7ef, #f3f4f6);
        border-radius: 9px;
        position: relative;
        overflow: hidden;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .card__image img {
        width: 100%;
        height: 100%;
        max-width: 100%;
        max-height: 100%;
        object-fit: contain;
        display: block;
        margin: 0 auto;
        padding: 8px;
        border-radius: 9px;
        background: none;
        border: none;
        box-shadow: none;
    }

    .card__text {
        display: flex;
        flex-direction: column;
        gap: 0;
        margin-top: 0.5em;
    }

    .card__title {
        color: var(--card-text);
        font-size: 1.1em;
        margin: 0;
        font-weight: 700;
        transition: all 0.3s ease;
        line-height: 1.2;
        white-space: normal;
        overflow: visible;
        text-overflow: unset;
        word-break: break-word;
    }

    .card__brand {
        color: #64748b;
        font-size: 0.9em;
        margin: 0;
        font-weight: 500;
        opacity: 1;
        transition: all 0.3s ease;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    .card__category {
        color: #94a3b8;
        font-size: 0.8em;
        margin: 0;
        font-weight: 400;
    }

    .card__footer {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-top: auto;
        gap: 0.5em;
    }

    .card__price {
        color: var(--card-text);
        font-weight: 700;
        font-size: 1em;
        transition: all 0.3s ease;
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        flex: 1 1 auto;
        white-space: normal;
        overflow: visible;
        text-overflow: unset;
        word-break: break-word;
    }

    .card__price .line-through {
        color: #94a3b8;
        font-size: 0.95em;
        text-decoration: line-through;
        margin-bottom: 2px;
        font-weight: 400;
    }

    .card__button {
        width: 28px;
        height: 28px;
        aspect-ratio: 1/1;
        background: var(--card-accent);
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
        cursor: pointer;
        transition: all 0.3s ease;
        font-size: 1.1em;
        box-shadow: 0 2px 8px 0 #e5e7eb;
        border: none;
        align-self: flex-end;
        margin-left: auto;
        transform: scale(0.9);
        text-decoration: none;
        min-width: 28px;
        min-height: 28px;
        max-width: 28px;
        max-height: 28px;
        position: relative;
    }

    .card:hover .card__button::after {
        content: '';
        position: absolute;
        inset: -6px;
        border-radius: 50%;
        background: radial-gradient(circle, rgba(4, 121, 255, 0.25) 0%, rgba(4, 121, 255, 0.08) 60%, transparent 100%);
        z-index: 0;
        pointer-events: none;
        animation: buttonGlow 0.5s;
    }

    @keyframes buttonGlow {
        from {
            opacity: 0;
            transform: scale(0.8);
        }

        to {
            opacity: 1;
            transform: scale(1);
        }
    }

    .card:hover {
        transform: translateY(-10px);
        box-shadow: 0 8px 32px 0 rgba(30, 41, 59, 0.18);
    }

    .card:hover .card__shine {
        opacity: 1;
        animation: shine 3s infinite;
    }

    .card:hover .card__glow {
        opacity: 1;
    }

    .card:hover .card__image {
        transform: translateY(-5px) scale(1.03);
        box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
        border-radius: 9px;
    }

    .card:hover .card__title {
        color: var(--card-text);
        transform: translateX(2px);
    }

    .card:hover .card__price {
        color: var(--card-text);
        transform: translateX(2px);
    }

    .card:hover .card__button {
        transform: scale(1.05);
    }

    @keyframes shine {
        0% {
            background-position: -100% 0;
        }

        100% {
            background-position: 200% 0;
        }
    }

    .custom-card-grid {
        display: grid;
        grid-template-columns: 1fr;
        gap: 1.25rem;
        justify-items: center;
        align-items: stretch;
    }

    @media (min-width: 640px) {
        .custom-card-grid {
            grid-template-columns: repeat(2, 1fr);
        }
    }

    @media (min-width: 900px) {
        .custom-card-grid {
            grid-template-columns: repeat(3, 1fr);
        }
    }

    @media (min-width: 1280px) {
        .custom-card-grid {
            grid-template-columns: repeat(4, 1fr);
        }
    }

    @media (max-width: 640px) {
        .card:hover {
            transform: none;
            box-shadow: var(--card-shadow);
        }

        .card:hover .card__shine,
        .card:hover .card__glow {
            opacity: 0;
            animation: none;
        }

        .card:hover .card__image {
            transform: none;
            box-shadow: none;
        }

        .card:hover .card__title {
            color: var(--card-text);
            transform: none;
        }

        .card:hover .card__price {
            color: var(--card-text);
            transform: none;
        }

        .card:hover .card__button {
            transform: none;
        }

        .card:hover .card__button::after {
            animation: none;
            opacity: 0;
        }

        .custom-card-grid {
            grid-template-columns: repeat(2, minmax(0, 1fr));
        }

        .card {
            min-width: 0;
            max-width: 100%;
        }
    }
</style>

@php
// Precompute pricing (min/max), discounted values, and wishlist inclusion for current user
$prices = $product->models->pluck('price')->filter()->sort();
$minPrice = $prices->min();
$maxPrice = $prices->max();
$hasRange = $minPrice && $maxPrice && $minPrice != $maxPrice;
$discountedMin = $minPrice && $product->discount > 0 ? round($minPrice * (1 - $product->discount / 100), 2) : $minPrice;
$discountedMax = $maxPrice && $product->discount > 0 ? round($maxPrice * (1 - $product->discount / 100), 2) : $maxPrice;
$inWishList = false;
if(auth()->check()) {
$inWishList = \App\Models\WishList::where('user_id', auth()->user()->id)
->where('product_id', $product->id)
->exists();
}
@endphp

<!-- Product card: effects, image/badges, details, price/action -->
<div class="card">
    <div class="card__shine"></div>
    <div class="card__glow"></div>
    <div class="card__content">
        <div class="card__image" style="position:relative;">
            <div style="position:absolute;top:8px;left:8px;display:flex;flex-direction:column;gap:4px;z-index:3;">
                @if($product->discount > 0)
                <div class="card__badge" style="position:static;">-{{ $product->discount }}%</div>
                @endif
                @if($product->new_stock)
                <div class="card__badge card__badge--new" style="position:static;">New</div>
                @endif
            </div>
            <div style="position:absolute;top:8px;right:8px;z-index:3;">
                @if(auth()->check() && (auth()->user()->roles ?? null) === 'customer')
                <img class="card__star"
                    src="{{ asset($inWishList ? 'icons/star 2.webp' : 'icons/star 1.webp') }}"
                    alt="Favorite"
                    style="width:28px;height:28px;cursor:pointer;box-shadow:0 2px 8px 0 #e5e7eb;border-radius:50%;background:#fff;padding:4px;"
                    onclick="toggleWishList(this, '{{ $product->id }}')">
                @endif
            </div>
            @php
            $allOutOfStock = $product->models->every(fn($m) => $m->stock <= 0);
                @endphp
                @if($allOutOfStock)
                <div class="card__badge" style="position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);background:#6b7280;">Out of Stock
        </div>
        @endif
        @if(!empty($product->image))
        <img src="{{ asset($product->image) }}" alt="Product Image" />
        @else
        <span class="text-gray-400">No Image</span>
        @endif
    </div>
    <div class="card__text">
        <p class="card__title">{{ $product->product_name }}</p>
        <p class="card__brand">{{ $product->brand_name }}</p>
        <p class="card__category">{{ $product->product_category }}</p>
    </div>
    <div class="card__footer">
        <div class="card__price">
            @if($minPrice)
            @if($product->discount > 0)
            @if($hasRange)
            <span class="line-through">${{ $minPrice }} - ${{ $maxPrice }}</span>
            <span>${{ $discountedMin }} - ${{ $discountedMax }}</span>
            @else
            <span class="line-through">${{ $minPrice }}</span>
            <span>${{ $discountedMin }}</span>
            @endif
            @else
            @if($hasRange)
            <span>${{ $minPrice }} - ${{ $maxPrice }}</span>
            @else
            <span>${{ $minPrice }}</span>
            @endif
            @endif
            @else
            <span class="text-gray-400 text-sm">No price</span>
            @endif
        </div>
        <div style="display: flex; flex-direction: column; align-items: flex-end; gap: 8px;">
            <a href="/product/{{ $product->id }}" class="card__button" title="Add to Cart">
                <svg height="18" width="18" viewBox="0 0 24 24">
                    <path stroke-width="2" stroke="currentColor" d="M4 12H20M12 4V20" fill="currentColor"></path>
                </svg>
            </a>
        </div>
    </div>
</div>
</div>

@if(auth()->check() && (auth()->user()->roles ?? null) === 'customer')
<script>
    // Wishlist toggle handler (POST add/remove; update icon and refresh wishlist page if removed)
    function toggleWishList(img, productId) {
        var inWishList = img.src.includes('star%202.webp');
        var url = inWishList ? "{{ route('wish-list.remove') }}" : "{{ route('wish-list.add') }}";
        var star1 = "{{ asset('icons/star 1.webp') }}";
        var star2 = "{{ asset('icons/star 2.webp') }}";
        fetch(url, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': "{{ csrf_token() }}"
                },
                body: JSON.stringify({
                    product_id: productId
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    img.src = inWishList ? star1 : star2;
                    if (inWishList && window.location.pathname.includes('wish-list')) {
                        window.location.reload();
                    }
                }
            });
    }
</script>
@endif