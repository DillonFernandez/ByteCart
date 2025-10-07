import 'dart:async';

import 'package:bytecart_app/models/product.dart';
import 'package:bytecart_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/productcard.dart';

class SearchState {
  final List<Product> products;
  final bool isLoading;
  final bool hasSearched;
  final List<String> history;
  final String? errorMessage;
  final String? lastQuery;

  SearchState({
    this.products = const [],
    this.isLoading = false,
    this.hasSearched = false,
    this.history = const [],
    this.errorMessage,
    this.lastQuery,
  });

  SearchState copyWith({
    List<Product>? products,
    bool? isLoading,
    bool? hasSearched,
    List<String>? history,
    String? errorMessage,
    String? lastQuery,
  }) {
    return SearchState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      hasSearched: hasSearched ?? this.hasSearched,
      history: history ?? this.history,
      errorMessage: errorMessage,
      lastQuery: lastQuery ?? this.lastQuery,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  static const String _historyKey = 'search_history';
  int _searchSeq = 0;

  SearchNotifier() : super(SearchState()) {
    _loadHistory();
  }

  Future<void> search(String query, {bool showInlineLoading = true}) async {
    final q = query.trim();
    if (q.isEmpty) {
      state = state.copyWith(
        products: [],
        isLoading: false,
        hasSearched: false,
        errorMessage: null,
        lastQuery: null,
      );
      return;
    }

    final currentSeq = ++_searchSeq;
    state = state.copyWith(
      lastQuery: q,
      errorMessage: null,
      isLoading: showInlineLoading,
      hasSearched: true,
    );

    List<Product> products = [];
    Object? lastError;

    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final res = await ApiService.searchProducts(
          q,
        ).timeout(const Duration(seconds: 10));
        products = res;
        lastError = null;
        break;
      } on TimeoutException {
        lastError =
            'Connection timed out. Please check your internet connection.';
      } catch (_) {
        lastError = 'Unable to connect. Please check your internet connection.';
      }
      await Future.delayed(Duration(milliseconds: 250 * (attempt + 1)));
    }

    if (currentSeq != _searchSeq) return;

    if (lastError != null) {
      state = state.copyWith(
        errorMessage: lastError as String,
        products: [],
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(
      products: products,
      errorMessage: null,
      isLoading: false,
    );

    _addToHistory(q);
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_historyKey) ?? const <String>[];
    state = state.copyWith(history: list.take(4).toList());
  }

