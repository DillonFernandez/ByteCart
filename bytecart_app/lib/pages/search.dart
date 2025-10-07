import 'dart:async';

import 'package:bytecart_app/models/product.dart';
import 'package:bytecart_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/productcard.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  Widget build(BuildContext context) {
    return SearchStyledPage(initialQuery: initialQuery);
  }
}

class SearchStyledPage extends StatefulWidget {
  const SearchStyledPage({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  State<SearchStyledPage> createState() => _SearchStyledPageState();
}

class _SearchStyledPageState extends State<SearchStyledPage>
    with TickerProviderStateMixin {
  static const String _historyKey = 'search_history';
  List<Product> _products = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _hasSearched = false;

  List<String> _history = [];
  int _searchSeq = 0;

  String? _errorMessage;
  String? _lastQuery;

  // Animation controllers for smooth transitions
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
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

    _loadHistory();

    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      final q = widget.initialQuery!.trim();
      _searchController.text = q;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _search(q);
      });
    }

    _fadeController.forward();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _search(String query, {bool showInlineLoading = true}) async {
    FocusScope.of(context).unfocus();

    final q = query.trim();
    if (q.isEmpty) {
      if (!mounted) return;
      setState(() {
        _products = [];
        _isLoading = false;
        _hasSearched = false;
        _errorMessage = null;
      });
      _slideController.reset();
      return;
    }

    final currentSeq = ++_searchSeq;
    if (!mounted) return;
    setState(() {
      _lastQuery = q;
      _errorMessage = null;
      if (showInlineLoading) _isLoading = true;
      _hasSearched = true;
    });

    // Start slide animation when loading
    if (showInlineLoading) {
      _slideController.reset();
    }

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
      } on TimeoutException catch (e) {
        lastError = e;
      } catch (e) {
        lastError = e;
      }
      await Future.delayed(Duration(milliseconds: 250 * (attempt + 1)));
    }

    if (!mounted || currentSeq != _searchSeq) return;

    if (lastError != null) {
      setState(() {
        _errorMessage = "$lastError";
        _products = [];
        if (showInlineLoading) _isLoading = false;
      });
      return;
    }

    setState(() {
      _products = products;
      _errorMessage = null;
      if (showInlineLoading) _isLoading = false;
    });

    // Animate results in
    if (products.isNotEmpty) {
      _slideController.forward();
    }

    _addToHistory(q);
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final q = value.trim();

    setState(() {
      _errorMessage = null;
    });

    if (q.length < 2) {
      setState(() {
        _hasSearched = false;
        _products = [];
        _isLoading = false;
      });
      _slideController.reset();
      return;
    }
  }

  Widget _buildModernSearchField(BuildContext context) {
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
        controller: _searchController,
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
              _searchController.text.isEmpty
                  ? null
                  : IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: Colors.grey[500],
                      size: 20,
                    ),
                    onPressed: () {
                      _debounce?.cancel();
                      _searchController.clear();
                      setState(() {
                        _hasSearched = false;
                        _isLoading = false;
                        _products = [];
                        _errorMessage = null;
                      });
                      _slideController.reset();
                    },
                  ),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (v) {
          _debounce?.cancel();
          final q = v.trim();
          if (q.isEmpty) {
            setState(() {
              _hasSearched = false;
              _products = [];
              _errorMessage = null;
            });
            return;
          }
          setState(() => _errorMessage = null);
          _search(q);
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
    if (_history.isEmpty) return const SizedBox.shrink();

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
                _history.map((q) {
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _searchController.text = q;
                        _searchController.selection = TextSelection.collapsed(
                          offset: q.length,
                        );
                        _search(q);
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
                              onTap: () => _removeFromHistory(q),
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
    final count = _products.length;
    final query = _lastQuery ?? '';

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

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Something went wrong',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              final q = _lastQuery ?? _searchController.text.trim();
              if (q.isNotEmpty) {
                _search(q);
              }
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0479FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(Color(0xFF0479FF)),
          ),
          SizedBox(height: 16),
          Text(
            'Searching...',
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_historyKey) ?? const <String>[];
    if (!mounted) return;
    setState(() {
      _history = list.take(4).toList();
    });
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, _history);
  }

  void _addToHistory(String q) {
    if (q.isEmpty) return;
    setState(() {
      _history.removeWhere((e) => e.toLowerCase() == q.toLowerCase());
      _history.insert(0, q);
      if (_history.length > 4) {
        _history = _history.sublist(0, 4);
      }
    });
    _saveHistory();
  }

  void _removeFromHistory(String q) {
    setState(() {
      _history.removeWhere((e) => e.toLowerCase() == q.toLowerCase());
    });
    _saveHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          final q = _searchController.text.trim();
          if (_hasSearched && q.isNotEmpty) {
            await _search(q, showInlineLoading: false);
          }
        },
        edgeOffset: 16,
        color: const Color(0xFF0479FF),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: _buildWelcomeSection(),
              ),
            ),

            // Search field
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildModernSearchField(context),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Content based on state
            if (_errorMessage != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildErrorState(),
                ),
              )
            else if (_isLoading)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildLoadingState(),
              )
            else if (!_hasSearched)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildTrendingSection(),
                ),
              )
            else if (_products.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildEmptyState(),
                ),
              )
            else ...[
              // Results header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildResultsHeader(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Results grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 200 + (index * 50)),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.easeOutCubic,
                      builder: (context, animation, child) {
                        return Transform.scale(
                          scale: 0.8 + (0.2 * animation),
                          child: Opacity(
                            opacity: animation,
                            child: ProductCard(product: _products[index]),
                          ),
                        );
                      },
                    );
                  }, childCount: _products.length),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ],
        ),
      ),
    );
  }
}
