<?php

/**
 * CartTotal (Livewire)
 *
 * Displays the cart item count and total in real time:
 * - Initializes totals on mount
 * - Listens for cart updates and refreshes values
 * - Provides a helper to pull current totals from the Cart facade
 * - Renders a small UI fragment for header/cart icon
 */

namespace App\Livewire;

use Livewire\Component;
use Livewire\Attributes\On;
use App\Support\Cart\CartFacade as Cart;

class CartTotal extends Component
{
    // State: values shown in the UI
    public int $count = 0;
    public float $total = 0.0;

    /**
     * Bootstrap totals on component mount.
     */
    public function mount(): void
    {
        $this->refreshTotals();
    }

    /**
     * Handle 'cart-updated' events and refresh totals.
     */
    #[On('cart-updated')]
    public function updateTotals(array $payload = []): void
    {
        if (isset($payload['count'], $payload['total'])) {
            $this->count = (int) $payload['count'];
            $this->total = (float) $payload['total'];
        } else {
            $this->refreshTotals();
        }
    }

    /**
     * Refresh totals from the Cart facade.
     */
    public function refreshTotals(): void
    {
        $this->count = (int) Cart::count();
        $this->total = (float) Cart::total();
    }

    /**
     * Render the cart totals view fragment.
     */
    public function render()
    {
        return view('livewire.cart-total');
    }
}