  Future<void> _saveHistory(List<String> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, history);
  }

  void _addToHistory(String q) {
    if (q.isEmpty) return;
    final updated = List<String>.from(state.history);
    updated.removeWhere((e) => e.toLowerCase() == q.toLowerCase());
    updated.insert(0, q);
    if (updated.length > 4) {
      updated.removeRange(4, updated.length);
    }
    state = state.copyWith(history: updated);
    _saveHistory(updated);
  }

  void removeFromHistory(String q) {
    final updated = List<String>.from(state.history);
    updated.removeWhere((e) => e.toLowerCase() == q.toLowerCase());
    state = state.copyWith(history: updated);
    _saveHistory(updated);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void resetSearch() {
    state = state.copyWith(
      products: [],
      isLoading: false,
      hasSearched: false,
      errorMessage: null,
      lastQuery: null,
    );
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>(
  (ref) => SearchNotifier(),
);

final searchTextControllerProvider =
    Provider.autoDispose<TextEditingController>(
      (ref) => TextEditingController(),
    );

class SearchPage extends StatelessWidget {
  const SearchPage({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(child: SearchStyledPage(initialQuery: initialQuery));
  }
}

class SearchStyledPage extends ConsumerStatefulWidget {
  const SearchStyledPage({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<SearchStyledPage> createState() => _SearchStyledPageState();
}

class _SearchStyledPageState extends ConsumerState<SearchStyledPage>
    with TickerProviderStateMixin {
  Timer? _debounce;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      final q = widget.initialQuery!.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchTextControllerProvider).text = q;
        ref.read(searchProvider.notifier).search(q);
      });
    }

    _fadeController.forward();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final q = value.trim();

    ref.read(searchProvider.notifier).clearError();

    if (q.length < 2) {
      ref.read(searchProvider.notifier).resetSearch();
      _slideController.reset();
      return;
    }
  }

  Widget _buildModernSearchField(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controller = ref.watch(searchTextControllerProvider);

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
        controller: controller,
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
              controller.text.isEmpty
                  ? null
                  : IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: Colors.grey[500],
                      size: 20,
                    ),
                    onPressed: () {
                      _debounce?.cancel();
                      controller.clear();
                      ref.read(searchProvider.notifier).resetSearch();
                      _slideController.reset();
                    },
                  ),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (v) {
          _debounce?.cancel();
          final q = v.trim();
          if (q.isEmpty) {
            ref.read(searchProvider.notifier).resetSearch();
            return;
          }
          ref.read(searchProvider.notifier).clearError();
          ref.read(searchProvider.notifier).search(q);
        },
        onChanged: _onQueryChanged,
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find what you need 🔍',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Search through thousands of products',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingSection() {
    final history = ref.watch(searchProvider).history;
    if (history.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0479FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: Color(0xFF0479FF),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Recent Searches',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                history.map((q) {
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        ref.read(searchTextControllerProvider).text = q;
                        ref.read(searchTextControllerProvider).selection =
                            TextSelection.collapsed(offset: q.length);
                        ref.read(searchProvider.notifier).search(q);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                isDark ? Colors.grey[700]! : Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              q,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap:
                                  () => ref
                                      .read(searchProvider.notifier)
                                      .removeFromHistory(q),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    final theme = Theme.of(context);
    final state = ref.watch(searchProvider);
    final count = state.products.length;
    final query = state.lastQuery ?? '';

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: Colors.green[600],
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Found $count result${count != 1 ? 's' : ''}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (query.isNotEmpty)
                      Text(
                        'for "$query"',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No products found',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(searchProvider);

    final String message =
        state.errorMessage ??
        'Unable to connect. Please check your internet connection and try again.';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? Colors.red[900]?.withOpacity(0.15) : Colors.red[50],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.red[900]?.withOpacity(0.25)
                        : Colors.red[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: isDark ? Colors.red[200] : Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Connection Issue',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.red[100] : Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.red[100] : Colors.red[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final q =
                    state.lastQuery ??
                    ref.read(searchTextControllerProvider).text.trim();
                if (q.isNotEmpty) {
                  ref.read(searchProvider.notifier).search(q);
                }
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0479FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(
              isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Searching...',
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final state = ref.watch(searchProvider);
    final controller = ref.watch(searchTextControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body:
          isLandscape
              ? _buildLandscapeBody()
              : RefreshIndicator(
                onRefresh: () async {
                  final q = controller.text.trim();
                  if (state.hasSearched && q.isNotEmpty) {
                    await ref
                        .read(searchProvider.notifier)
                        .search(q, showInlineLoading: false);
                  }
                },
                edgeOffset: 16,
                color: isDark ? Colors.white : Colors.black,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      sliver: SliverToBoxAdapter(child: _buildWelcomeSection()),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildModernSearchField(context),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      sliver: SliverToBoxAdapter(
                        child: _buildTrendingSection(),
                      ),
                    ),
                    if (state.errorMessage != null)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildErrorState(),
                        ),
                      )
                    else if (state.isLoading)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildLoadingState(),
                      )
                    else if (!state.hasSearched)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.search_rounded,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Start typing to search products',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (state.products.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildEmptyState(),
                        ),
                      )
                    else ...[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: _buildResultsHeader(),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.65,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            return TweenAnimationBuilder<double>(
                              duration: Duration(
                                milliseconds: 200 + (index * 50),
                              ),
                              tween: Tween(begin: 0.0, end: 1.0),
                              curve: Curves.easeOutCubic,
                              builder: (context, animation, child) {
                                return Transform.scale(
                                  scale: 0.8 + (0.2 * animation),
                                  child: Opacity(
                                    opacity: animation,
                                    child: ProductCard(
                                      product: state.products[index],
                                    ),
                                  ),
                                );
                              },
                            );
                          }, childCount: state.products.length),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
    );
  }

  Widget _buildLandscapeBody() {
    final state = ref.watch(searchProvider);
    final controller = ref.watch(searchTextControllerProvider);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showTwoPane = constraints.maxWidth >= 820;
          const gap = 24.0;

          if (!showTwoPane) {
            return ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(overscroll: false),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLandscapeLeftPane(),
                    const SizedBox(height: gap),
                    _buildLandscapeRightPane(constraints.maxWidth),
                  ],
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 9,
                  child: ScrollConfiguration(
                    behavior: const ScrollBehavior().copyWith(
                      overscroll: false,
                    ),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: _buildLandscapeLeftPane(),
                    ),
                  ),
                ),
                const SizedBox(width: gap),
                Expanded(
                  flex: 11,
                  child: ScrollConfiguration(
                    behavior: const ScrollBehavior().copyWith(
                      overscroll: false,
                    ),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: _buildLandscapeRightPane(
                        (constraints.maxWidth - 16 - 16 - gap) * (11 / 20),
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

  Widget _buildLandscapeLeftPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: _buildWelcomeSection(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildModernSearchField(context),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildTrendingSection(),
        ),
      ],
    );
  }

  Widget _buildLandscapeRightPane(double availableWidth) {
    final state = ref.watch(searchProvider);

    if (state.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: _buildErrorState(),
      );
    }
    if (state.isLoading) {
      return _buildLoadingState();
    }
    if (!state.hasSearched) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: const [
            Icon(Icons.search_rounded, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Start typing to search products',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    if (state.products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: _buildEmptyState(),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildResultsHeader(),
          const SizedBox(height: 12),
          _resultsGridLandscape(availableWidth),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _resultsGridLandscape(double availableWidth) {
    final state = ref.watch(searchProvider);
    const int cols = 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.products.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 200 + (index * 50)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCubic,
          builder: (context, animation, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * animation),
              child: Opacity(
                opacity: animation,
                child: ProductCard(product: state.products[index]),
              ),
            );
          },
        );
      },
    );
  }
}
