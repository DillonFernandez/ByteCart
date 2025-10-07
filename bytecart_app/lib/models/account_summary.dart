class AccountSummary {
  final String name;
  final String email;

  final int ordersTotal;
  final int ordersActive;
  final int ordersCompleted;
  final String? latestOrderNumber;
  final String? latestOrderStatus;
  final String? latestOrderDateHuman;

  final int wishCount;

  final bool shippingComplete;
  final bool billingComplete;
  final bool billingSameAsShipping;

  final String? paymentMethod;
  final bool cardSaved;

  AccountSummary({
    required this.name,
    required this.email,
    required this.ordersTotal,
    required this.ordersActive,
    required this.ordersCompleted,
    required this.latestOrderNumber,
    required this.latestOrderStatus,
    required this.latestOrderDateHuman,
    required this.wishCount,
    required this.shippingComplete,
    required this.billingComplete,
    required this.billingSameAsShipping,
    required this.paymentMethod,
    required this.cardSaved,
  });

  factory AccountSummary.fromJson(Map<String, dynamic> j) {
    final orders = (j['orders'] ?? {}) as Map;
    final latest = (orders['latest'] ?? {}) as Map;
    final wish = (j['wish_list'] ?? {}) as Map;
    final ship = (j['shipping'] ?? {}) as Map;
    final bill = (j['billing'] ?? {}) as Map;
    final pay = (j['payment'] ?? {}) as Map;

    return AccountSummary(
      name: j['name'] ?? '',
      email: j['email'] ?? '',
      ordersTotal: (orders['total'] ?? 0) as int,
      ordersActive: (orders['active'] ?? 0) as int,
      ordersCompleted: (orders['completed'] ?? 0) as int,
      latestOrderNumber: latest['number'] as String?,
      latestOrderStatus: latest['status'] as String?,
      latestOrderDateHuman: latest['date_human'] as String?,
      wishCount: (wish['count'] ?? 0) as int,
      shippingComplete: (ship['complete'] ?? false) as bool,
      billingComplete: (bill['complete'] ?? false) as bool,
      billingSameAsShipping: (bill['same_as_shipping'] ?? false) as bool,
      paymentMethod: pay['method'] as String?,
      cardSaved: (pay['card_saved'] ?? false) as bool,
    );
  }
}
