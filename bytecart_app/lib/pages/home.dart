import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/filter.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/appbar_bottomnav.dart';
import '../widgets/productcard.dart';
import 'account.dart';
import 'search.dart';
import 'shop.dart' as shop;

final productsProvider = FutureProvider<List<Product>>((ref) async {
  return await ApiService.getProducts();
});

final discountedProductsProvider = FutureProvider<List<Product>>((ref) async {
  final products = await ref.watch(productsProvider.future);
  return products.where((p) => p.discount > 0).take(10).toList();
});

final newProductsProvider = FutureProvider<List<Product>>((ref) async {
  final products = await ref.watch(productsProvider.future);
  final newProducts =
      products.where((p) => p.newStock).toList()..sort(
        (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
  return newProducts.take(10).toList();
});

class _FriendlyErrorWidget extends ConsumerWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;

  const _FriendlyErrorWidget({
    required this.message,
    required this.icon,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[900] : Colors.grey[50];
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.white : Colors.black;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: iconColor),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh, color: iconColor),
              label: Text('Retry', style: TextStyle(color: iconColor)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                foregroundColor: iconColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ByteCartShell(
      pages: [
        const HomeTab(key: PageStorageKey('Home')),
        shop.ShopPage(key: const PageStorageKey('Shop')),
        SearchPage(key: const PageStorageKey('Search')),
        AccountPage(key: const PageStorageKey('Account')),
      ],
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    if (isLandscape) {
      return _buildLandscapeHome(context);
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi there! 👋',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w300,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'What are you looking for?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),
                const _ModernSearchBar(),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: _TopBannersCarousel(),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  title: 'Shop by Category',
                  subtitle: 'Find what you need',
                  icon: Icons.grid_view_rounded,
                ),
                const SizedBox(height: 16),
                const _ShopByCategorySection(),
                const SizedBox(height: 32),
                _SectionHeader(
                  title: 'Flash Sale',
                  subtitle: 'Limited time offers',
                  icon: Icons.flash_on,
                  accentColor: Colors.red,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: _DiscountedProductsSection()),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
            child: _SectionHeader(
              title: 'New Arrivals',
              subtitle: 'Fresh picks just for you',
              icon: Icons.new_releases_outlined,
              accentColor: Colors.green,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: _NewProductsSection()),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildLandscapeHome(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1000;
          final showTwoPane = constraints.maxWidth >= 820;
          if (!showTwoPane) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLandscapeLeftPane(context),
                  const SizedBox(height: 24),
                  _buildLandscapeRightPane(context),
                ],
              ),
            );
          }

          final leftFlex = isWide ? 9 : 8;
          final rightFlex = isWide ? 11 : 10;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: leftFlex,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _buildLandscapeLeftPane(context),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: rightFlex,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _buildLandscapeRightPane(context),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLandscapeLeftPane(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.grey[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi there! 👋',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w300,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'What are you looking for?',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              const _ModernSearchBar(),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _SectionHeader(
          title: 'Shop by Category',
          subtitle: 'Find what you need',
          icon: Icons.grid_view_rounded,
        ),
        const SizedBox(height: 16),
        const _ShopByCategorySection(),
      ],
    );
  }

  Widget _buildLandscapeRightPane(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: _TopBannersCarousel(),
        ),
        SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.fromLTRB(0, 4, 0, 0),
          child: _LandscapeFlashHeader(),
        ),
        SizedBox(height: 12),
        _DiscountedProductsSection(),
        SizedBox(height: 24),
        Padding(
          padding: EdgeInsets.fromLTRB(0, 4, 0, 0),
          child: _LandscapeNewArrivalsHeader(),
        ),
        SizedBox(height: 12),
        _NewProductsSection(),
        SizedBox(height: 8),
      ],
    );
  }
}

class _LandscapeFlashHeader extends StatelessWidget {
  const _LandscapeFlashHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: _SectionHeader(
        title: 'Flash Sale',
        subtitle: 'Limited time offers',
        icon: Icons.flash_on,
        accentColor: Colors.red,
      ),
    );
  }
}

class _LandscapeNewArrivalsHeader extends StatelessWidget {
  const _LandscapeNewArrivalsHeader();

