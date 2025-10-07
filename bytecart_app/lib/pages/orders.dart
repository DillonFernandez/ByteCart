import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/api_service.dart';
import 'package:bytecart_app/theme/theme_colours.dart';

class OrdersState {
  final bool loading;
  final List<Map<String, dynamic>> orders;
  final String? error;
  final bool connectionError;
  final String? success;

  OrdersState({
    this.loading = false,
    this.orders = const [],
    this.error,
    this.connectionError = false,
    this.success,
  });

  OrdersState copyWith({
    bool? loading,
    List<Map<String, dynamic>>? orders,
    String? error,
    bool? connectionError,
    String? success,
  }) =>
      OrdersState(
        loading: loading ?? this.loading,
        orders: orders ?? this.orders,
        error: error,
        connectionError: connectionError ?? false,
        success: success,
      );
}

class OrdersNotifier extends StateNotifier<OrdersState> {
  OrdersNotifier() : super(OrdersState(loading: true)) {
    loadOrders();
  }

  Future<void> loadOrders() async {
    state = state.copyWith(
      loading: true,
      error: null,
      connectionError: false,
      success: null,
    );
    try {
      final list = await ApiService.getOrders();
      state = state.copyWith(
        orders: list,
        loading: false,
        error: null,
        connectionError: false,
      );
    } catch (e) {
      final isConn = _isConnectionError(e);
      state = state.copyWith(
        loading: false,
        error:
        isConn
            ? "Connection error. Please check your internet and try again."
            : "Failed to load orders. Please try again.",
        connectionError: isConn,
      );
    }
  }

  Future<Map<String, dynamic>?> getOrderDetails(String id) async {
    try {
      final details = await ApiService.getOrderDetails(id);
      return details;
    } catch (e) {
      final isConn = _isConnectionError(e);
      state = state.copyWith(
        error:
        isConn
            ? "Connection error. Please check your internet and try again."
            : "Failed to load order details. Please try again.",
        connectionError: isConn,
      );
      return null;
    }
  }

  Future<bool> cancelOrder(String id) async {
    try {
      await ApiService.cancelOrder(id);
      state = state.copyWith(
        success: "Order cancelled successfully.",
        error: null,
        connectionError: false,
      );
      await loadOrders();
      return true;
    } catch (e) {
      final isConn = _isConnectionError(e);
      state = state.copyWith(
        error:
        isConn
            ? "Connection error. Please check your internet and try again."
            : "Failed to cancel order. Please try again.",
        connectionError: isConn,
      );
      return false;
    }
  }

  Future<bool> deliverOrder(String id) async {
    try {
      await ApiService.deliverOrder(id);
      state = state.copyWith(
        success: "Order marked as delivered.",
        error: null,
        connectionError: false,
      );
      await loadOrders();
      return true;
    } catch (e) {
      final isConn = _isConnectionError(e);
      state = state.copyWith(
        error:
        isConn
            ? "Connection error. Please check your internet and try again."
            : "Failed to mark as delivered. Please try again.",
        connectionError: isConn,
      );
      return false;
    }
  }

  void clearError() =>
      state = state.copyWith(error: null, connectionError: false);

  void clearSuccess() => state = state.copyWith(success: null);

  bool _isConnectionError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('socket') ||
        msg.contains('network') ||
        msg.contains('connection') ||
        msg.contains('timeout');
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>(
      (ref) => OrdersNotifier(),
);

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ordersProvider);
    final notifier = ref.read(ordersProvider.notifier);

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLandscape =
        MediaQuery
            .of(context)
            .orientation == Orientation.landscape;

    Widget? banner;
    if (state.error != null) {
      banner = _ErrorBanner(
        message: state.error!,
        isConnection: state.connectionError,
        onClose: notifier.clearError,
      );
    } else if (state.success != null) {
      banner = _SuccessBanner(
        message: state.success!,
        onClose: notifier.clearSuccess,
      );
    }

    if (state.loading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color:
            scheme.brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        title: const Text(
          'My Orders',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: scheme.background,
        foregroundColor: scheme.onBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            if (banner != null) banner,
            Expanded(
              child:
              isLandscape
                  ? _LandscapeOrdersView(
                state: state,
                notifier: notifier,
                ref: ref,
              )
                  : _PortraitOrdersView(
                state: state,
                notifier: notifier,
                ref: ref,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final bool isConnection;
  final VoidCallback onClose;

  const _ErrorBanner({
    required this.message,
    required this.isConnection,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme
        .of(context)
        .colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final bg = isDark ? Colors.red[900] : Colors.red[50];
    final fg = isDark ? Colors.white : Colors.red[900];
    return Material(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              isConnection ? Icons.wifi_off : Icons.error_outline,
              color: fg,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  message,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: fg),
              onPressed: onClose,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              tooltip: 'Dismiss',
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _SuccessBanner({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme
        .of(context)
        .colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final bg = isDark ? Colors.green[900] : Colors.green[50];
    final fg = isDark ? Colors.white : Colors.green[900];
    return Material(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.check_circle, color: fg),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  message,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: fg),
              onPressed: onClose,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              tooltip: 'Dismiss',
            ),
          ],
        ),
      ),
    );
  }
}

