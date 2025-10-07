import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../models/account_summary.dart';
import '../theme/theme_colours.dart';
import 'login.dart';
import 'legal_information.dart';
import 'orders.dart';
import 'wishlist.dart';
import 'payment_methods.dart';
import 'shipping_info.dart';
import 'account_settings.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late Future<Map<String, dynamic>> _futureDashboard;
  Future<AccountSummary>? _futureSummary;

  StreamSubscription<Map<String, String>>? _profileSub;
  String _profileName = '';
  String _profileEmail = '';

  final GlobalKey _orderCardKey = GlobalKey();
  final GlobalKey _wishCardKey = GlobalKey();
  final GlobalKey _shipCardKey = GlobalKey();
  final GlobalKey _payCardKey = GlobalKey();
  double? _row1Height;
  double? _row2Height;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _futureSummary = ApiService.getAccountSummary();

    _profileSub = ApiService.onProfileChanged.listen((m) {
      setState(() {
        _profileName = (m['name'] ?? '').trim();
        _profileEmail = (m['email'] ?? '').trim();
      });
    });
  }

  void _loadDashboard() {
    _futureDashboard = ApiService.getAccountDashboard();
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await _showLogoutDialog();
    if (!confirmed) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');

    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<bool> _showLogoutDialog() async {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final popupBg = isDark ? Colors.grey[900] : Colors.grey[100];

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Center(
            child: Dialog(
              backgroundColor: popupBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 35,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 412.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sign Out',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: scheme.onBackground,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Are you sure you want to sign out of your account?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onBackground.withOpacity(0.85),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: TextButton.styleFrom(
                              foregroundColor: scheme.onBackground.withOpacity(
                                0.7,
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
    return result ?? false;
  }

  void _syncRowHeights() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final o = _orderCardKey.currentContext?.size?.height ?? 0;
      final w = _wishCardKey.currentContext?.size?.height ?? 0;
      final s = _shipCardKey.currentContext?.size?.height ?? 0;
      final p = _payCardKey.currentContext?.size?.height ?? 0;
      final r1 = o > w ? o : w;
      final r2 = s > p ? s : p;
      if ((r1 > 0 && r1 != _row1Height) || (r2 > 0 && r2 != _row2Height)) {
        setState(() {
          _row1Height = r1;
          _row2Height = r2;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.background,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureDashboard,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
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
                    'Something went wrong',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${snapshot.error}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onBackground.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _loadDashboard();
                        _futureSummary = ApiService.getAccountSummary();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kMainColour,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final user = data['user'];

          final orientation = MediaQuery.of(context).orientation;
          if (orientation == Orientation.landscape) {
            return _buildLandscapeLayout(context, data);
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kMainColour.withOpacity(0.1),
                        kMainColour.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kMainColour.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kMainColour.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.person, color: kMainColour, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back!',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onBackground.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _resolveName(user),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scheme.onBackground,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _resolveEmail(user),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onBackground.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _logout(context),
                        icon: const Icon(Icons.logout_rounded),
                        color: Colors.red,
                        tooltip: 'Sign Out',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Overview',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<AccountSummary>(
                        future: _futureSummary,
                        builder: (context, sSnap) {
                          if (sSnap.connectionState ==
                              ConnectionState.waiting) {
                            return _buildSkeletonCards();
                          }

                          final s = sSnap.data;
                          return _buildSummaryCards(context, s, data);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildQuickActions(context),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appearance',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildAppearanceSection(context),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Legal & Support',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLegalSection(context),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSkeletonCards() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final shimmerBase = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      primary: false,
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: List.generate(4, (index) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: shimmerBase,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 80,
                height: 14,
                decoration: BoxDecoration(
                  color: shimmerBase,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 60,
                height: 20,
                decoration: BoxDecoration(
                  color: shimmerBase,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    AccountSummary? s,
    Map<String, dynamic> data,
  ) {
    final orders = data['orders'];
    final wishlist = data['wishlist'];
    final user = data['user'];

    final ordersMain = s != null ? "${s.ordersTotal}" : "${orders['total']}";
    final wishMain = s != null ? "${s.wishCount}" : "${wishlist['count']}";
    final shippingMain =
        s != null
            ? (s.shippingComplete ? "Complete" : "Incomplete")
            : (user['shipping_complete'] ? "Complete" : "Incomplete");
    final paymentMain =
        s != null
            ? (s.paymentMethod ?? "Not set")
            : (user['payment_method'] ?? "Not set");

    final ordersSub =
        s != null
            ? [
              "Active: ${s.ordersActive}",
              "Completed: ${s.ordersCompleted}",
              s.latestOrderNumber != null
                  ? "Latest: #${s.latestOrderNumber} ${_ucFirst(s.latestOrderStatus ?? '')}"
                      "${s.latestOrderDateHuman != null ? ' • ${s.latestOrderDateHuman}' : ''}"
                  : "No orders yet",
            ].join("\n")
            : "Active: ${orders['active']}";

    final wishSub =
        s != null
            ? (s.wishCount > 0
                ? "You have ${s.wishCount} saved"
                : "No saved items")
            : "Saved items";

    final shippingSub =
        s != null
            ? "Billing: ${s.billingSameAsShipping ? 'Same as Shipping' : (s.billingComplete ? 'Complete' : 'Incomplete')}"
            : null;

    final paymentSub =
        s != null
            ? ((s.paymentMethod == 'Visa/MasterCard' && s.cardSaved)
                ? "Card saved"
                : "No card info")
            : (user['has_saved_card'] ? "Card saved" : "No card info");

    final double avail = MediaQuery.sizeOf(context).width - 32;
    final double cardW = (avail - 12) / 2;

    _syncRowHeights();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: cardW,
          child: ConstrainedBox(
            constraints:
                _row1Height != null
                    ? BoxConstraints(minHeight: _row1Height!)
                    : const BoxConstraints(),
            child: _summaryCard(
              context,
              title: "Orders",
              icon: Icons.receipt_long_rounded,
              mainValue: ordersMain,
              subText: ordersSub,
              color: Colors.blue,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrdersPage()),
                  ),
              containerKey: _orderCardKey,
            ),
          ),
        ),
        SizedBox(
          width: cardW,
          child: ConstrainedBox(
            constraints:
                _row1Height != null
                    ? BoxConstraints(minHeight: _row1Height!)
                    : const BoxConstraints(),
            child: _summaryCard(
              context,
              title: "Wish List",
              icon: Icons.favorite_rounded,
              mainValue: wishMain,
              subText: wishSub,
              color: Colors.pink,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WishlistPage()),
                  ),
              containerKey: _wishCardKey,
            ),
          ),
        ),
        SizedBox(
          width: cardW,
          child: ConstrainedBox(
            constraints:
                _row2Height != null
                    ? BoxConstraints(minHeight: _row2Height!)
                    : const BoxConstraints(),
            child: _summaryCard(
              context,
              title: "Shipping",
              icon: Icons.local_shipping_rounded,
              mainValue: shippingMain,
              subText: shippingSub ?? '',
              color: shippingMain == "Complete" ? Colors.green : Colors.orange,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ShippingInfoPage()),
                  ),
              containerKey: _shipCardKey,
            ),
          ),
        ),
        SizedBox(
          width: cardW,
          child: ConstrainedBox(
            constraints:
                _row2Height != null
                    ? BoxConstraints(minHeight: _row2Height!)
                    : const BoxConstraints(),
            child: _summaryCard(
              context,
              title: "Payment",
              icon: Icons.credit_card_rounded,
              mainValue: paymentMain,
              subText: paymentSub,
              color: paymentMain == "Not set" ? Colors.orange : Colors.teal,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PaymentMethodsPage(),
                    ),
                  ),
              containerKey: _payCardKey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String mainValue,
    required String subText,
    required Color color,
    VoidCallback? onTap,
    Key? containerKey,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          key: containerKey,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onBackground.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mainValue,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withOpacity(0.75),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _ActionItem(
        icon: Icons.receipt_long_outlined,
        label: "Order History",
        color: Colors.orange,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrdersPage()),
            ),
      ),
      _ActionItem(
        icon: Icons.favorite_border_rounded,
        label: "Wish List",
        color: Colors.pink,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WishlistPage()),
            ),
      ),
      _ActionItem(
        icon: Icons.credit_card_outlined,
        label: "Payment Methods",
        color: Colors.purple,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaymentMethodsPage()),
            ),
      ),
      _ActionItem(
        icon: Icons.location_on_outlined,
        label: "Addresses",
        color: Colors.green,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShippingInfoPage()),
            ),
      ),
      _ActionItem(
        icon: Icons.person_outline_rounded,
        label: "Profile & Security",
        color: Colors.blue,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountSettingsPage()),
            ),
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      primary: false,
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children:
          actions.map((action) => _quickActionCard(context, action)).toList(),
    );
  }

  Widget _quickActionCard(BuildContext context, _ActionItem action) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final Color iconColor = isDark ? Colors.white : Colors.black;
    final Color iconBg =
        isDark
            ? Colors.white.withOpacity(0.10)
            : Colors.black.withOpacity(0.06);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(action.icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  action.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onBackground,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onBackground.withOpacity(0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegalSection(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final Color iconColor = isDark ? Colors.white : Colors.black;
    final Color iconBg =
        isDark
            ? Colors.white.withOpacity(0.10)
            : Colors.black.withOpacity(0.06);

    final legalItems = [
      _LegalItem(
        icon: Icons.description_outlined,
        title: "Terms & Conditions",
        subtitle: "Review our terms of service",
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LegalInformationPage(),
                settings: const RouteSettings(arguments: 0),
              ),
            ),
      ),
      _LegalItem(
        icon: Icons.privacy_tip_outlined,
        title: "Privacy Policy",
        subtitle: "Learn how we protect your data",
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LegalInformationPage(),
                settings: const RouteSettings(arguments: 1),
              ),
            ),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children:
            legalItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == legalItems.length - 1;

              return Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: item.onTap,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: iconBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                item.icon,
                                color: iconColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: scheme.onBackground,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.subtitle,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onBackground.withOpacity(
                                        0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: scheme.onBackground.withOpacity(0.4),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: isDark ? Colors.white12 : Colors.black12,
                      indent: 56,
                    ),
                ],
              );
            }).toList(),
      ),
    );
  }

  String _ucFirst(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Widget _buildLandscapeLayout(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = data['user'];

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double gap = 20.0;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 9,
                  child: LayoutBuilder(
                    builder: (context, leftCons) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLandscapeHeaderCard(context, user),
                            const SizedBox(height: 20),
                            Text(
                              'Quick Actions',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scheme.onBackground,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildLandscapeQuickActions(
                              context,
                              leftCons.maxWidth,
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
                  child: LayoutBuilder(
                    builder: (context, rightCons) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Account Overview',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: scheme.onBackground,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FutureBuilder<AccountSummary>(
                                future: _futureSummary,
                                builder: (context, sSnap) {
                                  if (sSnap.connectionState ==
                                      ConnectionState.waiting) {
                                    return _buildSkeletonCards();
                                  }
                                  final s = sSnap.data;
                                  return _buildSummaryCardsLandscape(
                                    context,
                                    s,
                                    data,
                                    rightCons.maxWidth,
                                  );
                                },
                              ),
                              const SizedBox(height: 28),

                              Text(
                                'Appearance',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: scheme.onBackground,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildAppearanceSection(context),
                              const SizedBox(height: 28),

                              Text(
                                'Legal & Support',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: scheme.onBackground,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildLegalSection(context),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLandscapeHeaderCard(
    BuildContext context,
    Map<String, dynamic> user,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kMainColour.withOpacity(0.1), kMainColour.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kMainColour.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: kMainColour.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.person, color: kMainColour, size: 36),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onBackground.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _resolveName(user),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onBackground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _resolveEmail(user),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onBackground.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
            color: Colors.red,
            tooltip: 'Sign Out',
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeQuickActions(
    BuildContext context,
    double availableWidth,
  ) {
    final actions = [
      _ActionItem(
        icon: Icons.receipt_long_outlined,
        label: "Order History",
        color: Colors.orange,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrdersPage()),
            ),
      ),
      _ActionItem(
        icon: Icons.favorite_border_rounded,
        label: "Wish List",
        color: Colors.pink,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WishlistPage()),
            ),
      ),
      _ActionItem(
        icon: Icons.credit_card_outlined,
        label: "Payment Methods",
        color: Colors.purple,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaymentMethodsPage()),
            ),
      ),
      _ActionItem(
        icon: Icons.location_on_outlined,
        label: "Addresses",
        color: Colors.green,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShippingInfoPage()),
            ),
      ),
      _ActionItem(
        icon: Icons.person_outline_rounded,
        label: "Profile & Security",
        color: Colors.blue,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountSettingsPage()),
            ),
      ),
    ];

    int cols;
    if (availableWidth < 420) {
      cols = 1;
    } else if (availableWidth < 760) {
      cols = 2;
    } else {
      cols = 2;
    }
    const spacing = 12.0;
    final itemWidth = (availableWidth - spacing * (cols - 1)) / cols;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children:
          actions
              .map(
                (a) => SizedBox(
                  width: itemWidth,
                  child: _quickActionCard(context, a),
                ),
              )
              .toList(),
    );
  }

  Widget _buildSummaryCardsLandscape(
    BuildContext context,
    AccountSummary? s,
    Map<String, dynamic> data,
    double availableWidth,
  ) {
    final orders = data['orders'];
    final wishlist = data['wishlist'];
    final user = data['user'];

    final ordersMain = s != null ? "${s.ordersTotal}" : "${orders['total']}";
    final wishMain = s != null ? "${s.wishCount}" : "${wishlist['count']}";
    final shippingMain =
        s != null
            ? (s.shippingComplete ? "Complete" : "Incomplete")
            : (user['shipping_complete'] ? "Complete" : "Incomplete");
    final paymentMain =
        s != null
            ? (s.paymentMethod ?? "Not set")
            : (user['payment_method'] ?? "Not set");

    final ordersSub =
        s != null
            ? [
              "Active: ${s.ordersActive}",
              "Completed: ${s.ordersCompleted}",
              s.latestOrderNumber != null
                  ? "Latest: #${s.latestOrderNumber} ${_ucFirst(s.latestOrderStatus ?? '')}"
                      "${s.latestOrderDateHuman != null ? ' • ${s.latestOrderDateHuman}' : ''}"
                  : "No orders yet",
            ].join("\n")
            : "Active: ${orders['active']}";

    final wishSub =
        s != null
            ? (s.wishCount > 0
                ? "You have ${s.wishCount} saved"
                : "No saved items")
            : "Saved items";

    final shippingSub =
        s != null
            ? "Billing: ${s.billingSameAsShipping ? 'Same as Shipping' : (s.billingComplete ? 'Complete' : 'Incomplete')}"
            : null;

    final paymentSub =
        s != null
            ? ((s.paymentMethod == 'Visa/MasterCard' && s.cardSaved)
                ? "Card saved"
                : "No card info")
            : (user['has_saved_card'] ? "Card saved" : "No card info");

    int cols;
    if (availableWidth < 520) {
      cols = 1;
    } else if (availableWidth < 1000) {
      cols = 2;
    } else {
      cols = 3;
    }
    const spacing = 16.0;
    final cardW = (availableWidth - spacing * (cols - 1)) / cols;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        SizedBox(
          width: cardW,
          child: _summaryCard(
            context,
            title: "Orders",
            icon: Icons.receipt_long_rounded,
            mainValue: ordersMain,
            subText: ordersSub,
            color: Colors.blue,
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrdersPage()),
                ),
          ),
        ),
        SizedBox(
          width: cardW,
          child: _summaryCard(
            context,
            title: "Wish List",
            icon: Icons.favorite_rounded,
            mainValue: wishMain,
            subText: wishSub,
            color: Colors.pink,
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WishlistPage()),
                ),
          ),
        ),
        SizedBox(
          width: cardW,
          child: _summaryCard(
            context,
            title: "Shipping",
            icon: Icons.local_shipping_rounded,
            mainValue: shippingMain,
            subText: shippingSub ?? '',
            color: shippingMain == "Complete" ? Colors.green : Colors.orange,
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShippingInfoPage()),
                ),
          ),
        ),
        SizedBox(
          width: cardW,
          child: _summaryCard(
            context,
            title: "Payment",
            icon: Icons.credit_card_rounded,
            mainValue: paymentMain,
            subText: paymentSub,
            color: paymentMain == "Not set" ? Colors.orange : Colors.teal,
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaymentMethodsPage()),
                ),
          ),
        ),
      ],
    );
  }

  String _resolveName(Map<String, dynamic> user) {
    final n = _profileName.trim();
    if (n.isNotEmpty) return n;
    return user['first_name'] ?? user['name'] ?? 'User';
  }

  String _resolveEmail(Map<String, dynamic> user) {
    final e = _profileEmail.trim();
    if (e.isNotEmpty) return e;
    return user['email'] ?? '';
  }

  Widget _buildAppearanceSection(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final Color iconColor = isDark ? Colors.white : Colors.black;
    final Color iconBg =
        isDark
            ? Colors.white.withOpacity(0.10)
            : Colors.black.withOpacity(0.06);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _showThemePicker,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.brightness_6_rounded,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      ValueListenableBuilder<ThemeMode>(
                        valueListenable: themeModeNotifier,
                        builder:
                            (_, m, __) => Text(
                              _themeModeLabel(m),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onBackground.withOpacity(0.6),
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onBackground.withOpacity(0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showThemePicker() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeModeNotifier,
              builder: (context, current, __) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text(
                        'Choose Theme',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.system,
                      groupValue: current,
                      onChanged: (v) async {
                        if (v == null) return;
                        await setAppThemeMode(v);
                        if (mounted) Navigator.pop(context);
                      },
                      title: const Text('System default'),
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.light,
                      groupValue: current,
                      onChanged: (v) async {
                        if (v == null) return;
                        await setAppThemeMode(v);
                        if (mounted) Navigator.pop(context);
                      },
                      title: const Text('Light'),
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.dark,
                      groupValue: current,
                      onChanged: (v) async {
                        if (v == null) return;
                        await setAppThemeMode(v);
                        if (mounted) Navigator.pop(context);
                      },
                      title: const Text('Dark'),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _themeModeLabel(ThemeMode m) {
    switch (m) {
      case ThemeMode.system:
        return 'System default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _LegalItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _LegalItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
