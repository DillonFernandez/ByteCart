import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../services/api_service.dart';
import '../theme/theme_colours.dart';
import 'checkout.dart';

class CartState {
  final List<Map<String, dynamic>> items;
  final bool loading;
  final Object? error;
  final String? message;
  final bool connectionError;

  CartState({
    this.items = const [],
    this.loading = true,
    this.error,
    this.message,
    this.connectionError = false,
  });

  CartState copyWith({
    List<Map<String, dynamic>>? items,
    bool? loading,
    Object? error,
    String? message,
    bool? connectionError,
  }) {
    return CartState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      error: error ?? this.error,
      message: message ?? this.message,
      connectionError: connectionError ?? this.connectionError,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState()) {
    loadCart();
  }

  Future<void> loadCart() async {
    state = state.copyWith(
      loading: true,
      error: null,
      message: null,
      connectionError: false,
    );
    try {
      final data = await ApiService.getCartItems();
      state = state.copyWith(
        items: data,
        loading: false,
        error: null,
        connectionError: false,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e,
        connectionError: _isConnectionError(e),
      );
    }
  }

  Future<void> updateQty(String lineId, int qty) async {
    state = state.copyWith(loading: true, message: null);
    try {
      await ApiService.updateCartItem(lineId: lineId, qty: qty);
      final data = await ApiService.getCartItems();
      state = state.copyWith(
        items: data,
        loading: false,
        error: null,
        message: 'Quantity updated',
        connectionError: false,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e,
        message: 'Failed to update quantity.',
        connectionError: _isConnectionError(e),
      );
    }
  }

  Future<void> removeItem(String lineId) async {
    state = state.copyWith(loading: true, message: null);
    try {
      await ApiService.removeFromCart(lineId);
      final data = await ApiService.getCartItems();
      state = state.copyWith(
        items: data,
        loading: false,
        error: null,
        message: 'Item removed',
        connectionError: false,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e,
        message: 'Failed to remove item.',
        connectionError: _isConnectionError(e),
      );
    }
  }

  Future<void> clearCart() async {
    state = state.copyWith(loading: true, message: null);
    try {
      await ApiService.clearCart();
      final data = await ApiService.getCartItems();
      state = state.copyWith(
        items: data,
        loading: false,
        error: null,
        message: 'Cart cleared',
        connectionError: false,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e,
        message: 'Failed to clear cart.',
        connectionError: _isConnectionError(e),
      );
    }
  }

  void clearMessage() {
    state = state.copyWith(message: null);
  }

