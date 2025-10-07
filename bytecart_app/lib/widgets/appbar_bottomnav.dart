import 'package:flutter/material.dart';

import '../pages/account.dart';
import '../pages/cart.dart';
import '../pages/search.dart' as search;
import '../pages/shop.dart' as shop;
import '../services/api_service.dart';
import '../theme/theme_colours.dart';

class CartCounter {
  static final ValueNotifier<int> count = ValueNotifier<int>(0);

  static Future<void> refreshFromApi() async {
    try {
      final items = await ApiService.getCartItems();
      count.value = items.length;
    } catch (_) {}
  }
}

class ByteCartAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onCartTap;
  final String? logoAssetPath;

  const ByteCartAppBar({
    super.key,
    required this.title,
    this.onCartTap,
    this.logoAssetPath,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: _Logo(assetPath: logoAssetPath),
          ),
          Semantics(label: title, child: const SizedBox.shrink()),
        ],
      ),
      actions: [
        if (onCartTap != null)
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: ValueListenableBuilder<int>(
              valueListenable: CartCounter.count,
              builder:
                  (context, cartCount, _) =>
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart_outlined),
                        onPressed: onCartTap,
                        tooltip: 'Cart',
                      ),
                      if (cartCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: kMainColour,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                Theme
                                    .of(
                                  context,
                                )
                                    .appBarTheme
                                    .backgroundColor ??
                                    Colors.transparent,
                                width: 1,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${cartCount > 99 ? '99+' : cartCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
            ),
          ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  final String? assetPath;

  const _Logo({this.assetPath});

  @override
  Widget build(BuildContext context) {
    final size = Theme
        .of(context)
        .iconTheme
        .size ?? 24;
    final path = assetPath ?? 'assets/images/logo.webp';
    return Image.asset(
      path,
      height: size + 10,
      errorBuilder: (_, __, ___) => Icon(Icons.storefront_outlined, size: size),
    );
  }
}

class ByteCartBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const ByteCartBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[900]! : Colors.grey[100]!;
    final itemColor = isDark ? Colors.white : Colors.black;
    final selectedColor = const Color(0xFF0479FF);
    final selectedBgColor = selectedColor.withOpacity(isDark ? 0.24 : 0.12);

    return Theme(
      data: Theme.of(context).copyWith(
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: BottomNavigationBar(
        backgroundColor: bgColor,
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedItemColor: selectedColor,
        unselectedItemColor: itemColor,
        selectedIconTheme: const IconThemeData(color: Color(0xFF0479FF)),
        selectedLabelStyle: const TextStyle(
          color: Color(0xFF0479FF),
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(color: itemColor),
        items: [
          _navItem(
            Icons.home_outlined,
            'Home',
            currentIndex == 0,
            selectedBgColor,
          ),
          _navItem(
            Icons.storefront_outlined,
            'Shop',
            currentIndex == 1,
            selectedBgColor,
          ),
          _navItem(Icons.search, 'Search', currentIndex == 2, selectedBgColor),
          _navItem(
            Icons.person_outline,
            'Account',
            currentIndex == 3,
            selectedBgColor,
          ),
        ],
      ),
    );
  }

  BottomNavigationBarItem _navItem(IconData icon,
      String label,
      bool selected,
      Color selectedBgColor,) {
    return BottomNavigationBarItem(
      icon: Container(
        decoration:
        selected
            ? BoxDecoration(
          color: selectedBgColor,
          borderRadius: BorderRadius.circular(8),
        )
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Icon(icon),
      ),
      label: label,
    );
  }
}

class ByteCartShell extends StatefulWidget {
  final int initialIndex;
  final String? logoAssetPath;
  final List<Widget>? pages;
  final List<String>? titles;

  const ByteCartShell({
    super.key,
    this.initialIndex = 0,
    this.logoAssetPath,
    this.pages,
    this.titles,
  });

  @override
  State<ByteCartShell> createState() => _ByteCartShellState();
}

class _ByteCartShellState extends State<ByteCartShell> {
  late int _currentIndex;
  late List<String> _titles;
  late List<Widget> _pages;

  bool _shopShouldReset = false;
  bool _searchShouldReset = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _titles = widget.titles ?? const ['Home', 'Shop', 'Search', 'Account'];
    _pages =
        widget.pages ??
            [
              const Placeholder(key: PageStorageKey('Home')),
              shop.ShopPage(key: UniqueKey()),
              search.SearchPage(key: UniqueKey()),
              const AccountPage(key: PageStorageKey('Account')),
            ];
    CartCounter.refreshFromApi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ByteCartAppBar(
        title: _titles[_currentIndex],
        logoAssetPath: widget.logoAssetPath,
        onCartTap: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CartPage()));
          CartCounter.refreshFromApi();
        },
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: ByteCartBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() {
            if (_currentIndex == 1 && i != 1) _shopShouldReset = true;
            if (_currentIndex == 2 && i != 2) _searchShouldReset = true;

            _currentIndex = i;

            if (widget.pages == null) {
              if (i == 1) {
                _pages[1] = shop.ShopPage(key: UniqueKey());
              } else if (i == 2) {
                _pages[2] = search.SearchPage(key: UniqueKey());
              }
            }

            if (i == 1 && _shopShouldReset) {
              _shopShouldReset = false;
              _pages[1] = shop.ShopPage(key: UniqueKey());
            }
            if (i == 2 && _searchShouldReset) {
              _searchShouldReset = false;
              _pages[2] = search.SearchPage(key: UniqueKey());
            }
          });
          CartCounter.refreshFromApi();
        },
      ),
    );
  }
}
