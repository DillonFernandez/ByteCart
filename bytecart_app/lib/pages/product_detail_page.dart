import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/api_service.dart';
import '../theme/theme_colours.dart';
import '../widgets/appbar_bottomnav.dart' show CartCounter; // ADDED

/// ProductDetailPage
/// - Hybrid visual style: sleek + luxury + modern retail
/// - Pure black (dark) / pure white (light) backgrounds
/// - No functional changes: data fetching, selection, quantity, add-to-cart preserved
class ProductDetailPage extends StatefulWidget {
  final int productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Future<Product> _futureProduct;
  ProductModel? _selectedModel;
  String? _selectedColor;
  int _quantity = 1;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  // Added: transient "added" feedback
  Timer? _addedTimer;
  bool _addedFeedback = false;

  // Expandable sections
  bool _descExpanded = true;
  bool _specsExpanded = false;

  @override
  void initState() {
    super.initState();
    _futureProduct = _fetchProductAndPrecache();
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Added: cancel feedback timer
    _addedTimer?.cancel();
    super.dispose();
  }

  // -------------------- Data & Helpers (unchanged functionality) -------------------- //
  Future<Product> _fetchProductAndPrecache() async {
    final p = await ApiService.getProductDetail(widget.productId);
    if (!mounted) return p;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final media = MediaQuery.of(context);
      final availW = media.size.width - 32; // matches horizontal padding
      final pxW = (availW * media.devicePixelRatio).round();

      // Precache main image
      if (p.image != null && p.image!.isNotEmpty) {
        precacheImage(
          ResizeImage(NetworkImage(_imageUrl(p.image)), width: pxW),
          context,
        );
      }

      // Precache a few model images
      final urls = <String>[];
      for (final m in p.models) {
        for (final img in m.images) {
          urls.add(img);
          if (urls.length >= 5) break;
        }
        if (urls.length >= 5) break;
      }
      for (final u in urls) {
        final full = _imageUrl(u);
        if (full.isEmpty) continue;
        precacheImage(ResizeImage(NetworkImage(full), width: pxW), context);
      }
    });

    return p;
  }

  String _imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    const base = 'http://10.0.2.2:8000';
    return path.startsWith('/') ? '$base$path' : '$base/$path';
  }

  String _formatPrice(num price) => '\$${price.toStringAsFixed(2)}';

  num _finalPrice(Product product) {
    if (_selectedModel == null) return 0;
    final base = _selectedModel!.price;
    final discount = product.discount;
    return base - (base * (discount / 100));
  }

  // -------------------- Style helpers -------------------- //
  Color get _bg =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white;

  Color get _surface =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0E0E0E)
          : const Color(0xFFF7F7F7);

  Color get _subtleStroke =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white12
          : Colors.black12;

  TextStyle get _sectionTitleStyle => Theme.of(context).textTheme.titleLarge!
      .copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.1);

  // -------------------- Header (SliverAppBar) -------------------- //
  SliverAppBar _buildHeader(Product product, List<String> images) {
    final hasImages = images.isNotEmpty;
    return SliverAppBar(
      backgroundColor: _bg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      floating: false,
      pinned: true,
      expandedHeight: hasImages ? _heroHeight(context) : 120,
      iconTheme: IconThemeData(
        color: Theme.of(context).colorScheme.onBackground,
      ),
      actions: [
        _GlassIconButton(icon: Icons.favorite_border, onPressed: () {}),
        _GlassIconButton(icon: Icons.share, onPressed: () {}),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background:
            hasImages
                ? _HeroGallery(
                  images: images,
                  currentIndex: _currentImageIndex,
                  pageController: _pageController,
                  onChanged: (i) => setState(() => _currentImageIndex = i),
                  surface: _surface,
                  imageUrlBuilder: _imageUrl,
                )
                : Container(color: _bg),
        titlePadding: const EdgeInsetsDirectional.only(
          start: 16,
          bottom: 12,
          end: 16,
        ),
        // Remove the title so product name does not show in the app bar
        title: null,
      ),
    );
  }

  // Responsive hero gallery height based on screen height
  double _heroHeight(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    // Scales nicely across devices while staying under 520px
    return h <= 700 ? 360 : math.min(h * 0.55, 520);
  }

  // -------------------- Content Sections -------------------- //
  Widget _summaryBlock(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.productName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          product.brandName,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 14),
        if (_selectedModel != null) _priceBlock(product),
      ],
    );
  }

  Widget _priceBlock(Product product) {
    final base = _selectedModel!.price;
    final discount = product.discount;
    final finalPrice = _finalPrice(product);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (discount > 0)
          Row(
            children: [
              Text(
                _formatPrice(base),
                style: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$discount% OFF',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 6),
        Text(
          _formatPrice(finalPrice),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        if (_selectedModel!.stock <= 5)
          Row(
            children: [
              Icon(
                _selectedModel!.stock == 0
                    ? Icons.cancel
                    : Icons.warning_amber_rounded,
                color: _selectedModel!.stock == 0 ? Colors.red : Colors.orange,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                _selectedModel!.stock == 0
                    ? 'Out of Stock'
                    : 'Low stock (${_selectedModel!.stock} left)',
                style: TextStyle(
                  color:
                      _selectedModel!.stock == 0 ? Colors.red : Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _models(Product product) {
    return _section(
      'Model',
      // Convert from grid-like Wrap to a smooth horizontal carousel
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              product.models.map((m) {
                final selected = _selectedModel?.id == m.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _ChipCard(
                    selected: selected,
                    onTap:
                        () => setState(() {
                          _selectedModel = m;
                          _selectedColor = null;
                          _quantity = 1;
                          // Reset added feedback when options change
                          _addedFeedback = false;
                        }),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          m.modelName,
                          style: TextStyle(
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _colors() {
    if (_selectedModel == null || _selectedModel!.colorList.isEmpty) {
      return const SizedBox.shrink();
    }
    return _section(
      'Color',
      // Convert from Wrap to a horizontal scroller for consistency
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              _selectedModel!.colorList.map((c) {
                final selected = _selectedColor == c;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _ChipCard(
                    selected: selected,
                    onTap:
                        () => setState(() {
                          _selectedColor = c;
                          // Reset added feedback when options change
                          _addedFeedback = false;
                        }),
                    child: Text(
                      c,
                      style: TextStyle(
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _description(Product product) {
    return _expander(
      'Description',
      product.description,
      _descExpanded,
      (v) => setState(() => _descExpanded = v),
    );
  }

  Widget _specs(Product product) {
    return _expander(
      'Specifications',
      product.specification,
      _specsExpanded,
      (v) => setState(() => _specsExpanded = v),
    );
  }

  // Reusable section shell
  Widget _section(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _sectionTitleStyle),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  // Expander (glass card)
  Widget _expander(
    String title,
    String? content,
    bool expanded,
    void Function(bool) onToggle,
  ) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _subtleStroke),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          // Disable press/hover visuals to prevent flash
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          hoverColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
        ),
        child: ExpansionTile(
          initiallyExpanded: expanded,
          onExpansionChanged: onToggle,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          iconColor: Theme.of(context).colorScheme.onSurface,
          collapsedIconColor: Theme.of(context).colorScheme.onSurface,
          title: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          children: [
            Text(content, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  // -------------------- Bottom Action Bar -------------------- //
  Widget _bottomBar(Product product) {
    final canAddToCart =
        _selectedModel != null &&
        _selectedColor != null && // Require color selection
        _selectedModel!.stock > 0 &&
        _quantity <= _selectedModel!.stock;

    final price = _finalPrice(product);
    final total = price * _quantity;
    final canIncrement = (_selectedModel?.stock ?? 0) > _quantity;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF121212)
                : const Color(0xFFF5F5F5),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedModel != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1A1A1A)
                        : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _subtleStroke),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total",
                        style: Theme.of(
                          context,
                        ).textTheme.labelMedium?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatPrice(total),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _subtleStroke),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed:
                              _quantity > 1
                                  ? () => setState(() => _quantity--)
                                  : null,
                          icon: const Icon(Icons.remove, size: 18),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '$_quantity',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          onPressed:
                              canIncrement
                                  ? () => setState(() => _quantity++)
                                  : null,
                          icon: const Icon(Icons.add, size: 18),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            child:
                _selectedModel == null
                    ? Text(
                      'Select model & color',
                      key: const ValueKey('select'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: Colors.grey),
                    )
                    : SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: canAddToCart ? _addToCart : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _addedFeedback ? Colors.green : kMainColour,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _addedFeedback ? 'Added to Cart' : 'Add to Cart',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Future<void> _addToCart() async {
    // Prevent add unless both model and color are selected
    if (_selectedModel == null || _selectedColor == null) return;

    try {
      final response = await ApiService.addToCart(
        modelId: _selectedModel!.id,
        qty: _quantity,
        color: _selectedColor,
      );

      if (mounted) {
        // ADDED: refresh global cart count immediately
        unawaited(CartCounter.refreshFromApi());

        // Show transient success on button instead of SnackBar
        setState(() {
          _addedFeedback = true;
        });
        _addedTimer?.cancel();
        _addedTimer = Timer(const Duration(seconds: 3), () {
          if (!mounted) return;
          setState(() => _addedFeedback = false);
        });
      }
    } catch (e) {
      if (mounted) {
        // Keep error feedback via SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  // -------------------- Build -------------------- //
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FutureBuilder<Product>(
        future: _futureProduct,
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Error
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Something went wrong",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed:
                          () => setState(
                            () => _futureProduct = _fetchProductAndPrecache(),
                          ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          // Not found
          if (!snapshot.hasData) {
            return const Center(child: Text("Product not found"));
          }

          final product = snapshot.data!;
          // Auto-select first model (preserved)
          if (_selectedModel == null && product.models.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() => _selectedModel = product.models.first);
            });
          }

          final heroImages = <String>[
            if (product.image != null && product.image!.isNotEmpty)
              product.image!,
            if (_selectedModel != null) ..._selectedModel!.images,
          ];

          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    _buildHeader(product, heroImages),
                    SliverToBoxAdapter(
                      child: Padding(
                        // Slightly increase breathing room around content
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _summaryBlock(product),
                            const SizedBox(height: 24),
                            const _DividerLine(),
                            const SizedBox(height: 24),
                            _models(product),
                            const SizedBox(height: 20),
                            _colors(),
                            const SizedBox(height: 24),
                            const _DividerLine(),
                            const SizedBox(height: 24),
                            _description(product),
                            const SizedBox(height: 16),
                            _specs(product),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _bottomBar(product),
            ],
          );
        },
      ),
    );
  }
}

// -------------------- Reusable Visual Components -------------------- //

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _GlassIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base =
        isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.06);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Container(
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 22),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
      ),
    );
  }
}

class _ChipCard extends StatelessWidget {
  final bool selected;
  final Widget child;
  final VoidCallback onTap;

  const _ChipCard({
    required this.selected,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final stroke =
        selected
            ? kMainColour
            : (Theme.of(context).brightness == Brightness.dark
                ? Colors.white24
                : Colors.black12);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color:
            selected
                ? kMainColour.withOpacity(0.10)
                : (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF121212)
                    : const Color(0xFFF5F5F5)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stroke, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: GestureDetector(onTap: onTap, child: child),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color:
          Theme.of(context).brightness == Brightness.dark
              ? Colors.white12
              : Colors.black12,
    );
  }
}

class _HeroGallery extends StatelessWidget {
  final List<String> images;
  final int currentIndex;
  final PageController pageController;
  final void Function(int) onChanged;
  final Color surface;
  final String Function(String?) imageUrlBuilder;

  const _HeroGallery({
    required this.images,
    required this.currentIndex,
    required this.pageController,
    required this.onChanged,
    required this.surface,
    required this.imageUrlBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return _ImageFrame(
        color: surface,
        child: const Center(
          child: Icon(Icons.image_outlined, size: 56, color: Colors.grey),
        ),
      );
    }

    // Cleaner, fully-overlaid gallery with in-frame dots
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors:
                    Theme.of(context).brightness == Brightness.dark
                        ? [Colors.black, Colors.black]
                        : [Colors.white, Colors.white],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: _ImageFrame(
            color: surface,
            child: PageView.builder(
              controller: pageController,
              onPageChanged: onChanged,
              itemCount: images.length,
              itemBuilder: (_, i) {
                final url = imageUrlBuilder(images[i]);
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Image.network(
                      key: ValueKey(url),
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (c, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      },
                      errorBuilder:
                          (c, e, s) => const Center(
                            child: Icon(Icons.broken_image, size: 56),
                          ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: _Dots(count: images.length, current: currentIndex),
          ),
      ],
    );
  }
}

class _ImageFrame extends StatelessWidget {
  final Widget child;
  final Color color;

  const _ImageFrame({required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Remove fixed height to allow the frame to expand within constraints
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(12),
      child: ClipRRect(borderRadius: BorderRadius.circular(12), child: child),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int current;

  const _Dots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? kMainColour : Colors.grey.withOpacity(0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
