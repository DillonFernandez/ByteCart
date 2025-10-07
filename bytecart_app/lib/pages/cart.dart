import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/theme_colours.dart'; // NEW: use shared accent color

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> _cartItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _loading = true);
    try {
      final items = await ApiService.getCartItems();
      setState(() => _cartItems = items);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading cart: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateQty(String lineId, int qty) async {
    try {
      await ApiService.updateCartItem(lineId: lineId, qty: qty);
      await _loadCart();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    }
  }

  Future<void> _removeItem(String lineId) async {
    try {
      await ApiService.removeFromCart(lineId);
      await _loadCart();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to remove: $e')));
    }
  }

  Future<void> _clearCart() async {
    try {
      await ApiService.clearCart();
      await _loadCart();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart cleared successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to clear cart: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        title: const Text(
          'Shopping Cart',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // CHANGED: match other pages (stable, theme-aware)
        backgroundColor: scheme.background,
        foregroundColor: scheme.onBackground,
        iconTheme: IconThemeData(color: scheme.onBackground),
        titleTextStyle: theme.textTheme.titleMedium?.copyWith(
          color: scheme.onBackground,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16), // keep page padding at 16
        child:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _cartItems.isEmpty
                ? _emptyCart(context)
                : _buildCartContent(),
      ),
      // CHANGED: single icon-only FAB on the right
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton:
          _cartItems.isEmpty
              ? null
              : FloatingActionButton(
                onPressed: _showOrderSummaryDialog,
                backgroundColor: kMainColour,
                foregroundColor: Colors.white,
                child: const Icon(Icons.receipt_long),
              ),
    );
  }

  Widget _emptyCart(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16), // CHANGED: whole page padding 16
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                // CHANGED: unify accent ring
                color: kMainColour.withOpacity(0.1),
                borderRadius: BorderRadius.circular(48),
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 48,
                // CHANGED: unify icon accent
                color: kMainColour,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your cart is empty',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onBackground,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Discover our latest electronics and gadgets.\nAdd some items to get started!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onBackground.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Start Shopping'),
              style: FilledButton.styleFrom(
                // CHANGED: unify CTA accent
                backgroundColor: kMainColour,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 768;

        if (isLargeScreen) {
          return _buildDesktopLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(
        0,
      ), // outer padding handled by Scaffold body
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildCartItems()),
          // Removed right-side Order Summary panel (now a FAB dialog)
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(child: _buildCartItems()),
        // Removed bottom Order Summary panel (now a FAB dialog)
      ],
    );
  }

  Widget _buildProgressBar() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shopping Cart',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Step 1 of 2',
                style: TextStyle(
                  color: scheme.onBackground.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: 0.5,
            backgroundColor: theme.colorScheme.surfaceVariant,
            // CHANGED: unify progress accent
            valueColor: const AlwaysStoppedAnimation<Color>(kMainColour),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cart',
                style: TextStyle(
                  // CHANGED
                  color: kMainColour,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              Text(
                'Checkout',
                style: TextStyle(
                  color: scheme.onBackground.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems() {
    return Column(
      children: [
        _buildProgressBar(),
        _buildCartHeader(),
        Expanded(
          child: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(
              overscroll: false,
            ), // NEW: no glow/stretch
            child: ListView.builder(
              // CHANGED: remove bounce/overscroll animation
              physics: const ClampingScrollPhysics(),
              // CHANGED: no extra bottom padding; ends at last item
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              itemCount: _cartItems.length,
              itemBuilder:
                  (context, index) =>
                      _buildCartItemCard(_cartItems[index], index),
            ),
          ),
        ),
        // REMOVED: inline continue shopping (now a left FAB)
        // _buildContinueShopping(),
      ],
    );
  }

  Widget _buildCartHeader() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Cart Items',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  // CHANGED: chip bg
                  color: kMainColour.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_cartItems.length} ${_cartItems.length == 1 ? 'item' : 'items'}',
                  style: const TextStyle(
                    // CHANGED: chip text color
                    color: kMainColour,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => _showClearCartDialog(),
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    color: scheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(Map<String, dynamic> item, int index) {
    final theme = Theme.of(context);

    final lineId = item['line_id'] ?? index.toString();
    final price = (item['price'] ?? 0).toDouble();
    final qty = item['qty'] ?? 1;
    final imageUrl = _formatImageUrl(item['image']);
    final isDark = theme.brightness == Brightness.dark; // NEW

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        // CHANGED: match ProductCard background
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(18),
        // CHANGED: no heavy shadow to align with ProductCard look
        boxShadow: const [],
      ),
      child: Stack(
        children: [
          // Card content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // CHANGED: Product Image (no bg, just rounded clip)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child:
                        imageUrl.isNotEmpty
                            ? Image.network(
                              imageUrl,
                              fit: BoxFit.contain, // align with ProductCard
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      _buildPlaceholderImage(),
                            )
                            : _buildPlaceholderImage(),
                  ),
                ),
                const SizedBox(width: 16),
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row (IconButton removed)
                      Row(
                        children: const [
                          Expanded(
                            child: Text(
                              // ...existing name binding...
                              // name
                              '',
                              // Note: keep original Text with name and styles
                            ),
                          ),
                        ],
                      ),
                      if (item['model_name'] != null ||
                          (item['options'] is Map &&
                              item['options']['color'] != null)) ...[
                        const SizedBox(height: 4),
                        if (item['model_name'] != null)
                          Text(
                            'Model: ${item['model_name']}',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        if (item['options'] is Map &&
                            item['options']['color'] != null)
                          Text(
                            'Color: ${item['options']['color']}',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildQuantityControls(lineId, qty),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '\$${(price * qty).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // NEW: top-right remove button, nudged closer to edges
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              onPressed: () => _removeItem(item['line_id'] ?? index.toString()),
              padding: const EdgeInsets.all(0),
              constraints: const BoxConstraints(),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.close,
                  color: theme.colorScheme.error,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Add this helper before _buildPlaceholderImage()
  String _formatImageUrl(dynamic path) {
    if (path == null || (path is String && path.isEmpty)) return '';
    final url = path.toString();
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    const base = 'http://10.0.2.2:8000'; // your Laravel base URL
    return url.startsWith('/') ? '$base$url' : '$base/$url';
  }

  Widget _buildPlaceholderImage() {
    return Icon(
      Icons.image_outlined,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
      size: 32,
    );
  }

  // NEW: compact payment icon with border
  Widget _paymentIcon(String asset) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Match Product Detail model pill bg and border
    final chipBg = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final chipBorder = isDark ? Colors.white24 : Colors.black12;

    return Container(
      width: 64,
      height: 40,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipBorder, width: 1.5),
      ),
      child: Image.asset(asset, fit: BoxFit.contain),
    );
  }

  Future<void> _showOrderSummaryDialog() async {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final popupBg = isDark ? Colors.grey[900] : Colors.grey[100];

    double subtotal = 0;
    for (var item in _cartItems) {
      subtotal += ((item['price'] ?? 0) * (item['qty'] ?? 1)).toDouble();
    }
    const shipping = 5.0;
    final tax = subtotal * 0.05;
    final total = subtotal + shipping + tax;

    // CHANGED: use showGeneralDialog with no transition to remove fade
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Order Summary',
      barrierColor: Colors.black54,
      // keep dimmed backdrop if desired
      transitionDuration: Duration.zero,
      pageBuilder: (context, _, __) {
        return Center(
          child: Dialog(
            backgroundColor: popupBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 35,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 412.0),
              // ...existing Stack/Dialog content unchanged...
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Summary',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: scheme.onBackground,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          'Subtotal (${_cartItems.length} items)',
                          subtotal,
                        ),
                        _buildSummaryRow('Shipping', shipping),
                        _buildSummaryRow('Tax (estimated)', tax),
                        const Divider(height: 32),
                        _buildSummaryRow('Total', total, isTotal: true),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              // Navigate to checkout if available
                            },
                            icon: const Icon(Icons.lock_outline),
                            label: const Text('Secure Checkout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kMainColour,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified_user,
                                color: Colors.green[600],
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '256-bit SSL Encrypted',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'Accepted payment methods',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onBackground.withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _paymentIcon('assets/images/icons/Visa.webp'),
                            _paymentIcon('assets/images/icons/Mastercard.webp'),
                            _paymentIcon('assets/images/icons/Koko.webp'),
                            _paymentIcon('assets/images/icons/Mintpay.webp'),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      // No-op transition (no fade/scale)
      transitionBuilder:
          (context, animation, secondaryAnimation, child) => child,
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color:
                  isTotal
                      ? scheme.onBackground
                      : scheme.onSurface.withOpacity(0.7),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: scheme.onBackground,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearCartDialog() async {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final popupBg = isDark ? Colors.grey[900] : Colors.grey[100];

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Center(
            child: Theme(
              data: theme.copyWith(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
              ),
              child: Dialog(
                backgroundColor: popupBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 35,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 412.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clear Cart',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: scheme.onBackground,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Are you sure you want to empty your cart?',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onBackground.withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              style: TextButton.styleFrom(
                                foregroundColor: scheme.onBackground
                                    .withOpacity(0.7),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: const Text('Yes, clear'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
    );

    if (confirmed == true) {
      _clearCart();
    }
  }

  Widget _buildQuantityControls(String lineId, int qty) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black; // CHANGED
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          color: iconColor, // CHANGED
          onPressed: qty > 1 ? () => _updateQty(lineId, qty - 1) : null,
        ),
        Text(
          '$qty',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          color: iconColor, // CHANGED
          onPressed: () => _updateQty(lineId, qty + 1),
        ),
      ],
    );
  }
}
