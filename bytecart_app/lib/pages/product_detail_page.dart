import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/product.dart';
import '../services/api_service.dart';
import '../theme/theme_colours.dart';
import '../widgets/appbar_bottomnav.dart' show CartCounter;

class ProductDetailPage extends ConsumerWidget {
  final int productId;

  const ProductDetailPage({super.key, required this.productId});

  static SnackBar _styledSnackBar(BuildContext context,
      String msg, {
        bool isError = false,
      }) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    return SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.wifi_off : Icons.check_circle,
            color:
            isError
                ? (isDark ? Colors.red[200] : Colors.red)
                : (isDark ? Colors.green[200] : Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      backgroundColor:
      isError
          ? (isDark ? Colors.red[900] : Colors.red[50])
          : (isDark ? Colors.green[900] : Colors.green[50]),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    );
  }

  static Widget _errorView(BuildContext context,
      String msg, {
        bool isConnection = false,
        VoidCallback? onRetry,
      }) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isConnection ? Icons.wifi_off : Icons.error_outline,
              size: 64,
              color:
              isConnection
                  ? (isDark ? Colors.white : Colors.black)
                  : (isDark ? Colors.red[200] : Colors.red),
            ),
            const SizedBox(height: 16),
            Text(
              isConnection ? "Connection Issue" : "Something went wrong",
              style: Theme
                  .of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: Icon(
                  Icons.refresh,
                  color: isDark ? Colors.white : Colors.black,
                ),
                label: Text(
                  'Retry',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white12 : Colors.black12,
                  foregroundColor: isDark ? Colors.white : Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Color _refreshIndicatorColor(BuildContext context) =>
      Theme
          .of(context)
          .brightness == Brightness.dark
          ? Colors.white
          : Colors.black;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLandscape =
        MediaQuery
            .of(context)
            .orientation == Orientation.landscape;
    final productAsync = ref.watch(productDetailProvider(productId));
    final selectedModel = ref.watch(selectedModelProvider(productId));
    final selectedColor = ref.watch(selectedColorProvider(productId));
    final quantity = ref.watch(quantityProvider(productId));
    final currentImageIndex = ref.watch(currentImageIndexProvider(productId));
    final addedFeedback = ref.watch(addedFeedbackProvider(productId));
    final wishlisted = ref.watch(wishlistProvider(productId));

    return Scaffold(
      backgroundColor: _bg(context),
      appBar:
      isLandscape
          ? AppBar(
        backgroundColor: _bg(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: Theme
              .of(context)
              .colorScheme
              .onBackground,
        ),
        titleTextStyle: Theme
            .of(
          context,
        )
            .textTheme
            .titleMedium
            ?.copyWith(
          color: Theme
              .of(context)
              .colorScheme
              .onBackground,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        title: const Text('Product'),
        centerTitle: true,
      )
          : null,
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
          final isConnection =
              err.toString().contains('SocketException') ||
                  err.toString().contains('Failed host lookup');
          return _errorView(
            context,
            isConnection
                ? "Unable to connect. Please check your internet connection and try again."
                : "We couldn't load this product. Please try again.",
            isConnection: isConnection,
            onRetry: () => ref.refresh(productDetailProvider(productId)),
          );
        },
        data: (product) {
          if (selectedModel == null && product.models.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref
                  .read(selectedModelProvider(productId).notifier)
                  .state =
                  product.models.first;
            });
          }
          final heroImages = <String>[
            if (product.image != null && product.image!.isNotEmpty)
              product.image!,
            if (selectedModel != null) ...selectedModel.images,
          ];

          final content =
          isLandscape
              ? _buildLandscapeContent(
            context,
            ref,
            product,
            heroImages,
            currentImageIndex,
            wishlisted,
            addedFeedback,
          )
              : _buildPortraitContent(
            context,
            ref,
            product,
            heroImages,
            currentImageIndex,
            wishlisted,
            addedFeedback,
          );

          return RefreshIndicator(
            color: _refreshIndicatorColor(context),
            onRefresh: () async {
              ref.invalidate(productDetailProvider(productId));
              await ref.refresh(productDetailProvider(productId).future);
            },
            child: content,
          );
        },
      ),
    );
  }

  Widget _buildPortraitContent(BuildContext context,
      WidgetRef ref,
      Product product,
      List<String> heroImages,
      int currentImageIndex,
      bool wishlisted,
      bool addedFeedback,) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              _buildHeader(
                context,
                ref,
                product,
                heroImages,
                currentImageIndex,
                wishlisted,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: _DetailSections(
                    productId: productId,
                    product: product,
                  ),
                ),
              ),
            ],
          ),
        ),
        _BottomBar(
          productId: productId,
          product: product,
          addedFeedback: addedFeedback,
        ),
      ],
    );
  }

  Widget _buildLandscapeContent(BuildContext context,
      WidgetRef ref,
      Product product,
      List<String> images,
      int currentImageIndex,
      bool wishlisted,
      bool addedFeedback,) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 20.0;
          final isWide = constraints.maxWidth >= 1100;
          final leftFlex = isWide ? 11 : 10;
          final rightFlex = isWide ? 10 : 10;
          final maxGalleryHeight = math.min(constraints.maxHeight - 32, 520.0);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: leftFlex,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxGalleryHeight),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _surface(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _subtleStroke(context)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _HeroGallery(
                          images: images,
                          currentIndex: currentImageIndex,
                          pageController: PageController(
                            initialPage: currentImageIndex,
                          ),
                          onChanged:
                              (i) =>
                          ref
                              .read(
                            currentImageIndexProvider(
                              productId,
                            ).notifier,
                          )
                              .state = i,
                          surface: _surface(context),
                          imageUrlBuilder: _imageUrl,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: gap),
                Expanded(
                  flex: rightFlex,
                  child: ScrollConfiguration(
                    behavior: const ScrollBehavior().copyWith(
                      overscroll: false,
                    ),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DetailSections(
                              productId: productId,
                              product: product,
                            ),
                            const SizedBox(height: 24),
                            _LandscapeCTA(
                              productId: productId,
                              product: product,
                              addedFeedback: addedFeedback,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  SliverAppBar _buildHeader(BuildContext context,
      WidgetRef ref,
      Product product,
      List<String> images,
      int currentImageIndex,
      bool wishlisted,) {
    final hasImages = images.isNotEmpty;
    return SliverAppBar(
      backgroundColor: _bg(context),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      floating: false,
      pinned: true,
      expandedHeight: hasImages ? _heroHeight(context) : 120,
      iconTheme: IconThemeData(
        color: Theme
            .of(context)
            .colorScheme
            .onBackground,
      ),
      actions: [
        _GlassIconButton(
          icon: wishlisted ? Icons.favorite : Icons.favorite_border,
          onPressed:
              () =>
              ref
                  .read(wishlistProvider(productId).notifier)
                  .toggle(context),
          color: wishlisted ? Colors.amber : null,
        ),
        _GlassIconButton(icon: Icons.share, onPressed: () {}),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background:
        hasImages
            ? _HeroGallery(
          images: images,
          currentIndex: currentImageIndex,
          pageController: PageController(
            initialPage: currentImageIndex,
          ),
          onChanged:
              (i) =>
          ref
              .read(
            currentImageIndexProvider(productId).notifier,
          )
              .state = i,
          surface: _surface(context),
          imageUrlBuilder: _imageUrl,
        )
            : Container(color: _bg(context)),
        titlePadding: const EdgeInsetsDirectional.only(
          start: 16,
          bottom: 12,
          end: 16,
        ),
        title: null,
      ),
    );
  }

  double _heroHeight(BuildContext context) {
    final h = MediaQuery
        .of(context)
        .size
        .height;
    return h <= 700 ? 360 : math.min(h * 0.55, 520);
  }

  static Color _bg(BuildContext context) =>
      Theme
          .of(context)
          .brightness == Brightness.dark
          ? Colors.black
          : Colors.white;

  static Color _surface(BuildContext context) =>
      Theme
          .of(context)
          .brightness == Brightness.dark
          ? const Color(0xFF0E0E0E)
          : const Color(0xFFF7F7F7);

  static Color _subtleStroke(BuildContext context) =>
      Theme
          .of(context)
          .brightness == Brightness.dark
          ? Colors.white12
          : Colors.black12;

  static TextStyle _sectionTitleStyle(BuildContext context) =>
      Theme
          .of(context)
          .textTheme
          .titleLarge!
          .copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.1);

  static String _imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    const base = 'http://10.0.2.2:8000';
    return path.startsWith('/') ? '$base$path' : '$base/$path';
  }

  static String _formatPrice(num price) => '\$${price.toStringAsFixed(2)}';

  static num _finalPrice(Product product, ProductModel? selectedModel) {
    if (selectedModel == null) return 0;
    final base = selectedModel.price;
    final discount = product.discount;
    return base - (base * (discount / 100));
  }
}

class _DetailSections extends ConsumerWidget {
  final int productId;
  final Product product;

  const _DetailSections({required this.productId, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedModel = ref.watch(selectedModelProvider(productId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _summaryBlock(context, selectedModel),
        const SizedBox(height: 24),
        const _DividerLine(),
        const SizedBox(height: 24),
        _models(context, ref, product),
        const SizedBox(height: 20),
        _colors(context, ref, product),
        const SizedBox(height: 24),
        const _DividerLine(),
        const SizedBox(height: 24),
        _description(context, product),
        const SizedBox(height: 16),
        _specs(context, product),
      ],
    );
  }

  Widget _summaryBlock(BuildContext context, ProductModel? selectedModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.productName,
          style: Theme
              .of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          product.brandName,
          style: Theme
              .of(
            context,
          )
              .textTheme
              .titleMedium
              ?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 14),
        if (selectedModel != null) _priceBlock(context, selectedModel),
      ],
    );
  }

  Widget _priceBlock(BuildContext context, ProductModel selectedModel) {
    final base = selectedModel.price;
    final discount = product.discount;
    final finalPrice = ProductDetailPage._finalPrice(product, selectedModel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (discount > 0)
          Row(
            children: [
              Text(
                ProductDetailPage._formatPrice(base),
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
          ProductDetailPage._formatPrice(finalPrice),
          style: Theme
              .of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        if (selectedModel.stock <= 5)
          Row(
            children: [
              Icon(
                selectedModel.stock == 0
                    ? Icons.cancel
                    : Icons.warning_amber_rounded,
                color: selectedModel.stock == 0 ? Colors.red : Colors.orange,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                selectedModel.stock == 0
                    ? 'Out of Stock'
                    : 'Low stock (${selectedModel.stock} left)',
                style: TextStyle(
                  color: selectedModel.stock == 0 ? Colors.red : Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _models(BuildContext context, WidgetRef ref, Product product) {
    final selectedModel = ref.watch(selectedModelProvider(productId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Model', style: ProductDetailPage._sectionTitleStyle(context)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
            product.models.map((m) {
              final selected = selectedModel?.id == m.id;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _ChipCard(
                  selected: selected,
                  onTap: () {
                    ref
                        .read(selectedModelProvider(productId).notifier)
                        .state = m;
                    ref
                        .read(selectedColorProvider(productId).notifier)
                        .state = null;
                    ref
                        .read(quantityProvider(productId).notifier)
                        .state =
                    1;
                    ref
                        .read(addedFeedbackProvider(productId).notifier)
                        .state = false;
                  },
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
      ],
    );
  }

  Widget _colors(BuildContext context, WidgetRef ref, Product product) {
    final selectedModel = ref.watch(selectedModelProvider(productId));
    final selectedColor = ref.watch(selectedColorProvider(productId));
    if (selectedModel == null || selectedModel.colorList.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Color', style: ProductDetailPage._sectionTitleStyle(context)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
            selectedModel.colorList.map((c) {
              final selected = selectedColor == c;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _ChipCard(
                  selected: selected,
                  onTap: () {
                    ref
                        .read(selectedColorProvider(productId).notifier)
                        .state = c;
                    ref
                        .read(addedFeedbackProvider(productId).notifier)
                        .state = false;
                  },
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
      ],
    );
  }

  Widget _description(BuildContext context, Product product) {
    return _expander(context, 'Description', product.description, true);
  }

  Widget _specs(BuildContext context, Product product) {
    return _expander(context, 'Specifications', product.specification, false);
  }

  Widget _expander(BuildContext context,
      String title,
      String? content,
      bool initiallyExpanded,) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: ProductDetailPage._surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ProductDetailPage._subtleStroke(context)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          hoverColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          iconColor: Theme
              .of(context)
              .colorScheme
              .onSurface,
          collapsedIconColor: Theme
              .of(context)
              .colorScheme
              .onSurface,
          title: Text(
            title,
            style: Theme
                .of(
              context,
            )
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          children: [
            Text(content, style: Theme
                .of(context)
                .textTheme
                .bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends ConsumerWidget {
  final int productId;
  final Product product;
  final bool addedFeedback;

  const _BottomBar({
    required this.productId,
    required this.product,
    required this.addedFeedback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedModel = ref.watch(selectedModelProvider(productId));
    final selectedColor = ref.watch(selectedColorProvider(productId));
    final quantity = ref.watch(quantityProvider(productId));
    final canAddToCart =
        selectedModel != null &&
            selectedColor != null &&
            selectedModel.stock > 0 &&
            quantity <= selectedModel.stock;
    final price = ProductDetailPage._finalPrice(product, selectedModel);
    final total = price * quantity;
    final canIncrement = (selectedModel?.stock ?? 0) > quantity;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      decoration: BoxDecoration(
        color:
        Theme
            .of(context)
            .brightness == Brightness.dark
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
          if (selectedModel != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                Theme
                    .of(context)
                    .brightness == Brightness.dark
                    ? const Color(0xFF1A1A1A)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ProductDetailPage._subtleStroke(context),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total",
                        style: Theme
                            .of(
                          context,
                        )
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ProductDetailPage._formatPrice(total),
                        style: Theme
                            .of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color:
                      Theme
                          .of(context)
                          .brightness == Brightness.dark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: ProductDetailPage._subtleStroke(context),
                      ),
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
                          quantity > 1
                              ? () =>
                          ref
                              .read(
                            quantityProvider(
                              productId,
                            ).notifier,
                          )
                              .state--
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
                            '$quantity',
                            style: Theme
                                .of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          onPressed:
                          canIncrement
                              ? () =>
                          ref
                              .read(
                            quantityProvider(
                              productId,
                            ).notifier,
                          )
                              .state++
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
            selectedModel == null
                ? Text(
              'Select model & color',
              key: const ValueKey('select'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme
                  .of(
                context,
              )
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: Colors.grey),
            )
                : SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed:
                canAddToCart
                    ? () async {
                  await _addToCart(
                    context,
                    ref,
                    productId,
                    selectedModel,
                    quantity,
                    ref.read(selectedColorProvider(productId)),
                  );
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  addedFeedback ? Colors.green : kMainColour,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  addedFeedback ? 'Added to Cart' : 'Add to Cart',
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

  Future<void> _addToCart(BuildContext context,
      WidgetRef ref,
      int productId,
      ProductModel selectedModel,
      int quantity,
      String? selectedColor,) async {
    if (selectedModel == null || selectedColor == null) return;
    try {
      await ApiService.addToCart(
        modelId: selectedModel.id,
        qty: quantity,
        color: selectedColor,
      );
      unawaited(CartCounter.refreshFromApi());
      ref
          .read(addedFeedbackProvider(productId).notifier)
          .state = true;
      Timer(const Duration(seconds: 3), () {
        ref
            .read(addedFeedbackProvider(productId).notifier)
            .state = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        ProductDetailPage._styledSnackBar(context, e.toString(), isError: true),
      );
    }
  }
}

class _LandscapeCTA extends ConsumerWidget {
  final int productId;
  final Product product;
  final bool addedFeedback;

  const _LandscapeCTA({
    required this.productId,
    required this.product,
    required this.addedFeedback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedModel = ref.watch(selectedModelProvider(productId));
    final selectedColor = ref.watch(selectedColorProvider(productId));
    final quantity = ref.watch(quantityProvider(productId));
    final canAddToCart =
        selectedModel != null &&
            selectedColor != null &&
            selectedModel.stock > 0 &&
            quantity <= selectedModel.stock;
    final price = ProductDetailPage._finalPrice(product, selectedModel);
    final total = price * quantity;
    final canIncrement = (selectedModel?.stock ?? 0) > quantity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selectedModel != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:
              Theme
                  .of(context)
                  .brightness == Brightness.dark
                  ? const Color(0xFF1A1A1A)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ProductDetailPage._subtleStroke(context),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total",
                      style: Theme
                          .of(
                        context,
                      )
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ProductDetailPage._formatPrice(total),
                      style: Theme
                          .of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color:
                    Theme
                        .of(context)
                        .brightness == Brightness.dark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: ProductDetailPage._subtleStroke(context),
                    ),
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
                        quantity > 1
                            ? () =>
                        ref
                            .read(
                          quantityProvider(productId).notifier,
                        )
                            .state--
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
                          '$quantity',
                          style: Theme
                              .of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed:
                        canIncrement
                            ? () =>
                        ref
                            .read(
                          quantityProvider(productId).notifier,
                        )
                            .state++
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
          selectedModel == null
              ? Text(
            'Select model & color',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme
                .of(
              context,
            )
                .textTheme
                .labelLarge
                ?.copyWith(color: Colors.grey),
          )
              : SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed:
              canAddToCart
                  ? () async {
                await _addToCart(
                  context,
                  ref,
                  productId,
                  selectedModel,
                  quantity,
                  ref.read(selectedColorProvider(productId)),
                );
              }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                addedFeedback ? Colors.green : kMainColour,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                addedFeedback ? 'Added to Cart' : 'Add to Cart',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _addToCart(BuildContext context,
      WidgetRef ref,
      int productId,
      ProductModel selectedModel,
      int quantity,
      String? selectedColor,) async {
    if (selectedModel == null || selectedColor == null) return;
    try {
      await ApiService.addToCart(
        modelId: selectedModel.id,
        qty: quantity,
        color: selectedColor,
      );
      unawaited(CartCounter.refreshFromApi());
      ref
          .read(addedFeedbackProvider(productId).notifier)
          .state = true;
      Timer(const Duration(seconds: 3), () {
        ref
            .read(addedFeedbackProvider(productId).notifier)
            .state = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        ProductDetailPage._styledSnackBar(context, e.toString(), isError: true),
      );
    }
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
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
          icon: Icon(icon, size: 22, color: color),
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
        : (Theme
        .of(context)
        .brightness == Brightness.dark
        ? Colors.white24
        : Colors.black12);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color:
        selected
            ? kMainColour.withOpacity(0.10)
            : (Theme
            .of(context)
            .brightness == Brightness.dark
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
      Theme
          .of(context)
          .brightness == Brightness.dark
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

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors:
                Theme
                    .of(context)
                    .brightness == Brightness.dark
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
                          (c, e, s) =>
                      const Center(
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

final productDetailProvider = FutureProvider.family<Product, int>((ref,
    productId,) async {
  final p = await ApiService.getProductDetail(productId);
  return p;
});

final selectedModelProvider = StateProvider.family<ProductModel?, int>(
      (ref, productId) => null,
);

final selectedColorProvider = StateProvider.family<String?, int>(
      (ref, productId) => null,
);

final quantityProvider = StateProvider.family<int, int>((ref, productId) => 1);

final currentImageIndexProvider = StateProvider.family<int, int>(
      (ref, productId) => 0,
);

final addedFeedbackProvider = StateProvider.family<bool, int>(
      (ref, productId) => false,
);

final wishlistProvider =
StateNotifierProvider.family<_WishlistNotifier, bool, int>(
      (ref, productId) => _WishlistNotifier(productId),
);

class _WishlistNotifier extends StateNotifier<bool> {
  final int productId;
  bool _wishOp = false;

  _WishlistNotifier(this.productId) : super(false) {
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final items = await ApiService.getWishlist();
      final isIn = items.any((item) {
        final product =
        (item['product'] is Map)
            ? Map<String, dynamic>.from(item['product'])
            : null;
        final dynamic idRaw =
            item['product_id'] ?? product?['id'] ?? item['id'];
        if (idRaw is int) return idRaw == productId;
        if (idRaw is String) return int.tryParse(idRaw) == productId;
        if (idRaw is num) return idRaw.toInt() == productId;
        return false;
      });
      state = isIn;
    } catch (_) {
      state = false;
    }
  }

  Future<void> toggle(BuildContext context) async {
    if (_wishOp) return;
    _wishOp = true;
    state = !state;
    try {
      await ApiService.toggleWishlist(productId.toString());
    } catch (e) {
      state = !state;
      ScaffoldMessenger.of(context).showSnackBar(
        ProductDetailPage._styledSnackBar(context, e.toString(), isError: true),
      );
    } finally {
      _wishOp = false;
    }
  }
}
