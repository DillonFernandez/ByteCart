<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>ByteCart | {{ $product->product_name ?? 'Product' }}</title>
    <link rel="icon" type="image/x-icon" href="{{ asset('logo/x-icon.webp') }}">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <style>
        /* Remove number input arrows for quantity */
        input[type=number]::-webkit-inner-spin-button,
        input[type=number]::-webkit-outer-spin-button {
            -webkit-appearance: none;
            margin: 0;
        }

        input[type=number] {
            -moz-appearance: textfield;
        }
    </style>
</head>

<body>
    @livewire('nav-bar')
    <div class="w-full mx-auto pb-8 pt-5 px-4 sm:px-16 sm:pb-10 sm:pt-5">
        @if(isset($product))
        <div class="flex flex-col lg:flex-row">
            <!-- Left: Product Images -->
            <div class="w-full lg:w-7/12 flex flex-col justify-start lg:h-full relative mb-8 lg:mb-0 mr-0 lg:mr-8">
                @if(!empty($product->image))
                <div id="product-image-container" class="relative w-full h-[420px] lg:h/full rounded-[18px] p-7 bg-white shadow-[0_8px_32px_0_rgba(30,41,59,0.10)] flex items-center justify-center">
                    <img src="{{ asset($product->image) }}" alt="Product Image" class="img-zoom w-full h-full object-contain rounded-[9px]"
                        style="max-height:340px;">
                    @php
                    $showBadges = $product->discount > 0 || $product->new_stock;
                    $allOutOfStock = $product->models->every(fn($m) => $m->stock <= 0);
                        @endphp
                        @if($showBadges || $allOutOfStock)
                        <div class="absolute top-6 right-6 flex flex-col items-end gap-2 z-10">
                        @if($product->discount > 0)
                        <span class="bg-red-500 text-white px-4 py-1 rounded-[9px] text-xs font-semibold shadow">{{ $product->discount
                            }}% OFF</span>
                        @endif
                        @if($product->new_stock)
                        <span class="bg-green-500 text-white px-4 py-1 rounded-[9px] text-xs font-semibold shadow">New</span>
                        @endif
                        @if($allOutOfStock)
                        <span class="bg-gray-700 text-white px-4 py-1 rounded-[9px] text-xs font-semibold shadow">Out of Stock</span>
                        @endif
                </div>
                @endif
            </div>
            @else
            <span class="text-gray-400">No Image</span>
            @endif
        </div>
        <!-- Right: Product Info & Cart -->
        <div class="w-full lg:w-5/12 flex flex-col gap-6 justify-center lg:h-full">
            <div id="product-info-cart" class="bg-white rounded-[18px] shadow-[0_8px_32px_0_rgba(30,41,59,0.10)] p-8 cart-fade h-full">
                <h1 class="text-2xl font-bold text-gray-900 mb-2 leading-tight">{{ $product->product_name }}</h1>
                <div class="text-base text-gray-500 font-semibold mb-3">{{ $product->brand_name }} <span class="ml-2 text-xs text-gray-400">
                        {{ $product->product_category }}</span></div>
                @php
                $minPrice = $product->models->min('price');
                $maxPrice = $product->models->max('price');
                $hasRange = $minPrice && $maxPrice && $minPrice != $maxPrice;
                $discountedMin = $minPrice && $product->discount > 0 ? round($minPrice * (1 - $product->discount / 100), 2) : $minPrice;
                $discountedMax = $maxPrice && $product->discount > 0 ? round($maxPrice * (1 - $product->discount / 100), 2) : $maxPrice;
                @endphp
                <div class="flex items-center gap-4 mb-4" id="price-display">
                    <span class="text-3xl font-bold text-gray-900">
                        @if($product->discount > 0)
                        @if($hasRange)
                        <span class="line-through text-gray-400 text-lg">${{ $minPrice }} - ${{ $maxPrice }}</span>
                        <span class="ml-2">${{ $discountedMin }} - ${{ $discountedMax }}</span>
                        @else
                        <span class="line-through text-gray-400 text-lg">${{ $minPrice }}</span>
                        <span class="ml-2">${{ $discountedMin }}</span>
                        @endif
                        @else
                        @if($hasRange)
                        <span>${{ $minPrice }} - ${{ $maxPrice }}</span>
                        @else
                        <span>${{ $minPrice }}</span>
                        @endif
                        @endif
                    </span>
                </div>
                <!-- Model Selection -->
                <div class="mb-3">
                    <div class="font-semibold text-gray-700 mb-2">Model</div>
                    <div class="flex gap-2 flex-wrap" id="model-select">
                        @foreach($product->models as $model)
                        <span class="px-4 py-2 rounded-[9px] border border-gray-200 bg-gray-50 text-gray-700 font-semibold text-sm cursor-pointer model-option {{ $model->stock <= 0 ? 'opacity-50 cursor-not-allowed' : '' }}"
                            data-model-id="{{ $model->id }}" data-price="{{ $model->price }}" data-colors="{{ $model->colors }}" data-discount="{{ $product->discount }}" data-stock="{{ $model->stock }}">{{ $model->model_name }}
                            @if($model->stock <= 0)
                                @endif
                                </span>
                                @endforeach
                    </div>
                </div>
                <!-- Color Selection -->
                <div class="mb-3">
                    <div class="font-semibold text-gray-700 mb-2">Color</div>
                    <div class="flex gap-2 flex-wrap" id="color-select">
                        @php
                        $allColors = collect($product->models)->flatMap(function($model) {
                        return array_map('trim', explode(',', $model->colors));
                        })->filter()->unique()->values();
                        @endphp
                        @foreach($allColors as $color)
                        @php
                        $colorOutOfStock = $product->models->every(function($m) use ($color) {
                        return !in_array($color, array_map('trim', explode(',', $m->colors))) || $m->stock <= 0;
                            });
                            @endphp
                            <span class="px-4 py-2 rounded-[9px] border border-gray-200 bg-gray-50 text-gray-700 font-semibold text-sm cursor-pointer color-option hover:bg-gray-100 transition {{ $colorOutOfStock ? 'opacity-50 cursor-not-allowed' : '' }}">{{ $color }}</span>
                            @endforeach
                    </div>
                    <div id="color-warning" class="text-xs text-red-500 mt-2 hidden">Please select a model first.</div>
                </div>
                <!-- Cart Summary -->
                <div class="flex flex-col gap-2 mt-6 mb-4">
                    <div class="flex items-center gap-3 text-gray-700">
                        <span class="font-semibold">Quantity:</span>
                        <div class="flex items-center gap-1">
                            <button type="button" id="qty-minus" class="w-8 h-10 flex items-center justify-center rounded-[9px] border border-gray-200 bg-gray-50 text-gray-500 hover:bg-gray-100 transition text-lg font-bold">-</button>
                            <input type="number" min="1" value="1" id="qty-input"
                                class="w-12 h-10 px-0 py-2 border border-gray-200 rounded-[9px] text-center font-semibold text-gray-700 focus:outline-none focus:ring-2 focus:ring-blue-200 transition" />
                            <button type="button" id="qty-plus" class="w-8 h-10 flex items-center justify-center rounded-[9px] border border-gray-200 bg-gray-50 text-gray-500 hover:bg-gray-100 transition text-lg font-bold">+</button>
                        </div>
                    </div>
                </div>
                <!-- Add to Cart -->
                <div class="flex gap-4 mt-4">
                    @if($allOutOfStock)
                    <button class="bg-gray-400 text-white px-6 py-3 rounded-[9px] font-semibold text-lg flex items-center gap-2 shadow w-full justify-center opacity-50 cursor-not-allowed" disabled>
                        Out of Stock
                    </button>
                    @else
                    @auth
                    @if(auth()->user()->hasRole('customer'))
                    <button id="add-to-cart-btn" data-url="{{ route('cart.add') }}" class="bg-blue-600 text-white px-6 py-3 rounded-[9px] font-semibold text-lg flex items-center gap-2 shadow hover:bg-blue-700 transition w-full justify-center">
                        Add to Cart
                    </button>
                    @else
                    <a href="{{ route('login') }}" class="bg-gray-500 text-white px-6 py-3 rounded-[9px] font-semibold text-lg flex items-center gap-2 shadow hover:bg-gray-600 transition w-full justify-center">
                        Only customers can purchase
                    </a>
                    @endif
                    @else
                    <a href="{{ route('login') }}" class="bg-gray-500 text-white px-6 py-3 rounded-[9px] font-semibold text-lg flex items-center gap-2 shadow hover:bg-gray-600 transition w-full justify-center">
                        Sign in as customer to purchase
                    </a>
                    @endauth
                    @endif
                </div>
            </div>
        </div>
    </div>
    <!-- Description & Specification Tabs -->
    <div class="bg-white rounded-[18px] shadow-[0_4px_24px_0_rgba(30,41,59,0.13)] p-8 mb-8 mt-8 lg:mt-8 lg:mb-0">
        <div class="flex justify-center border-b border-gray-200 mb-6">
            <button id="descTab" class="px-4 py-2 text-lg font-bold text-gray-800 focus:outline-none border-b-2 border-blue-600 tab-active" type="button">Description</button>
            <button id="specTab" class="px-4 py-2 text-lg font-bold text-gray-800 focus:outline-none border-b-2 border-transparent" type="button">Specifications</button>
        </div>
        <div id="descContent" class="text-gray-700">{{ $product->description }}</div>
        <div id="specContent" class="text-gray-700 hidden">{{ $product->specification }}</div>
    </div>
    <!-- Related Products Section -->
    @if(isset($relatedProducts) && $relatedProducts->count())
    <div class="w-full flex items-center my-12">
        <hr class="flex-grow border-t border-gray-200">
        <span class="mx-4 text-gray-400 text-sm font-semibold">More to Explore</span>
        <hr class="flex-grow border-t border-gray-200">
    </div>
    <div class="mt-4">
        <h2 class="text-2xl font-bold mb-6 text-center sm:text-left text-gray-800">Related Products</h2>
        <div class="grid grid-cols-2 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            @foreach($relatedProducts as $related)
            @include('livewire.product-card', ['product' => $related])
            @endforeach
        </div>
    </div>
    @endif
    @else
    <div class="text-center text-gray-500">Product not found.</div>
    @endif
    </div>
    @livewire('footer')
    <div id="toast-container" class="fixed bottom-4 right-4 z-50 flex flex-col gap-2 pointer-events-none"></div>
    <script>
        // Lightweight toast for Add to Cart confirmations
        (function() {
            const container = document.getElementById('toast-container');

            function showToast(message, type = 'success') {
                if (!container) return;
                const el = document.createElement('div');
                el.role = 'status';
                el.className = 'pointer-events-auto px-4 py-3 rounded-[9px] shadow text-white text-sm font-semibold transition-all duration-300 transform opacity-0 translate-y-2 ' + (type === 'success' ? 'bg-green-600' : type === 'warning' ? 'bg-yellow-600' : 'bg-red-600');
                el.textContent = message;
                container.appendChild(el);
                requestAnimationFrame(() => {
                    el.classList.remove('opacity-0', 'translate-y-2');
                    el.classList.add('opacity-100', 'translate-y-0');
                });
                setTimeout(() => {
                    el.classList.add('opacity-0', 'translate-y-2');
                    setTimeout(() => el.remove(), 300);
                }, 2200);
            }

            // Show confirmation when cart is updated
            window.addEventListener('cart-updated', function() {
                showToast('Added to cart!', 'success');
            });
        })();
    </script>
    <script>
        // Subtle micro-interaction for Add to Cart
        document.querySelectorAll('.lux-btn').forEach(btn => {
            btn.addEventListener('mousedown', () => btn.classList.add('scale-95'));
            btn.addEventListener('mouseup', () => btn.classList.remove('scale-95'));
            btn.addEventListener('mouseleave', () => btn.classList.remove('scale-95'));
        });

        // Dynamic price and color update based on selected model
        document.addEventListener('DOMContentLoaded', function() {
            const modelOptions = document.querySelectorAll('.model-option');
            const priceDisplay = document.getElementById('price-display');
            const colorSelect = document.getElementById('color-select');
            const colorWarning = document.getElementById('color-warning');
            const addToCartBtn = document.getElementById('add-to-cart-btn');
            let selectedModel = null;
            let selectedColor = null;

            function getSelectedColorEl() {
                return colorSelect.querySelector('.color-option.bg-blue-100');
            }

            function updateAddToCartState(modelStock = null) {
                if (!addToCartBtn) return;
                const stock = modelStock !== null ? modelStock : (selectedModel ? parseInt(selectedModel.getAttribute('data-stock')) : 0);
                const hasModel = !!selectedModel && stock > 0;
                const hasColor = !!getSelectedColorEl();
                if (hasModel && hasColor) {
                    addToCartBtn.classList.remove('opacity-50', 'cursor-not-allowed');
                    addToCartBtn.removeAttribute('disabled');
                } else {
                    addToCartBtn.classList.add('opacity-50', 'cursor-not-allowed');
                    addToCartBtn.setAttribute('disabled', 'disabled');
                }
            }

            function attachColorListeners(modelStock) {
                const colorOptions = colorSelect.querySelectorAll('.color-option');
                colorOptions.forEach(option => {
                    if (option.classList.contains('cursor-not-allowed')) return;
                    option.addEventListener('click', function() {
                        if (!selectedModel || modelStock <= 0) {
                            colorWarning.classList.remove('hidden');
                            setTimeout(() => colorWarning.classList.add('hidden'), 1800);
                            return;
                        }
                        colorOptions.forEach(o => o.classList.remove('bg-blue-100', 'border-blue-400'));
                        this.classList.add('bg-blue-100', 'border-blue-400');
                        selectedColor = this;
                        updateAddToCartState(modelStock);
                    });
                });
            }

            // Initial attach for all colors (no model selected)
            attachColorListeners(1);
            updateAddToCartState();

            modelOptions.forEach(option => {
                if (option.classList.contains('cursor-not-allowed')) return;
                option.addEventListener('click', function() {
                    // Remove active styling from all
                    modelOptions.forEach(o => o.classList.remove('bg-blue-100', 'border-blue-400'));
                    this.classList.add('bg-blue-100', 'border-blue-400');
                    selectedModel = this;
                    // Update price
                    const price = parseFloat(this.getAttribute('data-price'));
                    const discount = parseFloat(this.getAttribute('data-discount'));
                    const modelStock = parseInt(this.getAttribute('data-stock'));
                    let priceHtml = '';
                    if (discount > 0) {
                        const discounted = Math.round(price * (1 - discount / 100) * 100) / 100;
                        priceHtml = `<span class='line-through text-gray-400 text-lg'>$${price}</span> <span class='ml-2'>$${discounted}</span>`;
                    } else {
                        priceHtml = `<span>$${price}</span>`;
                    }
                    priceDisplay.innerHTML = `<span class='text-3xl font-bold text-gray-900'>${priceHtml}</span>`;
                    // Update colors
                    const colors = this.getAttribute('data-colors').split(',').map(c => c.trim()).filter(Boolean);
                    colorSelect.innerHTML = colors.map(color => `<span class='px-4 py-2 rounded-[9px] border border-gray-200 bg-gray-50 text-gray-700 font-semibold text-sm cursor-pointer color-option hover:bg-gray-100 transition ${modelStock <= 0 ? 'opacity-50 cursor-not-allowed' : ''}'>${color}</span>`).join('');
                    attachColorListeners(modelStock);
                    selectedColor = null;
                    // Ensure Add to Cart requires both model and color
                    updateAddToCartState(modelStock);
                });
            });
            // If all models are out of stock, ensure Add to Cart stays disabled
            if (addToCartBtn && modelOptions.length > 0 && Array.from(modelOptions).every(o => o.classList.contains('cursor-not-allowed'))) {
                addToCartBtn.classList.add('opacity-50', 'cursor-not-allowed');
                addToCartBtn.setAttribute('disabled', 'disabled');
            }
        });

        // Height sync for desktop: image container matches product info & cart div
        function syncImageHeight() {
            if (window.innerWidth >= 1024) { // lg breakpoint
                var infoCart = document.getElementById('product-info-cart');
                var imageContainer = document.getElementById('product-image-container');
                if (infoCart && imageContainer) {
                    imageContainer.style.height = infoCart.offsetHeight + 'px';
                }
            } else {
                var imageContainer = document.getElementById('product-image-container');
                if (imageContainer) {
                    imageContainer.style.height = '';
                }
            }
        }
        window.addEventListener('load', syncImageHeight);
        window.addEventListener('resize', syncImageHeight);

        // Elegant quantity input plus/minus logic
        const qtyInput = document.getElementById('qty-input');
        const qtyMinus = document.getElementById('qty-minus');
        const qtyPlus = document.getElementById('qty-plus');
        if (qtyInput && qtyMinus && qtyPlus) {
            qtyMinus.addEventListener('click', function() {
                let val = parseInt(qtyInput.value) || 1;
                if (val > 1) qtyInput.value = val - 1;
            });
            qtyPlus.addEventListener('click', function() {
                let val = parseInt(qtyInput.value) || 1;
                qtyInput.value = val + 1;
            });
        }

        // Tab switching for Description/Specifications
        document.addEventListener('DOMContentLoaded', function() {
            const descTab = document.getElementById('descTab');
            const specTab = document.getElementById('specTab');
            const descContent = document.getElementById('descContent');
            const specContent = document.getElementById('specContent');
            if (descTab && specTab && descContent && specContent) {
                descTab.addEventListener('click', function() {
                    descTab.classList.add('border-blue-600');
                    descTab.classList.remove('border-transparent');
                    specTab.classList.remove('border-blue-600');
                    specTab.classList.add('border-transparent');
                    descContent.classList.remove('hidden');
                    specContent.classList.add('hidden');
                });
                specTab.addEventListener('click', function() {
                    specTab.classList.add('border-blue-600');
                    specTab.classList.remove('border-transparent');
                    descTab.classList.remove('border-blue-600');
                    descTab.classList.add('border-transparent');
                    specContent.classList.remove('hidden');
                    descContent.classList.add('hidden');
                });
            }
        });
    </script>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const addToCartBtn = document.getElementById('add-to-cart-btn');
            const qtyInput = document.getElementById('qty-input');

            function getSelectedModelId() {
                const selected = document.querySelector('.model-option.bg-blue-100');
                return selected ? selected.getAttribute('data-model-id') : null;
            }

            function getSelectedColor() {
                const selected = document.querySelector('#color-select .color-option.bg-blue-100');
                return selected ? selected.textContent.trim() : null;
            }

            async function handleAddToCart() {
                const modelId = getSelectedModelId();
                if (!modelId) {
                    alert('Please select a model first.');
                    return;
                }

                const color = getSelectedColor();
                if (!color) {
                    alert('Please select a color first.');
                    return;
                }

                const qty = Math.max(1, parseInt(qtyInput?.value || '1', 10));

                addToCartBtn.setAttribute('disabled', 'disabled');
                addToCartBtn.classList.add('opacity-50', 'cursor-not-allowed');

                try {
                    const res = await fetch(addToCartBtn?.dataset?.url, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'Accept': 'application/json',
                            'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
                        },
                        body: JSON.stringify({
                            model_id: modelId,
                            qty: qty,
                            color: color,
                        }),
                    });

                    const data = await res.json();

                    if (res.ok && data.success) {
                        // Broadcast a browser event so any component can react (e.g., refresh cart badge/total)
                        window.dispatchEvent(new CustomEvent('cart-updated', {
                            detail: {
                                count: data.cart_count,
                                total: data.cart_total
                            }
                        }));

                        // Optional: show a quick success message
                        // e.g., toast('Added to cart!')
                        console.log('Added to cart', data);
                    } else {
                        alert(data.message || 'Could not add to cart.');
                    }
                } catch (e) {
                    console.error(e);
                    alert('Network error. Please try again.');
                } finally {
                    addToCartBtn.removeAttribute('disabled');
                    addToCartBtn.classList.remove('opacity-50', 'cursor-not-allowed');
                }
            }

            if (addToCartBtn) {
                addToCartBtn.addEventListener('click', handleAddToCart);
            }
        });
    </script>
</body>

</html>