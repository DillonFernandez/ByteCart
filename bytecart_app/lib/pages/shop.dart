import 'package:flutter/material.dart';

import '../models/filter.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/filter.dart'; // NEW: use ShopInlineFilters + FilterUtils
import '../widgets/productcard.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({
    super.key,
    this.initialFilter, // NEW
  });

  // NEW: optional initial filter (e.g., coming from Home "Shop by Category")
  final ShopFilter? initialFilter;

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late Future<List<Product>> _futureProducts;

  // REMOVED: AnimationController/_filterSlideAnimation and price controllers

  // Pagination state
  final int _pageSize = 28;
  List<Product> _allProducts = const [];
  int _visibleCount = 0;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  bool _initialized = false;
  late final ScrollController _scrollController;

  // Filters state
  ShopFilter _filters = ShopFilter();

  // NEW: key for inline filter section + pending scroll flags
  final GlobalKey _filterSectionKey = GlobalKey();
  bool _pendingScrollPageTop = false;
  bool _pendingScrollFilterTop = false;

  // NEW: keep a cache of the initially fetched list
  List<Product> _originalProducts = const [];

  @override
  void initState() {
    super.initState();
    // NEW: seed filters from initialFilter if provided
    _filters = widget.initialFilter ?? ShopFilter();

    bool _hasAnyFilter(ShopFilter f) =>
        f.sort.isNotEmpty ||
        f.category.isNotEmpty ||
        f.brand.isNotEmpty ||
        f.color.isNotEmpty ||
        f.minPrice != null ||
        f.maxPrice != null ||
        f.inStock;

    // If initial filter is present, load filtered; otherwise load all
    _futureProducts =
        _hasAnyFilter(_filters)
            ? ApiService.getFilteredProducts(_filters)
            : ApiService.getProducts();

    _scrollController = ScrollController()..addListener(_onScroll);
    // If deep-linked with a filter, scroll to top after first build
    if (widget.initialFilter != null) {
      _pendingScrollPageTop = true; // NEW: start at top
      _pendingScrollFilterTop = false; // NEW: do not target filter row
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    // REMOVED: _min/_max controllers dispose and animation dispose
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore) return;
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 100) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    await Future.delayed(const Duration(milliseconds: 400));
    final int nextCount =
        (_visibleCount + _pageSize) > _allProducts.length
            ? _allProducts.length
            : (_visibleCount + _pageSize);
    setState(() {
      _visibleCount = nextCount;
      _isLoadingMore = false;
      _hasMore = _visibleCount < _allProducts.length;
    });
  }

  // Apply filters against cached products to avoid API errors
  void _applyFilters(ShopFilter newFilters) {
    setState(() {
      _filters = newFilters;
      _futureProducts = ApiService.getFilteredProducts(_filters);
      _initialized = false;
      _pendingScrollPageTop =
          true; // NEW: always jump to top after applying filters
    });
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Promotional Banner
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

  // REMOVED: _buildFilterSection, _buildInlineFilters, _showChipSheet, _showSortSheet, _showPriceSheet, _buildChip, _buildSortTile

  // REMOVED: _filterAndSort and _minModelPrice, now using FilterUtils

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<Product>>(
          future: _futureProducts,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(Color(0xFF0479FF)),
                ),
              );
            } else if (snapshot.hasError) {
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
                      "Something went wrong",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      // ApiException.toString() already returns the message
                      "Error: ${snapshot.error}",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.red.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _initialized = false;
                          _futureProducts = ApiService.getProducts();
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retry"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0479FF),
                        foregroundColor: Colors.white,
                        elevation: 0, // Remove shadow
                      ),
                    ),
                  ],
                ),
              );
            }

            if (!_initialized) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  final List<Product> data = snapshot.data ?? const [];
                  if (_originalProducts.isEmpty) {
                    _originalProducts = data;
                  }
                  // Ensure client-side filter + sort always applied
                  final filtered = FilterUtils.filterAndSort(data, _filters);
                  _allProducts = filtered;
                  _visibleCount =
                      _allProducts.length < _pageSize
                          ? _allProducts.length
                          : _pageSize;
                  _hasMore = _visibleCount < _allProducts.length;
                  _initialized = true;
                });

                // After initialized content is laid out, perform the pending scroll
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_pendingScrollPageTop && _scrollController.hasClients) {
                    _pendingScrollPageTop = false;
                    _pendingScrollFilterTop = false;
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                    );
                  } else if (_pendingScrollFilterTop) {
                    _pendingScrollFilterTop = false;
                    final ctx = _filterSectionKey.currentContext;
                    if (ctx != null) {
                      Scrollable.ensureVisible(
                        ctx,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        alignment: 0.0, // top of viewport
                      );
                    }
                  }
                });
              });
              return const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(Color(0xFF0479FF)),
                ),
              );
            }

            // Wrap the content in a RefreshIndicator to manually retry fetches
            return RefreshIndicator(
              onRefresh: () async {
                // CHANGED: fetch fresh data and update state without triggering full-page loader
                final fresh = await ApiService.getProducts();
                final filtered = FilterUtils.filterAndSort(
                  fresh,
                  _filters,
                ); // CHANGED
                setState(() {
                  _originalProducts = fresh;
                  _allProducts = filtered;
                  _visibleCount =
                      _allProducts.length < _pageSize
                          ? _allProducts.length
                          : _pageSize;
                  _hasMore = _visibleCount < _allProducts.length;
                  // Do NOT touch _futureProducts or _initialized to avoid center loader
                });
              },
              edgeOffset: 16,
              color: const Color(0xFF0479FF),
              // spinner color
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              // circle bg
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header
                  SliverToBoxAdapter(child: _buildHeader(context)),
                  // Spacing after header
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  // Inline filters
                  SliverToBoxAdapter(
                    child: ShopInlineFilters(
                      key: _filterSectionKey,
                      filters: _filters,
                      onApply: _applyFilters,
                      sourceProducts:
                          _originalProducts.isNotEmpty
                              ? _originalProducts
                              : _allProducts,
                    ),
                  ),
                  // Spacing after filters
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // CHANGED: show empty-state message when there are no products,
                  // otherwise show the products grid
                  if (_allProducts.isEmpty)
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
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final product = _allProducts[index];
                        return ProductCard(product: product);
                      }, childCount: _visibleCount),
                    ),

                  if (_isLoadingMore)
                    SliverToBoxAdapter(child: _buildLoadingIndicator()),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
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
}
