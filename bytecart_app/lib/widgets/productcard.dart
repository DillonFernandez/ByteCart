import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod import
import 'package:flutter_riverpod/legacy.dart';

import '../models/product.dart';
import '../pages/product_detail_page.dart';
import '../services/api_service.dart';

// Provider for polling and holding the latest product info
final productCardProvider =
StateNotifierProvider.family<ProductCardNotifier, Product, Product>(
      (ref, initialProduct) => ProductCardNotifier(initialProduct),
);

class ProductCardNotifier extends StateNotifier<Product> {
  Timer? _pollTimer;

  ProductCardNotifier(Product initial) : super(initial) {
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final latest = await ApiService.getProductDetail(state.id);
        final imageChanged = latest.image != state.image;
        state = latest;
        // No need to precache here; let widget handle it if needed
      } catch (_) {
        // ignore polling errors
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

// Stateless ProductCard using Riverpod for state
class ProductCard extends ConsumerStatefulWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _elevationAnimation = Tween<double>(begin: 2.0, end: 12.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final url = _imageUrl(widget.product.image);
      if (url.isNotEmpty) {
        precacheImage(NetworkImage(url), context);
      }
    });
  }

  String _imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = 'http://10.0.2.2:8000';
    if (path.startsWith('/')) return '$base$path';
    return '$base/$path';
  }

  @override
  Widget build(BuildContext context) {
    final _product = ref.watch(productCardProvider(widget.product));
    final priceRange = _getPriceRange(_product);
    final isOutOfStock = _isOutOfStock(_product);
    final hasDiscount = _hasDiscount(_product);
    final isNew = _isNew(_product);
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return GestureDetector(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform:
              Matrix4.identity()
                ..translate(0.0, _isHovered ? -4.0 : 0.0),
              child: Card(
                elevation: _elevationAnimation.value,
                shadowColor: Colors.black.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: isDark ? Colors.grey[900] : Colors.grey[100],
                    border: Border.all(
                      color:
                      _isHovered
                          ? const Color(0xFF0479FF).withOpacity(0.2)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image section
                      Expanded(
                        flex: 3,
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          child: Stack(
                            children: [
                              // Product image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  child:
                                  _product.image != null &&
                                      _product.image!.isNotEmpty
                                      ? LayoutBuilder(
                                    builder: (context, constraints) {
                                      final cacheWidth =
                                      (constraints.maxWidth *
                                          MediaQuery
                                              .of(
                                            context,
                                          )
                                              .devicePixelRatio)
                                          .round();
                                      return Image.network(
                                        _imageUrl(_product.image),
                                        fit: BoxFit.contain,
                                        gaplessPlayback: true,
                                        filterQuality:
                                        FilterQuality.low,
                                        cacheWidth: cacheWidth,
                                        loadingBuilder: (context,
                                            child,
                                            loadingProgress,) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return _buildImagePlaceholder();
                                        },
                                        errorBuilder: (context,
                                            error,
                                            stackTrace,) {
                                          return _buildImagePlaceholder();
                                        },
                                      );
                                    },
                                  )
                                      : _buildImagePlaceholder(),
                                ),
                              ),
                              // Badges
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (hasDiscount)
                                      _buildDiscountBadge(_product),
                                    if (isNew) _buildNewBadge(),
                                  ],
                                ),
                              ),
                              // Out of stock overlay
                              if (isOutOfStock) _buildOutOfStockOverlay(),
                            ],
                          ),
                        ),
                      ),
                      // Product info section
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Brand name
                              Text(
                                _product.brandName,
                                style: TextStyle(
                                  color:
                                  isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              // Product name
                              Expanded(
                                child: Text(
                                  _product.productName,
                                  style: TextStyle(
                                    color:
                                    isDark ? Colors.white : Colors.black87,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Price and action section
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Price section
                                  Expanded(
                                    child: _buildPriceSection(
                                      priceRange,
                                      hasDiscount,
                                      isDark,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Add button
                                  _buildAddButton(isOutOfStock, _product),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: Icon(
          Icons.image_outlined,
          size: 32,
          color: isDark ? Colors.grey[500] : Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildDiscountBadge(Product product) {
    final d = product.discount;
    final clamped = d < 0 ? 0 : (d > 100 ? 100 : d);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626),
        borderRadius: BorderRadius.circular(4.5),
      ),
      child: Text(
        '-$clamped%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildNewBadge() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF059669),
        borderRadius: BorderRadius.circular(4.5),
      ),
      child: const Text(
        'NEW',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildOutOfStockOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          color: Colors.black.withOpacity(0.6),
        ),
        child: const Center(
          child: Text(
            'OUT OF STOCK',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceSection(Map<String, String?> priceRange,
      bool hasDiscount,
      bool isDark,) {
    final display = priceRange['display'] ?? '';
    final parts = display.split(' - ');
    var firstLine = parts.isNotEmpty ? parts[0] : display;
    final String? secondLine = parts.length > 1 ? parts[1] : null;
    if (secondLine != null) {
      firstLine = '$firstLine -';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasDiscount && priceRange['original'] != null)
          Text(
            priceRange['original']!,
            style: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[500],
              fontSize: 10,
              decoration: TextDecoration.lineThrough,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        Text(
          firstLine,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (secondLine != null)
          Text(
            secondLine,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildAddButton(bool isOutOfStock, Product product) {
    return GestureDetector(
      onTap:
      isOutOfStock
          ? null
          : () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(productId: product.id),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color:
          isOutOfStock
              ? const Color(0xFF94A3B8)
              : (_isHovered
              ? const Color(0xFF0369A1)
              : const Color(0xFF0479FF)),
          shape: BoxShape.circle,
          boxShadow:
          _isHovered && !isOutOfStock
              ? [
            BoxShadow(
              color: const Color(0xFF0479FF).withOpacity(0.3),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ]
              : [],
        ),
        child: Icon(
          isOutOfStock ? Icons.block : Icons.add,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Map<String, String?> _getPriceRange(Product product) {
    if (product.models.isEmpty) {
      return {'display': '\$0.00', 'original': null};
    }
    final prices = product.models.map((m) => m.price).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);

    String originalRange;
    String displayRange;

    if (minPrice == maxPrice) {
      originalRange = '\$${_formatPrice(minPrice)}';
    } else {
      originalRange =
      '\$${_formatPrice(minPrice)} - \$${_formatPrice(maxPrice)}';
    }

    final d = product.discount;
    final discount = d < 0 ? 0 : (d > 100 ? 100 : d);

    if (discount > 0) {
      final discountedMin = minPrice * (1 - discount / 100);
      final discountedMax = maxPrice * (1 - discount / 100);

      if (minPrice == maxPrice) {
        displayRange = '\$${_formatPrice(discountedMin)}';
      } else {
        displayRange =
        '\$${_formatPrice(discountedMin)} - \$${_formatPrice(discountedMax)}';
      }

      return {'display': displayRange, 'original': originalRange};
    }

    return {'display': originalRange, 'original': null};
  }

  String _formatPrice(double price) {
    final formatted = price.toStringAsFixed(2);
    final parts = formatted.split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    final integerWithCommas = integerPart.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]},',
    );

    return '$integerWithCommas.$decimalPart';
  }

  bool _isOutOfStock(Product product) {
    return product.models.every((model) => model.stock == 0);
  }

  bool _hasDiscount(Product product) {
    return product.discount > 0;
  }

  bool _isNew(Product product) {
    return product.newStock;
  }
}
