import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../widgets/productcard.dart';

class WishlistState {
  final List<Map<String, dynamic>> wishlist;
  final bool loading;
  final String? error;

  WishlistState({this.wishlist = const [], this.loading = true, this.error});

  WishlistState copyWith({
    List<Map<String, dynamic>>? wishlist,
    bool? loading,
    String? error,
  }) {
    return WishlistState(
      wishlist: wishlist ?? this.wishlist,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class WishlistNotifier extends StateNotifier<WishlistState> {
  WishlistNotifier() : super(WishlistState()) {
    loadWishlist();
  }

  Future<void> loadWishlist() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final data = await ApiService.getWishlist();
      state = state.copyWith(wishlist: data, loading: false, error: null);
    } catch (_) {
      state = state.copyWith(
        loading: false,
        error: 'Unable to load your wish list. Please check your connection.',
      );
    }
  }

  Future<void> removeItem(String productId, BuildContext context) async {
    try {
      await ApiService.removeFromWishlist(productId);
      final updated = List<Map<String, dynamic>>.from(state.wishlist)
        ..removeWhere(
          (p) => (_extractProductId(p)?.toString() ?? '') == productId,
        );
      state = state.copyWith(wishlist: updated);
      _showSuccess(context, "Removed from wishlist");
    } catch (_) {
      _showError(
        context,
        "Unable to remove item. Please check your connection.",
      );
    }
  }

  int? _extractProductId(Map<String, dynamic> item) {
    final product =
        (item['product'] is Map)
            ? Map<String, dynamic>.from(item['product'])
            : null;
    final dynamic idRaw = item['product_id'] ?? product?['id'] ?? item['id'];
    if (idRaw is int) return idRaw;
    if (idRaw is String) return int.tryParse(idRaw);
    if (idRaw is num) return idRaw.toInt();
    return null;
  }

  Product toProduct(Map<String, dynamic> item) {
    final productMap =
        (item['product'] is Map)
            ? Map<String, dynamic>.from(item['product'])
            : <String, dynamic>{};
    if (productMap.isNotEmpty) {
      try {
        return Product.fromJson(productMap);
      } catch (_) {}
    }
    final modelMap =
        (item['model'] is Map)
            ? Map<String, dynamic>.from(item['model'])
            : null;
    final id = _extractProductId(item) ?? 0;
    final name =
        (item['name'] ?? productMap['product_name'] ?? 'Unknown Product')
            .toString();
    final brand =
        (productMap['brand_name'] ?? item['brand_name'] ?? '').toString();
    final image = (item['image_url'] ?? productMap['image'])?.toString();
    final discountRaw = productMap['discount'];
    final discount =
        discountRaw is num
            ? discountRaw.clamp(0, 100).toInt()
            : (discountRaw is String
                ? (int.tryParse(discountRaw) ?? 0).clamp(0, 100)
                : 0);
    final newStock =
        (() {
          final v = productMap['new_stock'];
          if (v is bool) return v;
          if (v is num) return v != 0;
          if (v is String) {
            final s = v.toLowerCase();
            return s == 'true' || s == '1' || s == 'yes';
          }
          return false;
        })();

    final List<ProductModel> models = [];
    if (modelMap != null) {
      models.add(ProductModel.fromJson(modelMap));
    } else {
      models.add(
        ProductModel(
          id: id,
          modelName: 'Default',
          price:
              (item['price'] is num)
                  ? (item['price'] as num).toDouble()
                  : double.tryParse(item['price']?.toString() ?? '0') ?? 0.0,
          stock: 1,
          colors: item['color']?.toString(),
          images: [(item['image_url'] ?? '').toString()],
        ),
      );
    }

    return Product(
      id: id,
      productName: name,
      brandName: brand,
      description: null,
      specification: null,
      image: image,
      discount: discount,
      newStock: newStock,
      createdAt: null,
      models: models,
      categoryName: null,
    );
  }

  void _showSuccess(BuildContext context, String msg) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? Colors.white : Colors.black;
    final fg = isDark ? Colors.black : Colors.white;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: bg,
        content: Row(
          children: [
            Icon(Icons.check_circle, color: fg),
            const SizedBox(width: 12),
            Expanded(child: Text(msg, style: TextStyle(color: fg))),
          ],
        ),
      ),
    );
  }

  void _showError(BuildContext context, String msg) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: cs.error,
        content: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(msg, style: TextStyle(color: cs.onError))),
          ],
        ),
      ),
    );
  }
}

