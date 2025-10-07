import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/filter.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/productcard.dart';
import '../widgets/filter.dart';

class ShopState {
  final List<Product> allProducts;
  final List<Product> originalProducts;
  final int visibleCount;
  final bool isLoadingMore;
  final bool hasMore;
  final bool initialized;
  final ShopFilter filters;
  final AsyncValue<List<Product>> asyncProducts;

  ShopState({
    this.allProducts = const [],
    this.originalProducts = const [],
    this.visibleCount = 0,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.initialized = false,
    ShopFilter? filters,
    this.asyncProducts = const AsyncLoading(),
  }) : filters = filters ?? ShopFilter();

  ShopState copyWith({
    List<Product>? allProducts,
    List<Product>? originalProducts,
    int? visibleCount,
    bool? isLoadingMore,
    bool? hasMore,
    bool? initialized,
    ShopFilter? filters,
    AsyncValue<List<Product>>? asyncProducts,
  }) {
    return ShopState(
      allProducts: allProducts ?? this.allProducts,
      originalProducts: originalProducts ?? this.originalProducts,
      visibleCount: visibleCount ?? this.visibleCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      initialized: initialized ?? this.initialized,
      filters: filters ?? this.filters,
      asyncProducts: asyncProducts ?? this.asyncProducts,
    );
  }
}

class ShopNotifier extends StateNotifier<ShopState> {
  ShopNotifier({ShopFilter? initialFilter})
    : super(ShopState(filters: initialFilter ?? ShopFilter())) {
    _fetchProducts();
  }

  static const int _pageSize = 28;

  Future<void> _fetchProducts({bool filtered = false}) async {
    state = state.copyWith(
      asyncProducts: const AsyncLoading(),
      initialized: false,
    );
    try {
      final products =
          filtered
              ? await ApiService.getFilteredProducts(state.filters)
              : await ApiService.getProducts();
      final filteredList = FilterUtils.filterAndSort(products, state.filters);
      state = state.copyWith(
        originalProducts: products,
        allProducts: filteredList,
        visibleCount:
            filteredList.length < _pageSize ? filteredList.length : _pageSize,
        hasMore: filteredList.length > _pageSize,
        initialized: true,
        asyncProducts: AsyncData(products),
      );
    } catch (e, st) {
      state = state.copyWith(
        asyncProducts: AsyncError(e, st),
        initialized: false,
      );
    }
  }

  Future<void> refresh() async {
    await _fetchProducts(filtered: false);
  }

  Future<void> applyFilters(ShopFilter newFilters) async {
    state = state.copyWith(filters: newFilters, initialized: false);
    await _fetchProducts(filtered: true);
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    await Future.delayed(const Duration(milliseconds: 400));
    final int nextCount =
        (state.visibleCount + _pageSize) > state.allProducts.length
            ? state.allProducts.length
            : (state.visibleCount + _pageSize);
    state = state.copyWith(
      visibleCount: nextCount,
      isLoadingMore: false,
      hasMore: nextCount < state.allProducts.length,
    );
  }
}

final shopProvider = StateNotifierProvider.autoDispose
    .family<ShopNotifier, ShopState, ShopFilter?>(
      (ref, initialFilter) => ShopNotifier(initialFilter: initialFilter),
    );

final shopScrollControllerProvider = Provider.autoDispose<ScrollController>((
  ref,
) {
  final controller = ScrollController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

class ShopPage extends ConsumerWidget {
  const ShopPage({super.key, this.initialFilter});

  final ShopFilter? initialFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body:
          isLandscape
              ? _ShopLandscapeBody(initialFilter: initialFilter)
              : _ShopPortraitBody(initialFilter: initialFilter),
    );
  }
}

class _ShopPortraitBody extends ConsumerStatefulWidget {
  const _ShopPortraitBody({this.initialFilter});

  final ShopFilter? initialFilter;

  @override
  ConsumerState<_ShopPortraitBody> createState() => _ShopPortraitBodyState();
}