  @override
  Widget build(BuildContext context) {
    return _SectionHeader(
      title: 'New Arrivals',
      subtitle: 'Fresh picks just for you',
      icon: Icons.new_releases_outlined,
      accentColor: Colors.green,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? accentColor;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? const Color(0xFF0479FF);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModernSearchBar extends StatefulWidget {
  const _ModernSearchBar();

  @override
  State<_ModernSearchBar> createState() => _ModernSearchBarState();
}

class _ModernSearchBarState extends State<_ModernSearchBar> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _goToSearch(String q) {
    final query = q.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder:
            (_, __, ___) => ByteCartShell(
              initialIndex: 2,
              pages: [
                const HomeTab(key: PageStorageKey('Home')),
                shop.ShopPage(key: const PageStorageKey('Shop')),
                SearchPage(key: UniqueKey(), initialQuery: query),
                AccountPage(key: const PageStorageKey('Account')),
              ],
            ),
        transitionsBuilder: (_, __, ___, child) => child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: TextField(
        controller: _ctrl,
        cursorColor: const Color(0xFF0479FF),
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: "Search for products, brands, and more...",
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(
              Icons.search_rounded,
              color: Colors.grey[500],
              size: 22,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 50),
          suffixIcon:
              _ctrl.text.isEmpty
                  ? null
                  : IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: Colors.grey[500],
                      size: 20,
                    ),
                    onPressed: () {
                      _ctrl.clear();
                      setState(() {});
                    },
                  ),
        ),
        onChanged: (_) => setState(() {}),
        textInputAction: TextInputAction.search,
        onSubmitted: _goToSearch,
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
      ),
    );
  }
}

class _ShopByCategorySection extends ConsumerWidget {
  const _ShopByCategorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final cols = isLandscape ? 3 : 4;