final wishlistProvider = StateNotifierProvider<WishlistNotifier, WishlistState>(
  (ref) => WishlistNotifier(),
);

class WishlistPage extends ConsumerWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wishlistProvider);
    final notifier = ref.read(wishlistProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    if (state.loading) {
      return Scaffold(
        backgroundColor: scheme.background,
        appBar: _wishlistAppBar(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return Scaffold(
        backgroundColor: scheme.background,
        appBar: _wishlistAppBar(context),
        body: _buildErrorState(context, notifier),
      );
    }

    if (state.wishlist.isEmpty) {
      return Scaffold(
        backgroundColor: scheme.background,
        appBar: _wishlistAppBar(context),
        body: _buildEmptyState(context),
      );
    }

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: _wishlistAppBar(context),
      body: _WishlistBody(
        products: state.wishlist.map(notifier.toProduct).toList(),
      ),
    );
  }

  PreferredSizeWidget _wishlistAppBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppBar(
      title: const Text(
        'Wish List',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      backgroundColor: scheme.background,
      foregroundColor: scheme.onBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    );
  }

  Widget _buildErrorState(BuildContext context, WishlistNotifier notifier) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? Colors.red[900]?.withOpacity(0.15) : Colors.red[50];
    final fg = isDark ? Colors.red[100] : Colors.red[700];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color:
                  isDark ? Colors.red[900]?.withOpacity(0.25) : Colors.red[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.wifi_off_rounded, size: 64, color: fg),
          ),
          const SizedBox(height: 16),
          Text(
            "Connection Issue",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Unable to load your wish list. Please check your internet connection and try again.",
            style: theme.textTheme.bodyMedium?.copyWith(color: fg),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              notifier.loadWishlist();
            },
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0479FF),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              "Your wish list is empty",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Start saving your favorite items!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Start Shopping"),
            ),
          ],
        ),
      ),
    );
  }
}

class _WishlistBody extends ConsumerWidget {
  const _WishlistBody({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orientation = MediaQuery.of(context).orientation;
    return orientation == Orientation.landscape
        ? _buildLandscapeWishlistBody(context, ref)
        : _buildPortraitWishlistBody(context, ref);
  }

  Widget _buildPortraitWishlistBody(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(wishlistProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () => notifier.loadWishlist(),
        edgeOffset: 0,
        color: isDark ? Colors.white : Colors.black,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _wishlistInfoSection(context),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate((context, i) {
                  final p = products[i];
                  return ProductCard(product: p);
                }, childCount: products.length),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeWishlistBody(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(wishlistProvider.notifier);
    final double w = MediaQuery.of(context).size.width;
    final bool isWide = w >= 1000;
    final rightMaxWidth = isWide ? 420.0 : 360.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SafeArea(
          top: false,
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _section(
                        context: context,
                        title: 'Saved Items',
                        child: Text(
                          'Quickly browse and manage the products you’ve saved for later.',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onBackground.withOpacity(0.85),
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () => notifier.loadWishlist(),
                          color: isDark ? Colors.white : Colors.black,
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                          child: _wishlistGrid(products),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: rightMaxWidth),
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: ScrollConfiguration(
                      behavior: const ScrollBehavior().copyWith(
                        overscroll: false,
                      ),
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [_wishlistInfoSection(context)],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _wishlistGrid(List<Product> products) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, i) {
        final p = products[i];
        return ProductCard(product: p);
      },
    );
  }

  Widget _wishlistInfoSection(BuildContext context) {
    return _section(
      context: context,
      title: 'Your Personal Wish List',
      child: Text(
        'Save products you love and easily find them later. Your wish list helps you keep track of favorites and plan future purchases. Items are saved privately and can be accessed anytime.',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.85),
          height: 1.35,
        ),
      ),
    );
  }

  Widget _section({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