class _ShopPortraitBodyState extends ConsumerState<_ShopPortraitBody> {
  final GlobalKey _filterSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shopProvider(widget.initialFilter));
    final shopNotifier = ref.read(shopProvider(widget.initialFilter).notifier);
    final scrollController = ref.watch(shopScrollControllerProvider);

    scrollController.addListener(() {
      if (!shopState.hasMore || shopState.isLoadingMore) return;
      if (!scrollController.hasClients) return;
      final pos = scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent - 100) {
        shopNotifier.loadMore();
      }
    });

    return Padding(
      padding: const EdgeInsets.all(16),
      child: shopState.asyncProducts.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(Color(0xFF0479FF)),
              ),
            ),
        error: (error, _) => _buildErrorState(context, shopNotifier),
        data: (_) {
          if (!shopState.initialized) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(Color(0xFF0479FF)),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => shopNotifier.refresh(),
            edgeOffset: 16,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            child: CustomScrollView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(
                  child: ShopInlineFilters(
                    key: _filterSectionKey,
                    filters: shopState.filters,
                    onApply: shopNotifier.applyFilters,
                    sourceProducts:
                        shopState.originalProducts.isNotEmpty
                            ? shopState.originalProducts
                            : shopState.allProducts,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                if (shopState.allProducts.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 64,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No products found",
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Try adjusting your filters",
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey.withOpacity(0.7)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = shopState.allProducts[index];
                      return ProductCard(product: product);
                    }, childCount: shopState.visibleCount),
                  ),
                if (shopState.isLoadingMore)
                  SliverToBoxAdapter(child: _buildLoadingIndicator(context)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ShopLandscapeBody extends ConsumerStatefulWidget {
  const _ShopLandscapeBody({this.initialFilter});

  final ShopFilter? initialFilter;

  @override
  ConsumerState<_ShopLandscapeBody> createState() => _ShopLandscapeBodyState();
}

class _ShopLandscapeBodyState extends ConsumerState<_ShopLandscapeBody> {
  final GlobalKey _filterSectionKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shopProvider(widget.initialFilter));
    final shopNotifier = ref.read(shopProvider(widget.initialFilter).notifier);
    final scrollController = ref.watch(shopScrollControllerProvider);

    scrollController.addListener(() {
      if (!shopState.hasMore || shopState.isLoadingMore) return;
      if (!scrollController.hasClients) return;
      final pos = scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent - 100) {
        shopNotifier.loadMore();
      }
    });

    return Padding(
      padding: const EdgeInsets.all(16),
      child: shopState.asyncProducts.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(Color(0xFF0479FF)),
              ),
            ),
        error: (error, _) => _buildErrorState(context, shopNotifier),
        data: (_) {
          if (!shopState.initialized) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(Color(0xFF0479FF)),
              ),
            );
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              const gap = 24.0;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 9,
                    child: LayoutBuilder(
                      builder: (context, leftCons) {
                        return SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeader(context),
                              const SizedBox(height: 16),
                              ShopInlineFilters(
                                key: _filterSectionKey,
                                filters: shopState.filters,
                                onApply: shopNotifier.applyFilters,
                                sourceProducts:
                                    shopState.originalProducts.isNotEmpty
                                        ? shopState.originalProducts
                                        : shopState.allProducts,
                                landscape: true,
                                maxWidth: leftCons.maxWidth,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: gap),
                  Expanded(
                    flex: 11,
                    child: RefreshIndicator(
                      onRefresh: () => shopNotifier.refresh(),
                      edgeOffset: 16,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                      child: LayoutBuilder(
                        builder: (context, rightCons) {
                          int cols;
                          if (rightCons.maxWidth >= 1200) {
                            cols = 4;
                          } else if (rightCons.maxWidth >= 900) {
                            cols = 3;
                          } else {
                            cols = 2;
                          }
                          return CustomScrollView(
                            controller: scrollController,
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              if (shopState.allProducts.isEmpty)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 48,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.shopping_bag_outlined,
                                          size: 64,
                                          color: Colors.grey.withOpacity(0.5),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          "No products found",
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "Try adjusting your filters",
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.copyWith(
                                            color: Colors.grey.withOpacity(0.7),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                SliverGrid(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: cols,
                                        childAspectRatio: 0.65,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                      ),
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final product =
                                        shopState.allProducts[index];
                                    return ProductCard(product: product);
                                  }, childCount: shopState.visibleCount),
                                ),
                              if (shopState.isLoadingMore)
                                SliverToBoxAdapter(
                                  child: _buildLoadingIndicator(context),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

Widget _buildHeader(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0479FF).withOpacity(0.1),
              const Color(0xFF0479FF).withOpacity(0.05),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF0479FF).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0479FF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_offer_outlined,
                color: Color(0xFF0479FF),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shop at ByteCart, byte by byte',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0479FF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Discover gadgets, gear, and everyday essentials tailored to you.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white70 : Colors.black54,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildErrorState(BuildContext context, ShopNotifier notifier) {
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
          "Unable to load products. Please check your internet connection and try again.",
          style: theme.textTheme.bodyMedium?.copyWith(color: fg),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            notifier.refresh();
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

Widget _buildLoadingIndicator(BuildContext context) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 20),
    child: Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading more products...',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