class _LandscapeOrdersView extends StatelessWidget {
  final OrdersState state;
  final OrdersNotifier notifier;
  final WidgetRef ref;

  const _LandscapeOrdersView({
    required this.state,
    required this.notifier,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme
        .of(context)
        .colorScheme;
    return LayoutBuilder(
      builder: (ctx, constraints) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: RefreshIndicator(
                    onRefresh: notifier.loadOrders,
                    color:
                    scheme.brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    child: ScrollConfiguration(
                      behavior: const ScrollBehavior().copyWith(
                        overscroll: false,
                      ),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: ClampingScrollPhysics(),
                        ),
                        child: _section(
                          context: context,
                          title: 'Recent Orders',
                          child:
                          state.orders.isEmpty
                              ? Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No orders yet",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onBackground,
                                  ),
                                ),
                                Text(
                                  "Your recent orders will appear here.",
                                  style: TextStyle(
                                    color: scheme.onBackground
                                        .withOpacity(0.75),
                                  ),
                                ),
                              ],
                            ),
                          )
                              : Column(
                            children: List.generate(state.orders.length, (i,) {
                              final o = state.orders[i];
                              return Card(
                                color: Colors.transparent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    16,
                                  ),
                                  side: BorderSide(
                                    color: scheme.onBackground
                                        .withOpacity(0.15),
                                  ),
                                ),
                                margin: const EdgeInsets.only(
                                  bottom: 12,
                                ),
                                child: ListTile(
                                  contentPadding:
                                  const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  title: Text(
                                    "Order #${o["order_number"]}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text("Date: ${o["placed_at"]}"),
                                      Text(
                                        "Payment: ${o["payment_method"]}",
                                      ),
                                      Text(
                                        "Items: ${o["items_count"]}",
                                      ),
                                    ],
                                  ),
                                  trailing: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "\$${o["total"]}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: _statusColor(
                                            o["status"],
                                          ).withOpacity(0.15),
                                          borderRadius:
                                          BorderRadius.circular(12),
                                        ),
                                        padding:
                                        const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        child: Text(
                                          o["status"],
                                          style: TextStyle(
                                            color: _statusColor(
                                              o["status"],
                                            ),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap:
                                      () =>
                                      _showOrderDetailsDialog(
                                        context,
                                        ref,
                                        o["id"],
                                      ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: ScrollConfiguration(
                    behavior: const ScrollBehavior().copyWith(
                      overscroll: false,
                    ),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: ClampingScrollPhysics(),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _section(
                            context: context,
                            title: 'Your Order History',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Track your purchases, view order details, and manage your shopping history. You can monitor order status, cancel pending orders, and confirm deliveries. All your order information is kept secure and easily accessible.',
                                  style: TextStyle(
                                    color: scheme.onBackground.withOpacity(
                                      0.85,
                                    ),
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'If an order is not marked as delivered after 2 months, it will be automatically marked as delivered.',
                                  style: TextStyle(
                                    color: Colors.red,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _section(
                            context: context,
                            title: 'Orders Help & Support',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _tip(
                                  context,
                                  'You can cancel an order while it is Pending or Processed.',
                                ),
                                const SizedBox(height: 8),
                                _tip(
                                  context,
                                  'Status flow: Pending → Processed → Shipped → Out for Delivery → Delivered.',
                                ),
                                const SizedBox(height: 8),
                                _tip(
                                  context,
                                  'Track items, quantities, and totals from the order details view.',
                                ),
                                const SizedBox(height: 8),
                                _tip(
                                  context,
                                  'Delivery times may vary by location; watch for email/SMS updates.',
                                ),
                                const SizedBox(height: 8),
                                _tip(
                                  context,
                                  'Need changes after placing an order? Contact support as soon as possible.',
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.support_agent),
                                    label: const Text('Contact Order Support'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: kMainColour,
                                      side: const BorderSide(
                                        color: kMainColour,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
    );
  }
}

class _PortraitOrdersView extends StatelessWidget {
  final OrdersState state;
  final OrdersNotifier notifier;
  final WidgetRef ref;

  const _PortraitOrdersView({
    required this.state,
    required this.notifier,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme
        .of(context)
        .colorScheme;
    return RefreshIndicator(
      onRefresh: notifier.loadOrders,
      color: scheme.brightness == Brightness.dark ? Colors.white : Colors.black,
      child: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _section(
                context: context,
                title: 'Your Order History',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Track your purchases, view order details, and manage your shopping history. You can monitor order status, cancel pending orders, and confirm deliveries. All your order information is kept secure and easily accessible.',
                      style: TextStyle(
                        color: scheme.onBackground.withOpacity(0.85),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'If an order is not marked as delivered after 2 months, it will be automatically marked as delivered.',
                      style: TextStyle(color: Colors.red, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _section(
                context: context,
                title: 'Orders Help & Support',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _tip(
                      context,
                      'You can cancel an order while it is Pending or Processed.',
                    ),
                    const SizedBox(height: 8),
                    _tip(
                      context,
                      'Status flow: Pending → Processed → Shipped → Out for Delivery → Delivered.',
                    ),
                    const SizedBox(height: 8),
                    _tip(
                      context,
                      'Track items, quantities, and totals from the order details view.',
                    ),
                    const SizedBox(height: 8),
                    _tip(
                      context,
                      'Delivery times may vary by location; watch for email/SMS updates.',
                    ),
                    const SizedBox(height: 8),
                    _tip(
                      context,
                      'Need changes after placing an order? Contact support as soon as possible.',
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.support_agent),
                        label: const Text('Contact Order Support'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kMainColour,
                          side: const BorderSide(color: kMainColour),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _section(
                context: context,
                title: 'Recent Orders',
                child:
                state.orders.isEmpty
                    ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No orders yet",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: scheme.onBackground,
                        ),
                      ),
                      Text(
                        "Your recent orders will appear here.",
                        style: TextStyle(
                          color: scheme.onBackground.withOpacity(0.75),
                        ),
                      ),
                    ],
                  ),
                )
                    : Column(
                  children: List.generate(state.orders.length, (i) {
                    final o = state.orders[i];
                    return Card(
                      color: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: scheme.onBackground.withOpacity(0.15),
                        ),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          "Order #${o["order_number"]}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Date: ${o["placed_at"]}"),
                            Text("Payment: ${o["payment_method"]}"),
                            Text("Items: ${o["items_count"]}"),
                          ],
                        ),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "\$${o["total"]}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              decoration: BoxDecoration(
                                color: _statusColor(
                                  o["status"],
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Text(
                                o["status"],
                                style: TextStyle(
                                  color: _statusColor(o["status"]),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onTap:
                            () =>
                            _showOrderDetailsDialog(
                              context,
                              ref,
                              o["id"],
                            ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _section({
  required BuildContext context,
  required String title,
  required Widget child,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? Colors.grey[900] : Colors.grey[100],
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

Widget _tip(BuildContext context, String text) {
  final scheme = Theme
      .of(context)
      .colorScheme;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.check_circle, size: 18, color: kMainColour),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            color: scheme.onBackground.withOpacity(0.9),
            height: 1.35,
          ),
        ),
      ),
    ],
  );
}

Color _statusColor(String s) {
  switch (s.toLowerCase()) {
    case 'pending':
      return Colors.amber;
    case 'processed':
    case 'processing':
    case 'shipped':
    case 'out for delivery':
    case 'delivered':
      return Colors.green;
    case 'canceled':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

Future<void> _showOrderDetailsDialog(BuildContext context,
    WidgetRef ref,
    String id,) async {
  final notifier = ref.read(ordersProvider.notifier);
  final details = await notifier.getOrderDetails(id);
  if (details == null) return;

  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;
  final popupBg = isDark ? Colors.grey[900] : Colors.grey[100];
  final cardBorder = isDark ? Colors.white12 : Colors.black12;

  final status = (details["status"] ?? "").toString();
  final statusColor = _statusColor(status);

  final items = List<Map<String, dynamic>>.from(details["items"] ?? const []);
  final maxH = MediaQuery
      .of(context)
      .size
      .height * 0.7;

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Order Details',
    barrierColor: Colors.black54,
    transitionDuration: Duration.zero,
    pageBuilder: (dialogCtx, _, __) {
      return Center(
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
            constraints: BoxConstraints(maxWidth: 412.0, maxHeight: maxH),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: kMainColour.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.receipt_long,
                                color: kMainColour,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Order #${details["order_number"]}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: scheme.onBackground,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: statusColor.withOpacity(0.3),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment: ${details["payment_method"] ?? "-"}',
                                style: TextStyle(
                                  color: scheme.onBackground.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Date: ${details["placed_at"] ?? "-"}',
                                style: TextStyle(
                                  color: scheme.onBackground.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Items',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ScrollConfiguration(
                          behavior: const ScrollBehavior().copyWith(
                            overscroll: false,
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(top: 2, bottom: 2),
                            itemCount: items.length,
                            itemBuilder: (_, i) {
                              final it = items[i];
                              final title =
                              (it["product_name"] ?? "").toString();
                              final sub = [
                                if ((it["model_name"] ?? "")
                                    .toString()
                                    .isNotEmpty)
                                  it["model_name"],
                                if ((it["color"] ?? "")
                                    .toString()
                                    .isNotEmpty)
                                  it["color"],
                              ].join(' • ');
                              final qty = it["qty"] ?? 1;
                              final line = (it["line_total"] ?? "").toString();
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (sub.isNotEmpty)
                                            Text(
                                              sub,
                                              style: TextStyle(
                                                color: scheme.onBackground
                                                    .withOpacity(0.6),
                                                fontSize: 12,
                                              ),
                                            ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Qty: $qty',
                                            style: TextStyle(
                                              color: scheme.onBackground
                                                  .withOpacity(0.7),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '\$$line',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(height: 24),
                        _amountRow(context, 'Subtotal', details["subtotal"]),
                        _amountRow(context, 'Shipping', details["shipping"]),
                        _amountRow(context, 'Tax', details["tax"]),
                        const Divider(height: 32),
                        _amountRow(
                          context,
                          'Total',
                          details["total"],
                          isTotal: true,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Shipping Address',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          details["shipping_address"] ?? "-",
                          style: TextStyle(
                            color: scheme.onBackground.withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Billing Address',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          details["billing_address"] ?? "-",
                          style: TextStyle(
                            color: scheme.onBackground.withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Builder(
                          builder: (actionCtx) {
                            final canCancel = _canCancel(status);
                            final canDeliver = _canMarkDelivered(status);
                            if (!canCancel && !canDeliver)
                              return const SizedBox.shrink();

                            return Row(
                              children: [
                                if (canCancel)
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final ok = await _showConfirmDialog(
                                          actionCtx,
                                          title: 'Cancel order?',
                                          message:
                                          'Are you sure you want to cancel this order?',
                                          confirmText: 'Yes, cancel',
                                          confirmColor: Colors.red,
                                          cancelText: 'No',
                                        );
                                        if (ok != true) return;
                                        final success = await notifier
                                            .cancelOrder(id);
                                        if (success &&
                                            Navigator.of(dialogCtx).canPop()) {
                                          Navigator.of(dialogCtx).pop();
                                        }
                                      },
                                      icon: const Icon(Icons.cancel),
                                      label: const Text('Cancel Order'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(
                                          color: Colors.red,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (canCancel && canDeliver)
                                  const SizedBox(width: 12),
                                if (canDeliver)
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        final ok = await _showConfirmDialog(
                                          actionCtx,
                                          title: 'Mark as delivered?',
                                          message:
                                          'Confirm that you have received this order.',
                                          confirmText: 'Yes, I have',
                                          confirmColor: kMainColour,
                                          cancelText: 'Not yet',
                                        );
                                        if (ok != true) return;
                                        final success = await notifier
                                            .deliverOrder(id);
                                        if (success &&
                                            Navigator.of(dialogCtx).canPop()) {
                                          Navigator.of(dialogCtx).pop();
                                        }
                                      },
                                      icon: const Icon(Icons.check_circle),
                                      label: const Text('Mark as Delivered'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kMainColour,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: IconButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    icon: const Icon(Icons.close),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    tooltip: 'Close',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) => child,
  );
}

Widget _amountRow(BuildContext ctx,
    String label,
    dynamic amount, {
      bool isTotal = false,
    }) {
  final scheme = Theme
      .of(ctx)
      .colorScheme;
  final amt =
  (amount is num)
      ? amount.toStringAsFixed(2)
      : amount?.toString() ?? '0.00';
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color:
            isTotal
                ? scheme.onBackground
                : scheme.onSurface.withOpacity(0.7),
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          '\$$amt',
          style: TextStyle(
            color: scheme.onBackground,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            fontSize: isTotal ? 18 : 14,
          ),
        ),
      ],
    ),
  );
}

Future<bool?> _showConfirmDialog(BuildContext ctx, {
  required String title,
  required String message,
  required String confirmText,
  required Color confirmColor,
  String cancelText = 'Cancel',
}) async {
  final theme = Theme.of(ctx);
  final colorScheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;
  final popupBg = isDark ? Colors.grey[900] : Colors.grey[100];

  return showDialog<bool>(
    context: ctx,
    barrierDismissible: false,
    builder:
        (context) =>
        Center(
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
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onBackground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onBackground.withOpacity(0.85),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.onBackground
                                .withOpacity(0.7),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Text(cancelText),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: confirmColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: Text(confirmText),
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
}

bool _canCancel(String status) {
  final s = status.toLowerCase();
  return s == 'pending' || s == 'processed' || s == 'processing';
}

bool _canMarkDelivered(String status) {
  final s = status.toLowerCase();
  if (s == 'delivered' || s == 'canceled') return false;
  return s == 'out for delivery' || s == 'shipped';
}