    final productsAsync = ref.watch(productsProvider);

    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return _FriendlyErrorWidget(
            message: "No categories available at the moment.",
            icon: Icons.category_outlined,
          );
        }
        final Set<String> uniqueCategories = <String>{};
        for (final product in products) {
          final categoryName = product.categoryName?.trim();
          if (categoryName != null && categoryName.isNotEmpty) {
            uniqueCategories.add(categoryName);
          }
        }
        if (uniqueCategories.isEmpty) {
          return _FriendlyErrorWidget(
            message: "No categories available at the moment.",
            icon: Icons.category_outlined,
          );
        }
        final categories =
            uniqueCategories.toList()
              ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        final showcase = categories.take(8).toList();

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: showcase.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 16,
            mainAxisSpacing: 20,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, i) {
            return _CategoryBubble(
              label: showcase[i],
              index: i,
              isDark: isDark,
              onTap: () => _navigateToCategory(context, showcase[i]),
            );
          },
        );
      },
      loading: () => _categorySkeleton(isDark, context),
      error:
          (err, stack) => _FriendlyErrorWidget(
            message: "Couldn't load categories.\nCheck your connection.",
            icon: Icons.wifi_off_rounded,
            onRetry: () => ref.refresh(productsProvider),
          ),
    );
  }

  void _navigateToCategory(BuildContext context, String category) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder:
            (_, __, ___) => ByteCartShell(
              initialIndex: 1,
              pages: [
                const HomeTab(key: PageStorageKey('Home')),
                shop.ShopPage(
                  key: UniqueKey(),
                  initialFilter: ShopFilter(category: category),
                ),
                SearchPage(key: const PageStorageKey('Search')),
                AccountPage(key: const PageStorageKey('Account')),
              ],
            ),
        transitionsBuilder: (_, __, ___, child) => child,
      ),
    );
  }

  Widget _categorySkeleton(bool isDark, BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final cols = isLandscape ? 3 : 4;
    final base = isDark ? Colors.grey[800]! : Colors.grey[100]!;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: cols,
      crossAxisSpacing: 16,
      mainAxisSpacing: 20,
      childAspectRatio: 0.85,
      children: List.generate(
        8,
        (index) => Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBubble extends StatelessWidget {
  const _CategoryBubble({
    required this.label,
    required this.index,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final int index;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gradients = <List<Color>>[
      [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      [const Color(0xFFF093FB), const Color(0xFFF5576C)],
      [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
      [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
      [const Color(0xFFFA709A), const Color(0xFFFEE140)],
      [const Color(0xFFA8EDEA), const Color(0xFFFED6E3)],
      [const Color(0xFFFFD89B), const Color(0xFF19547B)],
      [const Color(0xFF89F7FE), const Color(0xFF66A6FF)],
    ];

    final g = gradients[index % gradients.length];
    final icon = _iconForCategory(label);

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: g,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: g.first.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  IconData _iconForCategory(String name) {
    final s = name.toLowerCase();
    if (s.contains('phone') || s.contains('mobile') || s.contains('smart'))
      return Icons.smartphone;
    if (s.contains('laptop') || s.contains('notebook') || s.contains('pc'))
      return Icons.laptop_mac;
    if (s.contains('tablet') || s.contains('ipad')) return Icons.tablet_mac;
    if (s.contains('camera') || s.contains('photo')) return Icons.photo_camera;
    if (s.contains('tv') || s.contains('television')) return Icons.tv;
    if (s.contains('audio') || s.contains('head') || s.contains('ear'))
      return Icons.headphones;
    if (s.contains('game') || s.contains('console'))
      return Icons.sports_esports;
    if (s.contains('watch') || s.contains('wear')) return Icons.watch;
    if (s.contains('home') || s.contains('appliance')) return Icons.home_filled;
    if (s.contains('fashion') || s.contains('cloth') || s.contains('apparel'))
      return Icons.checkroom;
    if (s.contains('shoe') || s.contains('sneaker'))
      return Icons.directions_run;
    if (s.contains('sport') || s.contains('fitness'))
      return Icons.fitness_center;
    if (s.contains('book') || s.contains('read')) return Icons.menu_book;
    if (s.contains('toy')) return Icons.toys;
    if (s.contains('furniture')) return Icons.chair_alt;
    if (s.contains('tool')) return Icons.handyman;
    if (s.contains('beauty') || s.contains('make')) return Icons.brush;
    return Icons.category_outlined;
  }
}

class _TopBannersCarousel extends StatefulWidget {
  const _TopBannersCarousel();

  @override
  State<_TopBannersCarousel> createState() => _TopBannersCarouselState();
}

class _TopBannersCarouselState extends State<_TopBannersCarousel> {
  static const int _kInitialPage = 1000;
  final PageController _controller = PageController(
    viewportFraction: 0.92,
    initialPage: _kInitialPage,
  );
  int _index = 0;
  Timer? _timer;

  final List<_BannerData> _items = const [
    _BannerData(
      title: 'Mega Sale',
      subtitle: 'Up to 70% OFF on electronics',
      colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
      icon: Icons.flash_on,
    ),
    _BannerData(
      title: 'New Arrivals',
      subtitle: 'Fresh collection just dropped',
      colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
      icon: Icons.new_releases,
    ),
    _BannerData(
      title: 'Best Sellers',
      subtitle: 'Most loved products',
      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
      icon: Icons.trending_up,
    ),
    _BannerData(
      title: 'Free Shipping',
      subtitle: 'On orders above \$50',
      colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
      icon: Icons.local_shipping,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      _controller.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i % _items.length),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, i) {
              final data = _items[i % _items.length];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: _ModernBannerCard(data: data),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _ModernDots(count: _items.length, current: _index),
      ],
    );
  }
}

class _BannerData {
  final String title;
  final String subtitle;
  final List<Color> colors;
  final IconData icon;

  const _BannerData({
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.icon,
  });
}

class _ModernBannerCard extends StatelessWidget {
  final _BannerData data;

  const _ModernBannerCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: data.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: Icon(
              data.icon,
              size: 80,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(data.icon, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'SPECIAL',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  data.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernDots extends StatelessWidget {
  final int count;
  final int current;

  const _ModernDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0479FF) : Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _DiscountedProductsSection extends ConsumerWidget {
  const _DiscountedProductsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discountedAsync = ref.watch(discountedProductsProvider);

    return RefreshIndicator(
      color:
          Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
      onRefresh: () async {
        ref.invalidate(discountedProductsProvider);
        await ref.refresh(discountedProductsProvider.future);
      },
      child: discountedAsync.when(
        data: (products) {
          if (products.isEmpty) return const SizedBox.shrink();
          return SizedBox(
            height: 280,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, i) {
                return SizedBox(
                  width: 200,
                  child: ProductCard(product: products[i]),
                );
              },
            ),
          );
        },
        loading: () => _productSectionSkeleton(context),
        error:
            (err, stack) => _FriendlyErrorWidget(
              message:
                  "Couldn't load flash sale products.\nCheck your connection.",
              icon: Icons.wifi_off_rounded,
              onRetry: () => ref.refresh(discountedProductsProvider),
            ),
      ),
    );
  }
}

class _NewProductsSection extends ConsumerWidget {
  const _NewProductsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newAsync = ref.watch(newProductsProvider);

    return RefreshIndicator(
      color:
          Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
      onRefresh: () async {
        ref.invalidate(newProductsProvider);
        await ref.refresh(newProductsProvider.future);
      },
      child: newAsync.when(
        data: (products) {
          if (products.isEmpty) return const SizedBox.shrink();
          return SizedBox(
            height: 280,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, i) {
                return SizedBox(
                  width: 200,
                  child: ProductCard(product: products[i]),
                );
              },
            ),
          );
        },
        loading: () => _productSectionSkeleton(context),
        error:
            (err, stack) => _FriendlyErrorWidget(
              message: "Couldn't load new arrivals.\nCheck your connection.",
              icon: Icons.wifi_off_rounded,
              onRetry: () => ref.refresh(newProductsProvider),
            ),
      ),
    );
  }
}

Widget _productSectionSkeleton(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final color = isDark ? Colors.grey[800] : Colors.grey[100];
  return SizedBox(
    height: 280,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(width: 16),
      itemBuilder: (_, __) {
        return Container(
          width: 200,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    ),
  );
}