  bool _isConnectionError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection');
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
      (ref) => CartNotifier(),
);

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  String _productName(Map<String, dynamic> item) {
    final candidates = <dynamic>[
      item['product_name'],
      item['name'],
      item['title'],
      if (item['product'] is Map) (item['product'] as Map)['name'],
    ];
    for (final c in candidates) {
      if (c != null) {
        final s = c.toString().trim();
        if (s.isNotEmpty) return s;
      }
    }
    return 'Product';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLandscape =
        MediaQuery
            .of(context)
            .orientation == Orientation.landscape;
    final items = state.items;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.message != null) {
        _showBanner(
          context,
          state.message!,
          isError: state.error != null,
          isDark: theme.brightness == Brightness.dark,
        );
        notifier.clearMessage();
      }
    });

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        title: const Text(
          'Shopping Cart',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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
      body:
      isLandscape
          ? state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.connectionError
          ? _connectionErrorView(context, notifier)
          : state.error != null
          ? _errorView(context, notifier)
          : items.isEmpty
          ? _emptyCart(context)
          : _buildLandscapeCartBody(context, ref, items)
          : state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.connectionError
          ? _connectionErrorView(context, notifier)
          : state.error != null
          ? _errorView(context, notifier)
          : items.isEmpty
          ? _emptyCart(context)
          : RefreshIndicator(
        color:
        theme.brightness == Brightness.dark
            ? Colors.white
            : Colors.black,
        onRefresh: notifier.loadCart,
        child: _buildCartContent(context, ref, items),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton:
      (!isLandscape && items.isNotEmpty)
          ? FloatingActionButton(
        onPressed: () => _showOrderSummaryDialog(context, items),
        backgroundColor: kMainColour,
        foregroundColor: Colors.white,
        child: const Icon(Icons.receipt_long),
      )
          : null,
    );
  }

  void _showBanner(BuildContext context,
      String msg, {
        required bool isError,
        required bool isDark,
      }) {
    final bg =
    isError
        ? (isDark ? Colors.red[700] : Colors.red[100])
        : (isDark ? Colors.green[700] : Colors.green[100]);
    final fg =
    isError
        ? (isDark ? Colors.white : Colors.red[900])
        : (isDark ? Colors.white : Colors.green[900]);
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: bg,
        content: Row(
          children: [
            Icon(icon, color: fg),
            const SizedBox(width: 12),
            Expanded(child: Text(msg, style: TextStyle(color: fg))),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _connectionErrorView(BuildContext context, CartNotifier notifier) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off,
            size: 48,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
          const SizedBox(height: 16),
          Text(
            'Connection error. Please check your internet connection.',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: notifier.loadCart,
            icon: Icon(
              Icons.refresh,
              color: isDark ? Colors.white : Colors.black,
            ),
            label: Text(
              'Retry',
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              foregroundColor: isDark ? Colors.white : Colors.black,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView(BuildContext context, CartNotifier notifier) {
    final scheme = Theme
        .of(context)
        .colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load cart',
            style: Theme
                .of(
              context,
            )
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'An error occurred while loading your cart.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onBackground.withOpacity(0.7)),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: notifier.loadCart,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kMainColour,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCart(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: kMainColour.withOpacity(0.1),
                borderRadius: BorderRadius.circular(48),
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 48,
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

  Widget _buildCartContent(BuildContext context,
      WidgetRef ref,
      List<Map<String, dynamic>> items,) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 768;
        if (isLargeScreen) {
          return _buildDesktopLayout(context, ref, items);
        } else {
          return _buildMobileLayout(context, ref, items);
        }
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context,
      WidgetRef ref,
      List<Map<String, dynamic>> items,) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Expanded(child: _buildCartItems(context, ref, items))],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context,
      WidgetRef ref,
      List<Map<String, dynamic>> items,) {
    return Column(
      children: [Expanded(child: _buildCartItems(context, ref, items))],
    );
  }

  Widget _buildProgressBar(BuildContext context) {
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
            valueColor: const AlwaysStoppedAnimation<Color>(kMainColour),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Cart',
                style: TextStyle(
                  color: kMainColour,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              Text('Checkout', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(BuildContext context,
      WidgetRef ref,
      List<Map<String, dynamic>> items,) {
    return Column(
      children: [
        _buildProgressBar(context),
        _buildCartHeader(context, ref, items.length),
        Expanded(
          child: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(overscroll: false),
            child: RefreshIndicator(
              color:
              Theme
                  .of(context)
                  .brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              onRefresh: ref
                  .read(cartProvider.notifier)
                  .loadCart,
              child: ListView.builder(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                itemCount: items.length,
                itemBuilder:
                    (context, index) =>
                    _buildCartItemCard(context, ref, items[index], index),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartHeader(BuildContext context, WidgetRef ref, int count) {
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
                  color: kMainColour.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count ${count == 1 ? 'item' : 'items'}',
                  style: const TextStyle(
                    color: kMainColour,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => _showClearCartDialog(context, ref),
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

  Widget _buildCartItemCard(BuildContext context,
      WidgetRef ref,
      Map<String, dynamic> item,
      int index,) {
    final theme = Theme.of(context);
    final notifier = ref.read(cartProvider.notifier);
    final lineId = item['line_id'] ?? index.toString();
    final price = (item['price'] ?? 0).toDouble();
    final qty = item['qty'] ?? 1;
    final imageUrl = _formatImageUrl(item['image']);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child:
                    imageUrl.isNotEmpty
                        ? Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (context, error, stackTrace) =>
                          _buildPlaceholderImage(context),
                    )
                        : _buildPlaceholderImage(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _productName(item),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
                              color: Theme
                                  .of(
                                context,
                              )
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        if (item['options'] is Map &&
                            item['options']['color'] != null)
                          Text(
                            'Color: ${item['options']['color']}',
                            style: TextStyle(
                              color: Theme
                                  .of(
                                context,
                              )
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Transform.translate(
                            offset: const Offset(-14, 0),
                            child: _buildQuantityControls(
                              context,
                              ref,
                              lineId,
                              qty,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Theme
                                      .of(
                                    context,
                                  )
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
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
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              onPressed:
                  () =>
                  notifier.removeItem(item['line_id'] ?? index.toString()),
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

  String _formatImageUrl(dynamic path) {
    if (path == null || (path is String && path.isEmpty)) return '';
    final url = path.toString();
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    const base = 'http://10.0.2.2:8000';
    return url.startsWith('/') ? '$base$url' : '$base/$url';
  }

  Widget _buildPlaceholderImage(BuildContext context) {
    return Icon(
      Icons.image_outlined,
      color: Theme
          .of(context)
          .colorScheme
          .onSurface
          .withOpacity(0.2),
      size: 32,
    );
  }

  Widget _paymentIcon(BuildContext context,
      String asset, {
        bool fullWidth = false,
      }) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    final chipBg = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final chipBorder = isDark ? Colors.white24 : Colors.black12;

    return Container(
      width: fullWidth ? double.infinity : 64,
      height: fullWidth ? 48 : 40,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipBorder, width: 1.5),
      ),
      child: Image.asset(asset, fit: BoxFit.contain),
    );
  }

  Future<void> _showOrderSummaryDialog(BuildContext context,
      List<Map<String, dynamic>> items,) async {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final popupBg = isDark ? Colors.grey[900] : Colors.grey[100];

    double subtotal = 0;
    for (var item in items) {
      subtotal += ((item['price'] ?? 0) * (item['qty'] ?? 1)).toDouble();
    }
    const shipping = 5.0;
    final tax = subtotal * 0.05;
    final total = subtotal + shipping + tax;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Order Summary',
      barrierColor: Colors.black54,
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
                          context,
                          'Subtotal (${items.length} items)',
                          subtotal,
                        ),
                        _buildSummaryRow(context, 'Shipping', shipping),
                        _buildSummaryRow(context, 'Tax (estimated)', tax),
                        const Divider(height: 32),
                        _buildSummaryRow(
                          context,
                          'Total',
                          total,
                          isTotal: true,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CheckoutPage(),
                                ),
                              );
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
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _paymentIcon(
                                    context,
                                    'assets/images/icons/Visa.webp',
                                    fullWidth: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _paymentIcon(
                                    context,
                                    'assets/images/icons/Mastercard.webp',
                                    fullWidth: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _paymentIcon(
                                    context,
                                    'assets/images/icons/Koko.webp',
                                    fullWidth: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _paymentIcon(
                                    context,
                                    'assets/images/icons/Mintpay.webp',
                                    fullWidth: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _paymentIcon(
                                    context,
                                    'assets/images/icons/COD.webp',
                                    fullWidth: true,
                                  ),
                                ),
                              ],
                            ),
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
      transitionBuilder:
          (context, animation, secondaryAnimation, child) => child,
    );
  }

  Widget _buildSummaryRow(BuildContext context,
      String label,
      double amount, {
        bool isTotal = false,
      }) {
    final scheme = Theme
        .of(context)
        .colorScheme;
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

  Future<void> _showClearCartDialog(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final popupBg = isDark ? Colors.grey[900] : Colors.grey[100];

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) =>
          Center(
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
      await ref.read(cartProvider.notifier).clearCart();
    }
  }

  Widget _buildQuantityControls(BuildContext context,
      WidgetRef ref,
      String lineId,
      int qty,) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black;
    final notifier = ref.read(cartProvider.notifier);
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          color: iconColor,
          onPressed: qty > 1 ? () => notifier.updateQty(lineId, qty - 1) : null,
        ),
        Text(
          '$qty',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          color: iconColor,
          onPressed: () => notifier.updateQty(lineId, qty + 1),
        ),
      ],
    );
  }

  Widget _buildLandscapeCartBody(BuildContext context,
      WidgetRef ref,
      List<Map<String, dynamic>> items,) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (items.isEmpty) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _emptyCart(context),
          );
        }
        final isWide = constraints.maxWidth >= 900;
        final isMedium =
            constraints.maxWidth >= 700 && constraints.maxWidth < 900;

        if (isWide || isMedium) {
          final rightMaxWidth = isWide ? 420.0 : 340.0;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildCartItems(context, ref, items)),
                const SizedBox(width: 20),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: rightMaxWidth),
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _buildOrderSummaryPanel(context, items),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Expanded(child: _buildCartItems(context, ref, items)),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight * 0.6,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _buildOrderSummaryPanel(context, items),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildOrderSummaryPanel(BuildContext context,
      List<Map<String, dynamic>> items,) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? Colors.grey[900] : Colors.grey[50];

    double subtotal = 0;
    for (var item in items) {
      subtotal += ((item['price'] ?? 0) * (item['qty'] ?? 1)).toDouble();
    }
    const shipping = 5.0;
    final tax = subtotal * 0.05;
    final total = subtotal + shipping + tax;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kMainColour.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long, color: kMainColour),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Order Summary',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: scheme.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            context,
            'Subtotal (${items.length} items)',
            subtotal,
          ),
          _buildSummaryRow(context, 'Shipping', shipping),
          _buildSummaryRow(context, 'Tax (estimated)', tax),
          const Divider(height: 32),
          _buildSummaryRow(context, 'Total', total, isTotal: true),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const CheckoutPage()));
              },
              icon: const Icon(Icons.lock_outline),
              label: const Text('Secure Checkout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kMainColour,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user, color: Colors.green[600], size: 16),
                const SizedBox(width: 8),
                Text(
                  '256-bit SSL Encrypted',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
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
          LayoutBuilder(
            builder: (context, cons) {
              final gap = 12.0;
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _paymentIcon(
                          context,
                          'assets/images/icons/Visa.webp',
                          fullWidth: true,
                        ),
                      ),
                      SizedBox(width: gap),
                      Expanded(
                        child: _paymentIcon(
                          context,
                          'assets/images/icons/Mastercard.webp',
                          fullWidth: true,
                        ),
                      ),
                      SizedBox(width: gap),
                      Expanded(
                        child: _paymentIcon(
                          context,
                          'assets/images/icons/Koko.webp',
                          fullWidth: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _paymentIcon(
                          context,
                          'assets/images/icons/Mintpay.webp',
                          fullWidth: true,
                        ),
                      ),
                      SizedBox(width: gap),
                      Expanded(
                        child: _paymentIcon(
                          context,
                          'assets/images/icons/COD.webp',
                          fullWidth: true,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
