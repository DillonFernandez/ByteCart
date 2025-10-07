import 'package:flutter/material.dart';

import '../models/filter.dart';
import '../models/product.dart';

class FilterUtils {
  static List<Product> filterAndSort(List<Product> items, ShopFilter f) {
    Iterable<Product> result = items;
    String norm(String s) => s.toLowerCase();

    if (f.category.isNotEmpty) {
      final q = norm(f.category);
      result = result.where(
        (p) => (p.categoryName ?? '').toLowerCase().contains(q),
      );
    }
    if (f.brand.isNotEmpty) {
      final q = norm(f.brand);
      result = result.where((p) => p.brandName.toLowerCase().contains(q));
    }
    if (f.color.isNotEmpty) {
      final q = norm(f.color);
      result = result.where(
        (p) => p.models.any(
          (m) => m.colorList.any((c) {
            final lc = c.toLowerCase();
            return lc == q || lc.contains(q);
          }),
        ),
      );
    }
    if (f.inStock) {
      result = result.where((p) => p.models.any((m) => m.stock > 0));
    }
    if (f.minPrice != null || f.maxPrice != null) {
      final minP = f.minPrice ?? double.negativeInfinity;
      final maxP = f.maxPrice ?? double.infinity;
      result = result.where(
        (p) => p.models.any((m) => m.price >= minP && m.price <= maxP),
      );
    }

    final list = result.toList();
    switch (f.sort) {
      case 'price_asc':
        list.sort((a, b) => _minModelPrice(a).compareTo(_minModelPrice(b)));
        break;
      case 'price_desc':
        list.sort((a, b) => _minModelPrice(b).compareTo(_minModelPrice(a)));
        break;
      case 'name_asc':
        list.sort(
          (a, b) => a.productName.toLowerCase().compareTo(
            b.productName.toLowerCase(),
          ),
        );
        break;
      case 'name_desc':
        list.sort(
          (a, b) => b.productName.toLowerCase().compareTo(
            a.productName.toLowerCase(),
          ),
        );
        break;
      case 'newest':
        list.sort(
          (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
        );
        break;
      case 'oldest':
        list.sort(
          (a, b) => (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
        );
        break;
      default:
        break;
    }
    return list;
  }

  static double _minModelPrice(Product p) {
    if (p.models.isEmpty) return double.infinity;
    double minPrice = p.models.first.price;
    for (final m in p.models) {
      if (m.price < minPrice) minPrice = m.price;
    }
    return minPrice;
  }
}

class ShopInlineFilters extends StatefulWidget {
  final ShopFilter filters;
  final ValueChanged<ShopFilter> onApply;
  final List<Product> sourceProducts;

  final bool landscape;
  final double? maxWidth;

  const ShopInlineFilters({
    super.key,
    required this.filters,
    required this.onApply,
    required this.sourceProducts,
    this.landscape = false,
    this.maxWidth,
  });

  @override
  State<ShopInlineFilters> createState() => _ShopInlineFiltersState();
}

class _ShopInlineFiltersState extends State<ShopInlineFilters>
    with TickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Set<String> catSet = {};
    final Set<String> brandSet = {};
    final Set<String> colorSet = {};
    for (final p in widget.sourceProducts) {
      final cat = (p.categoryName ?? '').trim();
      if (cat.isNotEmpty) catSet.add(cat);
      final brand = p.brandName.trim();
      if (brand.isNotEmpty) brandSet.add(brand);
      for (final m in p.models) {
        for (final c in m.colorList) {
          final lc = c.trim();
          if (lc.isNotEmpty) colorSet.add(lc);
        }
      }
    }
    final categories =
        catSet.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final brands =
        brandSet.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final colors =
        colorSet.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1.0, 0.0),
        end: Offset.zero,
      ).animate(_slideAnim),
      child: FadeTransition(
        opacity: _slideAnim,
        child: _buildInlineFilters(context, isDark, categories, brands, colors),
      ),
    );
  }

  Widget _buildInlineFilters(
    BuildContext context,
    bool isDark,
    List<String> categories,
    List<String> brands,
    List<String> colors,
  ) {
    final theme = Theme.of(context);

    final Color cardBg = isDark ? (Colors.grey[900]!) : (Colors.grey[100]!);
    final Color tileText = isDark ? Colors.white : Colors.black87;
    final Color subtitleText = isDark ? Colors.white60 : Colors.black54;
    const Color kMain = Color(0xFF0479FF);

    double _tileWidth(double maxWidth) {
      const spacing = 12.0;
      if (maxWidth < 360) return maxWidth;
      if (maxWidth < 760) return (maxWidth - spacing) / 2;
      return (maxWidth - spacing) / 2;
    }

    Widget tile({
      required IconData icon,
      required String title,
      required String value,
      required VoidCallback onTap,
      double? width,
    }) {
      return TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 200),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, animation, child) {
          return Transform.scale(
            scale: 0.95 + (0.05 * animation),
            child: Opacity(
              opacity: animation,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
                  enableFeedback: false,
                  child: Container(
                    width: width ?? 180,
                    height: 64,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    margin: const EdgeInsets.only(right: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                kMain.withOpacity(0.1),
                                kMain.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, size: 18, color: kMain),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: tileText,
                                ),
                              ),
                              Text(
                                value.isEmpty ? 'All' : value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: subtitleText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_right,
                          size: 18,
                          color: kMain.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    String sortLabel(String key) {
      switch (key) {
        case 'price_asc':
          return 'Price: Low to High';
        case 'price_desc':
          return 'Price: High to Low';
        case 'name_asc':
          return 'Name: A–Z';
        case 'name_desc':
          return 'Name: Z–A';
        case 'newest':
          return 'Newest';
        case 'oldest':
          return 'Oldest';
        default:
          return 'Default';
      }
    }

    String priceSummary() {
      final parts = <String>[];
      if (widget.filters.minPrice != null)
        parts.add('${widget.filters.minPrice!.toStringAsFixed(0)}+');
      if (widget.filters.maxPrice != null) {
        if (parts.isEmpty) {
          parts.add('<= ${widget.filters.maxPrice!.toStringAsFixed(0)}');
        } else {
          parts.clear();
          parts.add(
            '${widget.filters.minPrice!.toStringAsFixed(0)} - ${widget.filters.maxPrice!.toStringAsFixed(0)}',
          );
        }
      }
      final range = parts.isEmpty ? 'Any' : parts.join();
      final stock = widget.filters.inStock ? ' • In Stock' : '';
      return '$range$stock';
    }

    if (widget.landscape) {
      return LayoutBuilder(
        builder: (context, cons) {
          final maxW = widget.maxWidth ?? cons.maxWidth;
          final w = _tileWidth(maxW);
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              tile(
                icon: Icons.tune,
                title: 'Sort',
                value: sortLabel(widget.filters.sort),
                onTap: () => _showSortSheet(context),
                width: w,
              ),
              tile(
                icon: Icons.category_outlined,
                title: 'Category',
                value: widget.filters.category,
                onTap:
                    () => _showChipSheet(
                      context: context,
                      title: 'Categories',
                      options: categories,
                      selected: widget.filters.category,
                      onSelected:
                          (val) => widget.onApply(
                            ShopFilter(
                              sort: widget.filters.sort,
                              category: val,
                              brand: widget.filters.brand,
                              color: widget.filters.color,
                              minPrice: widget.filters.minPrice,
                              maxPrice: widget.filters.maxPrice,
                              inStock: widget.filters.inStock,
                            ),
                          ),
                      limitRows: true,
                    ),
                width: w,
              ),
              tile(
                icon: Icons.branding_watermark_outlined,
                title: 'Brand',
                value: widget.filters.brand,
                onTap:
                    () => _showChipSheet(
                      context: context,
                      title: 'Brands',
                      options: brands,
                      selected: widget.filters.brand,
                      onSelected:
                          (val) => widget.onApply(
                            ShopFilter(
                              sort: widget.filters.sort,
                              category: widget.filters.category,
                              brand: val,
                              color: widget.filters.color,
                              minPrice: widget.filters.minPrice,
                              maxPrice: widget.filters.maxPrice,
                              inStock: widget.filters.inStock,
                            ),
                          ),
                      limitRows: true,
                    ),
                width: w,
              ),
              tile(
                icon: Icons.palette_outlined,
                title: 'Color',
                value: widget.filters.color,
                onTap:
                    () => _showChipSheet(
                      context: context,
                      title: 'Colors',
                      options: colors,
                      selected: widget.filters.color,
                      onSelected:
                          (val) => widget.onApply(
                            ShopFilter(
                              sort: widget.filters.sort,
                              category: widget.filters.category,
                              brand: widget.filters.brand,
                              color: val,
                              minPrice: widget.filters.minPrice,
                              maxPrice: widget.filters.maxPrice,
                              inStock: widget.filters.inStock,
                            ),
                          ),
                      limitRows: true,
                    ),
                width: w,
              ),
              tile(
                icon: Icons.monetization_on_outlined,
                title: 'Price & Stock',
                value: priceSummary(),
                onTap: () => _showPriceSheet(context),
                width: w,
              ),
            ],
          );
        },
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 4),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          tile(
            icon: Icons.tune,
            title: 'Sort',
            value: sortLabel(widget.filters.sort),
            onTap: () => _showSortSheet(context),
          ),
          tile(
            icon: Icons.category_outlined,
            title: 'Category',
            value: widget.filters.category,
            onTap:
                () => _showChipSheet(
                  context: context,
                  title: 'Categories',
                  options: categories,
                  selected: widget.filters.category,
                  onSelected:
                      (val) => widget.onApply(
                        ShopFilter(
                          sort: widget.filters.sort,
                          category: val,
                          brand: widget.filters.brand,
                          color: widget.filters.color,
                          minPrice: widget.filters.minPrice,
                          maxPrice: widget.filters.maxPrice,
                          inStock: widget.filters.inStock,
                        ),
                      ),
                  limitRows: true,
                ),
          ),
          tile(
            icon: Icons.branding_watermark_outlined,
            title: 'Brand',
            value: widget.filters.brand,
            onTap:
                () => _showChipSheet(
                  context: context,
                  title: 'Brands',
                  options: brands,
                  selected: widget.filters.brand,
                  onSelected:
                      (val) => widget.onApply(
                        ShopFilter(
                          sort: widget.filters.sort,
                          category: widget.filters.category,
                          brand: val,
                          color: widget.filters.color,
                          minPrice: widget.filters.minPrice,
                          maxPrice: widget.filters.maxPrice,
                          inStock: widget.filters.inStock,
                        ),
                      ),
                  limitRows: true,
                ),
          ),
          tile(
            icon: Icons.palette_outlined,
            title: 'Color',
            value: widget.filters.color,
            onTap:
                () => _showChipSheet(
                  context: context,
                  title: 'Colors',
                  options: colors,
                  selected: widget.filters.color,
                  onSelected:
                      (val) => widget.onApply(
                        ShopFilter(
                          sort: widget.filters.sort,
                          category: widget.filters.category,
                          brand: widget.filters.brand,
                          color: val,
                          minPrice: widget.filters.minPrice,
                          maxPrice: widget.filters.maxPrice,
                          inStock: widget.filters.inStock,
                        ),
                      ),
                  limitRows: true,
                ),
          ),
          tile(
            icon: Icons.monetization_on_outlined,
            title: 'Price & Stock',
            value: priceSummary(),
            onTap: () => _showPriceSheet(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showChipSheet({
    required BuildContext context,
    required String title,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
    bool limitRows = false,
  }) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color sheetText = isDark ? Colors.white : Colors.black87;

    String norm(String s) => s.toLowerCase();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        String temp = selected;

        Widget buildChips(void Function(void Function()) setModalState) {
          final chips = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildChip(
                label: 'All',
                selected: temp.isEmpty,
                isDark: isDark,
                onTap: () => setModalState(() => temp = ''),
              ),
              for (final opt in options)
                _buildChip(
                  label: opt,
                  selected: norm(temp) == norm(opt),
                  isDark: isDark,
                  onTap:
                      () => setModalState(
                        () => temp = (norm(temp) == norm(opt)) ? '' : opt,
                      ),
                ),
            ],
          );

          return limitRows
              ? SizedBox(
                height: 50.0 * 5,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: chips,
                ),
              )
              : chips;
        }

        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: sheetText,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            color: sheetText,
                            onPressed: () => Navigator.pop(context),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  isDark ? Colors.grey[800] : Colors.grey[100],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      buildChips(setModalState),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                onSelected('');
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                foregroundColor:
                                    isDark ? Colors.white : Colors.black,
                              ),
                              child: const Text('Clear'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                onSelected(temp);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: const Color(0xFF0479FF),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSortSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color sheetText = isDark ? Colors.white : Colors.black87;
    String? temp = widget.filters.sort.isEmpty ? null : widget.filters.sort;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Text(
                              'Sort By',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: sheetText,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close),
                              color: sheetText,
                              onPressed: () => Navigator.pop(context),
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[100],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildSortTile(
                          'price_asc',
                          'Price: Low to High',
                          temp,
                          (v) => setModalState(() => temp = v),
                        ),
                        _buildSortTile(
                          'price_desc',
                          'Price: High to Low',
                          temp,
                          (v) => setModalState(() => temp = v),
                        ),
                        _buildSortTile(
                          'name_asc',
                          'Name: A–Z',
                          temp,
                          (v) => setModalState(() => temp = v),
                        ),
                        _buildSortTile(
                          'name_desc',
                          'Name: Z–A',
                          temp,
                          (v) => setModalState(() => temp = v),
                        ),
                        _buildSortTile(
                          'newest',
                          'Newest',
                          temp,
                          (v) => setModalState(() => temp = v),
                        ),
                        _buildSortTile(
                          'oldest',
                          'Oldest',
                          temp,
                          (v) => setModalState(() => temp = v),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setModalState(() => temp = null);
                                  widget.onApply(
                                    ShopFilter(
                                      sort: '',
                                      category: widget.filters.category,
                                      brand: widget.filters.brand,
                                      color: widget.filters.color,
                                      minPrice: widget.filters.minPrice,
                                      maxPrice: widget.filters.maxPrice,
                                      inStock: widget.filters.inStock,
                                    ),
                                  );
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  foregroundColor:
                                      isDark ? Colors.white : Colors.black,
                                ),
                                child: const Text('Clear'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  widget.onApply(
                                    ShopFilter(
                                      sort: temp ?? '',
                                      category: widget.filters.category,
                                      brand: widget.filters.brand,
                                      color: widget.filters.color,
                                      minPrice: widget.filters.minPrice,
                                      maxPrice: widget.filters.maxPrice,
                                      inStock: widget.filters.inStock,
                                    ),
                                  );
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  backgroundColor: const Color(0xFF0479FF),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Apply'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPriceSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color sheetText = isDark ? Colors.white : Colors.black87;
    final minCtrl = TextEditingController(
      text: widget.filters.minPrice?.toString() ?? '',
    );
    final maxCtrl = TextEditingController(
      text: widget.filters.maxPrice?.toString() ?? '',
    );
    bool inStock = widget.filters.inStock;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            'Price & Availability',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: sheetText,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            color: sheetText,
                            onPressed: () => Navigator.pop(context),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  isDark ? Colors.grey[800] : Colors.grey[100],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: minCtrl,
                              decoration: InputDecoration(
                                labelText: 'Min Price',
                                labelStyle: TextStyle(color: sheetText),
                                floatingLabelStyle: TextStyle(color: sheetText),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color:
                                        isDark
                                            ? Colors.grey[700]!
                                            : Colors.grey[300]!,
                                    width: 2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color:
                                        isDark
                                            ? Colors.grey[700]!
                                            : Colors.grey[300]!,
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: const Icon(
                                  Icons.arrow_downward,
                                  size: 18,
                                ),
                                filled: true,
                                fillColor:
                                    isDark
                                        ? Colors.grey[800]?.withOpacity(0.3)
                                        : Colors.grey[50],
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: maxCtrl,
                              decoration: InputDecoration(
                                labelText: 'Max Price',
                                labelStyle: TextStyle(color: sheetText),
                                floatingLabelStyle: TextStyle(color: sheetText),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color:
                                        isDark
                                            ? Colors.grey[700]!
                                            : Colors.grey[300]!,
                                    width: 2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color:
                                        isDark
                                            ? Colors.grey[700]!
                                            : Colors.grey[300]!,
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: const Icon(
                                  Icons.arrow_upward,
                                  size: 18,
                                ),
                                filled: true,
                                fillColor:
                                    isDark
                                        ? Colors.grey[800]?.withOpacity(0.3)
                                        : Colors.grey[50],
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? Colors.grey[800]?.withOpacity(0.3)
                                  : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isDark ? Colors.grey[700]! : Colors.grey[200]!,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              color: sheetText,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'In Stock Only',
                                style: TextStyle(
                                  color: sheetText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Switch(
                              value: inStock,
                              onChanged:
                                  (v) => setModalState(() => inStock = v),
                              activeColor: const Color(0xFF0479FF),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                widget.onApply(
                                  ShopFilter(
                                    sort: widget.filters.sort,
                                    category: widget.filters.category,
                                    brand: widget.filters.brand,
                                    color: widget.filters.color,
                                    minPrice: null,
                                    maxPrice: null,
                                    inStock: false,
                                  ),
                                );
                                Navigator.pop(context);
                              },
                              child: const Text('Clear'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                foregroundColor:
                                    isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                final min = double.tryParse(
                                  minCtrl.text.trim(),
                                );
                                final max = double.tryParse(
                                  maxCtrl.text.trim(),
                                );
                                double? finalMin = min, finalMax = max;
                                if (finalMin != null &&
                                    finalMax != null &&
                                    finalMin > finalMax) {
                                  final tmp = finalMin;
                                  finalMin = finalMax;
                                  finalMax = tmp;
                                }
                                widget.onApply(
                                  ShopFilter(
                                    sort: widget.filters.sort,
                                    category: widget.filters.category,
                                    brand: widget.filters.brand,
                                    color: widget.filters.color,
                                    minPrice: finalMin,
                                    maxPrice: finalMax,
                                    inStock: inStock,
                                  ),
                                );
                                Navigator.pop(context);
                              },
                              child: const Text('Apply'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: const Color(0xFF0479FF),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip({
    required String label,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    const Color kMain = Color(0xFF0479FF);
    final selectedBg = kMain;
    const selectedFg = Colors.white;
    final unselectedBg =
        isDark
            ? Colors.grey[800]?.withOpacity(0.5) ?? Colors.grey[800]!
            : Colors.grey[100]!;
    final unselectedFg = isDark ? Colors.white70 : Colors.black87;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: selected,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? selectedFg : unselectedFg,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: selected ? kMain : borderColor,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        selectedColor: selectedBg,
        backgroundColor: unselectedBg,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildSortTile(
    String value,
    String label,
    String? group,
    ValueChanged<String?> onChanged,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = group == value;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color:
            isSelected
                ? const Color(0xFF0479FF).withOpacity(0.1)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isSelected
                  ? const Color(0xFF0479FF).withOpacity(0.3)
                  : Colors.transparent,
          width: 1,
        ),
      ),
      child: RadioListTile<String>(
        dense: true,
        value: value,
        groupValue: group,
        onChanged: onChanged,
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color:
                isSelected
                    ? const Color(0xFF0479FF)
                    : (isDark ? Colors.white : Colors.black87),
          ),
        ),
        activeColor: const Color(0xFF0479FF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
