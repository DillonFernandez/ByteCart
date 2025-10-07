import 'package:bytecart_app/services/api_service.dart';
import 'package:bytecart_app/theme/theme_colours.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _loading = true;
  bool _placing = false;
  bool _locating = false;
  List<Map<String, dynamic>> _cartItems = [];

  final _formKey = GlobalKey<FormState>();

  final _phoneCtrl = TextEditingController();

  final _shippingStreetCtrl = TextEditingController();
  final _shippingAptCtrl = TextEditingController();
  final _shippingCityCtrl = TextEditingController();
  final _shippingDistrictCtrl = TextEditingController();
  final _shippingZipCtrl = TextEditingController();

  bool _billingSame = true;
  final _billingStreetCtrl = TextEditingController();
  final _billingAptCtrl = TextEditingController();
  final _billingCityCtrl = TextEditingController();
  final _billingDistrictCtrl = TextEditingController();
  final _billingZipCtrl = TextEditingController();

  String _payment = 'cod';
  final _cardNumberCtrl = TextEditingController();
  final _cardHolderCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  String _cardNumberLabel = 'Card number';

  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();

    void sync() {
      if (_billingSame) _syncBillingFromShipping();
    }

    _shippingStreetCtrl.addListener(sync);
    _shippingAptCtrl.addListener(sync);
    _shippingCityCtrl.addListener(sync);
    _shippingDistrictCtrl.addListener(sync);
    _shippingZipCtrl.addListener(sync);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _shippingStreetCtrl.dispose();
    _shippingAptCtrl.dispose();
    _shippingCityCtrl.dispose();
    _shippingDistrictCtrl.dispose();
    _shippingZipCtrl.dispose();
    _billingStreetCtrl.dispose();
    _billingAptCtrl.dispose();
    _billingCityCtrl.dispose();
    _billingDistrictCtrl.dispose();
    _billingZipCtrl.dispose();
    _cardNumberCtrl.dispose();
    _cardHolderCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _syncBillingFromShipping() {
    _billingStreetCtrl.text = _shippingStreetCtrl.text;
    _billingAptCtrl.text = _shippingAptCtrl.text;
    _billingCityCtrl.text = _shippingCityCtrl.text;
    _billingDistrictCtrl.text = _shippingDistrictCtrl.text;
    _billingZipCtrl.text = _shippingZipCtrl.text;
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    try {
      final items = await ApiService.getCartItems();
      setState(() => _cartItems = items);

      try {
        final data = await ApiService.getShippingInfo();
        _phoneCtrl.text = data['phone_number']?.toString() ?? '';
        _shippingStreetCtrl.text =
            data['shipping_street_address']?.toString() ?? '';
        _shippingAptCtrl.text =
            data['shipping_apartment_suite']?.toString() ?? '';
        _shippingCityCtrl.text = data['shipping_city']?.toString() ?? '';
        _shippingDistrictCtrl.text =
            data['shipping_district']?.toString() ?? '';
        _shippingZipCtrl.text = data['shipping_zip_code']?.toString() ?? '';

        final sameRaw = data['is_billing_same_as_shipping'];
        final same = sameRaw == true || sameRaw == 1 || sameRaw == '1';
        setState(() {
          _billingSame = same;
        });

        _billingStreetCtrl.text =
            data['billing_street_address']?.toString() ?? '';
        _billingAptCtrl.text =
            data['billing_apartment_suite']?.toString() ?? '';
        _billingCityCtrl.text = data['billing_city']?.toString() ?? '';
        _billingDistrictCtrl.text = data['billing_district']?.toString() ?? '';
        _billingZipCtrl.text = data['billing_zip_code']?.toString() ?? '';

        if (_billingSame) _syncBillingFromShipping();
      } catch (_) {}

      try {
        final pm = await ApiService.getPaymentMethod();
        final methodName = pm['payment_method']?.toString() ?? '';
        final mapped = _mapPaymentFromApi(methodName);
        setState(() {
          _payment = mapped;
        });

        if (mapped == 'card') {
          _cardHolderCtrl.text = pm['cardholder_name']?.toString() ?? '';
          final exp = pm['expiry_date']?.toString() ?? '';
          if (RegExp(r'^\d{2}/\d{2}$').hasMatch(exp)) {
            _expiryCtrl.text = exp;
          }
          final raw = (pm['masked_card'] ?? '').toString().trim();
          String masked = raw;
          if (raw.isNotEmpty && RegExp(r'^\d{4}$').hasMatch(raw)) {
            masked = '**** **** **** $raw';
          }
          if (masked.isNotEmpty) {
            _cardNumberCtrl.text = masked;
            _cardNumberLabel = 'Card Number';
          } else {
            _cardNumberLabel = 'Card Number';
          }
        }
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load checkout: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapPaymentFromApi(String name) {
    switch (name.trim().toLowerCase()) {
      case 'visa/mastercard':
      case 'visa / mastercard':
      case 'card':
        return 'card';
      case 'koko':
        return 'koko';
      case 'mintpay':
        return 'mintpay';
      case 'cod':
      case 'cash on delivery':
        return 'cod';
      default:
        return _payment;
    }
  }

  double get _subtotal {
    double s = 0;
    for (final it in _cartItems) {
      final price = (it['price'] ?? 0).toDouble();
      final qty = (it['qty'] ?? 1) as int;
      s += price * qty;
    }
    return s;
  }

  double get _shipping => _cartItems.isEmpty ? 0 : 5.0;

  double get _tax => _subtotal * 0.05;

  double get _total => _subtotal + _shipping + _tax;

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _placing = true);
    try {
      await ApiService.clearCart();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to place order: $e')));
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isLandscape =
        MediaQuery
            .of(context)
            .orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: scheme.background,
        foregroundColor: scheme.onBackground,
        iconTheme: IconThemeData(color: scheme.onBackground),
        titleTextStyle: theme.textTheme.titleMedium?.copyWith(
          color: scheme.onBackground,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body:
      isLandscape
          ? _buildLandscapeCheckoutBody()
          : (_loading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
          ? _empty()
          : SafeArea(
        child: ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(
            overscroll: false,
          ),
          child: Theme(
            data: theme.copyWith(
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: kMainColour,
                selectionColor: kMainColour.withOpacity(
                  isDark ? 0.35 : 0.25,
                ),
                selectionHandleColor: kMainColour,
              ),
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProgressBar(context),
                  const SizedBox(height: 12),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _section(
                          title: 'Contact Information',
                          child: _inp(
                            _phoneCtrl,
                            'Phone number',
                            TextInputType.phone,
                            validatorPhone10,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9 ]'),
                              ),
                            ],
                            onChanged:
                                (v) => _formatPhone(_phoneCtrl),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _section(
                          title: 'Shipping Address',
                          trailing: _getLocationButton(
                            onPressed:
                                () =>
                                _getLocationAndFill(
                                  forBilling: false,
                                ),
                          ),
                          child: Column(
                            children: [
                              _inp(
                                _shippingStreetCtrl,
                                'Street address',
                                TextInputType.streetAddress,
                                validatorReq,
                              ),
                              const SizedBox(height: 12),
                              _inp(
                                _shippingAptCtrl,
                                'Apartment/Suite (optional)',
                                TextInputType.text,
                                    (_) => null,
                              ),
                              const SizedBox(height: 12),
                              _inp(
                                _shippingCityCtrl,
                                'City',
                                TextInputType.text,
                                validatorReq,
                              ),
                              const SizedBox(height: 12),
                              _inp(
                                _shippingDistrictCtrl,
                                'District',
                                TextInputType.text,
                                validatorReq,
                              ),
                              const SizedBox(height: 12),
                              _inp(
                                _shippingZipCtrl,
                                'ZIP code',
                                TextInputType.number,
                                validatorZip5,
                                inputFormatters: [
                                  FilteringTextInputFormatter
                                      .digitsOnly,
                                  LengthLimitingTextInputFormatter(
                                    5,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Checkbox(
                                value: _billingSame,
                                onChanged:
                                    (v) =>
                                    setState(() {
                                      _billingSame = v ?? true;
                                      if (_billingSame)
                                        _syncBillingFromShipping();
                                    }),
                                activeColor: kMainColour,
                                materialTapTargetSize:
                                MaterialTapTargetSize
                                    .shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(5),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Billing address is the same as shipping',
                                  style: TextStyle(
                                    color: scheme.onBackground
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (!_billingSame)
                          _section(
                            title: 'Billing Address',
                            trailing: _getLocationButton(
                              onPressed:
                                  () =>
                                  _getLocationAndFill(
                                    forBilling: true,
                                  ),
                            ),
                            child: Column(
                              children: [
                                _inp(
                                  _billingStreetCtrl,
                                  'Street address',
                                  TextInputType.streetAddress,
                                  validatorReq,
                                ),
                                const SizedBox(height: 12),
                                _inp(
                                  _billingAptCtrl,
                                  'Apartment/Suite (optional)',
                                  TextInputType.text,
                                      (_) => null,
                                ),
                                const SizedBox(height: 12),
                                _inp(
                                  _billingCityCtrl,
                                  'City',
                                  TextInputType.text,
                                  validatorReq,
                                ),
                                const SizedBox(height: 12),
                                _inp(
                                  _billingDistrictCtrl,
                                  'District',
                                  TextInputType.text,
                                  validatorReq,
                                ),
                                const SizedBox(height: 12),
                                _inp(
                                  _billingZipCtrl,
                                  'ZIP code',
                                  TextInputType.number,
                                  validatorZip5,
                                ),
                              ],
                            ),
                          ),
                        if (!_billingSame)
                          const SizedBox(height: 16),
                        _section(
                          title: 'Payment Method',
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              _payOption(
                                'card',
                                'Visa/MasterCard',
                                'Pay securely with your card',
                                logos: [
                                  'assets/images/icons/Visa.webp',
                                  'assets/images/icons/Mastercard.webp',
                                ],
                              ),
                              const SizedBox(height: 8),
                              _payOption(
                                'koko',
                                'Koko',
                                'Pay with Koko',
                                logos: [
                                  'assets/images/icons/Koko.webp',
                                ],
                              ),
                              const SizedBox(height: 8),
                              _payOption(
                                'mintpay',
                                'Mintpay',
                                'Pay with Mintpay',
                                logos: [
                                  'assets/images/icons/Mintpay.webp',
                                ],
                              ),
                              const SizedBox(height: 8),
                              _payOption(
                                'cod',
                                'COD',
                                'Cash on Delivery',
                                logos: [
                                  'assets/images/icons/COD.webp',
                                ],
                              ),
                              if (_payment == 'card') ...[
                                const SizedBox(height: 12),
                                _inp(
                                  _cardNumberCtrl,
                                  _cardNumberLabel,
                                  TextInputType.number,
                                  validatorCardNumber,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9* ]'),
                                    ),
                                    LengthLimitingTextInputFormatter(
                                      23,
                                    ),
                                  ],
                                  onChanged:
                                      (v) =>
                                      _formatCardNumberMasked(
                                        _cardNumberCtrl,
                                      ),
                                  enabled: _payment == 'card',
                                ),
                                const SizedBox(height: 12),
                                _inp(
                                  _cardHolderCtrl,
                                  'Cardholder Name',
                                  TextInputType.name,
                                  validatorReq,
                                  enabled: _payment == 'card',
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _inp(
                                        _expiryCtrl,
                                        'Expiry (MM/YY)',
                                        TextInputType.datetime,
                                        validatorExpiry,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'[0-9/]'),
                                          ),
                                          LengthLimitingTextInputFormatter(
                                            5,
                                          ),
                                        ],
                                        onChanged:
                                            (v) =>
                                            _formatExpiry(
                                              _expiryCtrl,
                                            ),
                                        enabled: _payment == 'card',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _inp(
                                        _cvvCtrl,
                                        'CVV',
                                        TextInputType.number,
                                        validatorCvv,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(
                                            4,
                                          ),
                                        ],
                                        enabled: _payment == 'card',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _section(
                          title: 'Order Notes',
                          child: _inp(
                            _notesCtrl,
                            'Notes (optional)',
                            TextInputType.multiline,
                                (_) => null,
                            maxLines: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox.shrink(),
                ],
              ),
            ),
          ),
        ),
      )),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton:
      isLandscape || _loading || _cartItems.isEmpty
          ? null
          : FloatingActionButton(
        onPressed: _showOrderSummaryDialog,
        backgroundColor: kMainColour,
        foregroundColor: Colors.white,
        child: const Icon(Icons.receipt_long),
      ),
    );
  }

  Widget _empty() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.remove_shopping_cart_outlined,
            size: 64,
            color: scheme.onBackground.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'Your cart is empty',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to proceed to checkout.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onBackground.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Checkout',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Step 2 of 2',
              style: TextStyle(
                color: scheme.onBackground.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: 1.0,
          backgroundColor: theme.colorScheme.surfaceVariant,
          valueColor: const AlwaysStoppedAnimation<Color>(kMainColour),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cart',
              style: TextStyle(
                color: scheme.onBackground.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            Text(
              'Checkout',
              style: const TextStyle(
                color: kMainColour,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _section({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _summaryItem(Map<String, dynamic> item) {
    final imageUrl = _formatImageUrl(item['image']);
    final name = (item['name'] ?? '').toString();
    final model = (item['model_name'] ?? '').toString();
    final color =
    (item['options'] is Map ? item['options']['color'] : null)?.toString();
    final qty = (item['qty'] ?? 1) as int;
    final price = (item['price'] ?? 0).toDouble();
    final line = price * qty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 56,
              height: 56,
              child:
              imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _placeholderImg(),
              )
                  : _placeholderImg(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (model.isNotEmpty ||
                    (color != null && color.isNotEmpty)) ...[
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (model.isNotEmpty) 'Model: $model',
                      if (color != null && color.isNotEmpty) 'Color: $color',
                    ].join(' • '),
                    style: TextStyle(
                      color: Theme
                          .of(
                        context,
                      )
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Qty: $qty',
                  style: TextStyle(
                    color: Theme
                        .of(
                      context,
                    )
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${price.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Theme
                      .of(
                    context,
                  )
                      .colorScheme
                      .onSurface
                      .withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              Text(
                '\$${line.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool isTotal = false}) {
    final scheme = Theme
        .of(context)
        .colorScheme;
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
            '\$${amount.toStringAsFixed(2)}',
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

  Widget _inp(TextEditingController c,
      String label,
      TextInputType type,
      String? Function(String?) validator, {
        int maxLines = 1,
        List<TextInputFormatter>? inputFormatters,
        bool enabled = true,
        ValueChanged<String>? onChanged,
      }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: c,
      keyboardType: type,
      validator: validator,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      enabled: enabled,
      onChanged: onChanged,
      style: TextStyle(color: colorScheme.onBackground),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: colorScheme.onBackground.withOpacity(0.5)),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kMainColour, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _payOption(String value,
      String title,
      String subtitle, {
        List<String> logos = const [],
      }) {
    final scheme = Theme
        .of(context)
        .colorScheme;
    return InkWell(
      onTap:
          () =>
          setState(() {
            _payment = value;
            if (_payment != 'card') _cvvCtrl.clear();
          }),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _payment == value ? kMainColour : scheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _payment,
              onChanged:
                  (v) =>
                  setState(() {
                    _payment = v ?? value;
                    if (_payment != 'card') _cvvCtrl.clear();
                  }),
              activeColor: kMainColour,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: scheme.onBackground.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (logos.isNotEmpty) ...[
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final a in logos) ...[
                    Image.asset(a, height: 20, fit: BoxFit.contain),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showOrderSummaryDialog() async {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final popupBg = isDark ? Colors.grey[900] : Colors.grey[100];

    double subtotal = 0;
    for (var item in _cartItems) {
      subtotal += ((item['price'] ?? 0) * (item['qty'] ?? 1)).toDouble();
    }
    const shipping = 5.0;
    final tax = subtotal * 0.05;
    final total = subtotal + shipping + tax;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Order Summary',
      barrierColor: Colors.black54,
      transitionDuration: Duration.zero,
      pageBuilder: (context, _, __) {
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
              constraints: const BoxConstraints(maxWidth: 412.0),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Summary',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: scheme.onBackground,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 240),
                          child: ScrollConfiguration(
                            behavior: const ScrollBehavior().copyWith(
                              overscroll: false,
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const ClampingScrollPhysics(),
                              padding: const EdgeInsets.only(top: 2, bottom: 2),
                              itemCount: _cartItems.length,
                              itemBuilder:
                                  (_, i) => _summaryItem(_cartItems[i]),
                            ),
                          ),
                        ),
                        const Divider(height: 24),
                        _summaryRow(
                          'Subtotal (${_cartItems.length} items)',
                          subtotal,
                        ),
                        _summaryRow('Shipping', shipping),
                        _summaryRow('Tax (estimated)', tax),
                        const Divider(height: 32),
                        _summaryRow('Total', total, isTotal: true),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _placeOrder();
                            },
                            icon: const Icon(Icons.lock_outline),
                            label: const Text('Place Order'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kMainColour,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified_user,
                                color: Colors.green[600],
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '256-bit SSL Encrypted',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'Accepted payment methods',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onBackground.withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _paymentIcon(
                                    'assets/images/icons/Visa.webp',
                                    fullWidth: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _paymentIcon(
                                    'assets/images/icons/Mastercard.webp',
                                    fullWidth: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _paymentIcon(
                                    'assets/images/icons/Koko.webp',
                                    fullWidth: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _paymentIcon(
                                    'assets/images/icons/Mintpay.webp',
                                    fullWidth: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _paymentIcon(
                                    'assets/images/icons/COD.webp',
                                    fullWidth: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder:
          (context, animation, secondaryAnimation, child) => child,
    );
  }

  String _formatImageUrl(dynamic path) {
    if (path == null || (path is String && path.isEmpty)) return '';
    final url = path.toString();
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    const base = 'http://10.0.2.2:8000';
    return url.startsWith('/') ? '$base$url' : '$base/$url';
  }

  Widget _placeholderImg() {
    return Icon(
      Icons.image_outlined,
      color: Theme
          .of(context)
          .colorScheme
          .onSurface
          .withOpacity(0.2),
      size: 24,
    );
  }

  Widget _paymentIcon(String asset, {bool fullWidth = false}) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    final chipBg = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final chipBorder = isDark ? Colors.white24 : Colors.black12;
    return Container(
      width: fullWidth ? double.infinity : 64,
      height: fullWidth ? 48 : 40,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipBorder, width: 1.5),
      ),
      child: Image.asset(asset, fit: BoxFit.contain),
    );
  }

  String? validatorReq(String? v) =>
      (v == null || v
          .trim()
          .isEmpty) ? 'Required' : null;

  String? validatorEmail(String? v) {
    if (v == null || v
        .trim()
        .isEmpty) return 'Required';
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim());
    return ok ? null : 'Invalid email';
  }

  String? validatorPhone10(String? v) {
    final s = (v ?? '').replaceAll(' ', '');
    if (s.isEmpty) return 'Required';
    if (!RegExp(r'^\d{10}$').hasMatch(s))
      return 'Enter a 10-digit phone number';
    return null;
  }

  String? validatorZip5(String? v) {
    final s = (v ?? '').replaceAll(' ', '');
    if (s.isEmpty) return 'Required';
    if (!RegExp(r'^\d{5}$').hasMatch(s)) return 'Enter a 5-digit ZIP code';
    return null;
  }

  String? validatorCardNumber(String? v) {
    final s = (v ?? '').replaceAll(' ', '').replaceAll('*', '');
    if (_payment != 'card') return null;
    if (s.isEmpty) return 'Required';
    if (!RegExp(r'^\d{12,19}$').hasMatch(s)) return 'Enter a valid card number';
    return null;
  }

  String? validatorExpiry(String? v) {
    if (_payment != 'card') return null;
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Required';
    final m = RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$').firstMatch(s);
    if (m == null) return 'Use MM/YY';
    return null;
  }

  String? validatorCvv(String? v) {
    if (_payment != 'card') return null;
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Required';
    if (!RegExp(r'^\d{3,4}$').hasMatch(s)) return '3–4 digits';
    return null;
  }

  void _formatPhone(TextEditingController c) {
    final digits = c.text
        .replaceAll(RegExp(r'\D'), '')
        .substring(0, c.text
        .replaceAll(RegExp(r'\D'), '')
        .length
        .clamp(0, 10));
    String out;
    if (digits.length <= 3) {
      out = digits;
    } else if (digits.length <= 6) {
      out = '${digits.substring(0, 3)} ${digits.substring(3)}';
    } else {
      out =
      '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(
          6)}';
    }
    if (c.text != out) {
      final pos = out.length;
      c.value = TextEditingValue(
        text: out,
        selection: TextSelection.collapsed(offset: pos),
      );
    }
  }

  void _formatCardNumberMasked(TextEditingController c) {
    final raw = c.text.replaceAll(RegExp(r'[^0-9*]'), '');
    final clipped = raw.substring(0, raw.length.clamp(0, 19));
    final groups = <String>[];
    for (int i = 0; i < clipped.length; i += 4) {
      groups.add(clipped.substring(i, (i + 4).clamp(0, clipped.length)));
    }
    final out = groups.join(' ');
    if (c.text != out) {
      final pos = out.length;
      c.value = TextEditingValue(
        text: out,
        selection: TextSelection.collapsed(offset: pos),
      );
    }
  }

  void _formatExpiry(TextEditingController c) {
    final digits = c.text
        .replaceAll(RegExp(r'\D'), '')
        .substring(0, c.text
        .replaceAll(RegExp(r'\D'), '')
        .length
        .clamp(0, 4));
    String out;
    if (digits.length <= 2) {
      out = digits;
    } else {
      out = '${digits.substring(0, 2)}/${digits.substring(2)}';
    }
    if (c.text != out) {
      final pos = out.length;
      c.value = TextEditingValue(
        text: out,
        selection: TextSelection.collapsed(offset: pos),
      );
    }
  }

  Widget _buildLandscapeCheckoutBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_cartItems.isEmpty) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _empty(),
          );
        }

        final isWide = constraints.maxWidth >= 1000;
        final isMedium =
            constraints.maxWidth >= 800 && constraints.maxWidth < 1000;

        if (isWide || isMedium) {
          final rightMaxWidth = isWide ? 420.0 : 360.0;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildLandscapeLeftPane()),
                  const SizedBox(width: 20),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: rightMaxWidth),
                    child: SizedBox(
                      height: constraints.maxHeight,
                      child: ScrollConfiguration(
                        behavior: const ScrollBehavior().copyWith(
                          overscroll: false,
                        ),
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: _buildOrderSummarySidePanel(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          return SafeArea(
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(overscroll: false),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLandscapeLeftPane(),
                    const SizedBox(height: 16),
                    _buildOrderSummarySidePanel(),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildLandscapeLeftPane() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Theme(
      data: theme.copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: kMainColour,
          selectionColor: kMainColour.withOpacity(isDark ? 0.35 : 0.25),
          selectionHandleColor: kMainColour,
        ),
      ),
      child: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProgressBar(context),
              const SizedBox(height: 12),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _section(
                      title: 'Contact Information',
                      child: _inp(
                        _phoneCtrl,
                        'Phone number',
                        TextInputType.phone,
                        validatorPhone10,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                        ],
                        onChanged: (v) => _formatPhone(_phoneCtrl),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _section(
                      title: 'Shipping Address',
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: _getLocationButton(
                              onPressed:
                                  () => _getLocationAndFill(forBilling: false),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _inp(
                            _shippingStreetCtrl,
                            'Street address',
                            TextInputType.streetAddress,
                            validatorReq,
                          ),
                          const SizedBox(height: 12),
                          _twoColRow(
                            _inp(
                              _shippingCityCtrl,
                              'City',
                              TextInputType.text,
                              validatorReq,
                            ),
                            _inp(
                              _shippingDistrictCtrl,
                              'District',
                              TextInputType.text,
                              validatorReq,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _twoColRow(
                            _inp(
                              _shippingZipCtrl,
                              'ZIP code',
                              TextInputType.number,
                              validatorZip5,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(5),
                              ],
                            ),
                            _inp(
                              _shippingAptCtrl,
                              'Apartment/Suite (optional)',
                              TextInputType.text,
                                  (_) => null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Checkbox(
                            value: _billingSame,
                            onChanged:
                                (v) =>
                                setState(() {
                                  _billingSame = v ?? true;
                                  if (_billingSame) _syncBillingFromShipping();
                                }),
                            activeColor: kMainColour,
                            materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Billing address is the same as shipping',
                              style: TextStyle(
                                color: Theme
                                    .of(
                                  context,
                                )
                                    .colorScheme
                                    .onBackground
                                    .withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!_billingSame)
                      _section(
                        title: 'Billing Address',
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: _getLocationButton(
                                onPressed:
                                    () => _getLocationAndFill(forBilling: true),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _inp(
                              _billingStreetCtrl,
                              'Street address',
                              TextInputType.streetAddress,
                              validatorReq,
                            ),
                            const SizedBox(height: 12),
                            _twoColRow(
                              _inp(
                                _billingCityCtrl,
                                'City',
                                TextInputType.text,
                                validatorReq,
                              ),
                              _inp(
                                _billingDistrictCtrl,
                                'District',
                                TextInputType.text,
                                validatorReq,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _twoColRow(
                              _inp(
                                _billingZipCtrl,
                                'ZIP code',
                                TextInputType.number,
                                validatorZip5,
                              ),
                              _inp(
                                _billingAptCtrl,
                                'Apartment/Suite (optional)',
                                TextInputType.text,
                                    (_) => null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!_billingSame) const SizedBox(height: 16),
                    _section(
                      title: 'Payment Method',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _payOption(
                            'card',
                            'Visa/MasterCard',
                            'Pay securely with your card',
                            logos: [
                              'assets/images/icons/Visa.webp',
                              'assets/images/icons/Mastercard.webp',
                            ],
                          ),
                          const SizedBox(height: 8),
                          _payOption(
                            'koko',
                            'Koko',
                            'Pay with Koko',
                            logos: ['assets/images/icons/Koko.webp'],
                          ),
                          const SizedBox(height: 8),
                          _payOption(
                            'mintpay',
                            'Mintpay',
                            'Pay with Mintpay',
                            logos: ['assets/images/icons/Mintpay.webp'],
                          ),
                          const SizedBox(height: 8),
                          _payOption(
                            'cod',
                            'COD',
                            'Cash on Delivery',
                            logos: ['assets/images/icons/COD.webp'],
                          ),
                          if (_payment == 'card') ...[
                            const SizedBox(height: 12),
                            _inp(
                              _cardNumberCtrl,
                              _cardNumberLabel,
                              TextInputType.number,
                              validatorCardNumber,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9* ]'),
                                ),
                                LengthLimitingTextInputFormatter(23),
                              ],
                              onChanged:
                                  (v) =>
                                  _formatCardNumberMasked(_cardNumberCtrl),
                              enabled: _payment == 'card',
                            ),
                            const SizedBox(height: 12),
                            _inp(
                              _cardHolderCtrl,
                              'Cardholder Name',
                              TextInputType.name,
                              validatorReq,
                              enabled: _payment == 'card',
                            ),
                            const SizedBox(height: 12),
                            _twoColRow(
                              _inp(
                                _expiryCtrl,
                                'Expiry (MM/YY)',
                                TextInputType.datetime,
                                validatorExpiry,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9/]'),
                                  ),
                                  LengthLimitingTextInputFormatter(5),
                                ],
                                onChanged: (v) => _formatExpiry(_expiryCtrl),
                                enabled: _payment == 'card',
                              ),
                              _inp(
                                _cvvCtrl,
                                'CVV',
                                TextInputType.number,
                                validatorCvv,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                enabled: _payment == 'card',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _section(
                      title: 'Order Notes',
                      child: _inp(
                        _notesCtrl,
                        'Notes (optional)',
                        TextInputType.multiline,
                            (_) => null,
                        maxLines: 3,
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

  Widget _buildOrderSummarySidePanel() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? Colors.grey[900] : Colors.grey[50];

    final subtotal = _subtotal;
    final shipping = _shipping;
    final tax = _tax;
    final total = _total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
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
                child: const Icon(Icons.receipt_long, color: kMainColour),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Order Summary',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: scheme.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(overscroll: false),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.only(top: 2, bottom: 2),
                itemCount: _cartItems.length,
                itemBuilder: (_, i) => _summaryItem(_cartItems[i]),
              ),
            ),
          ),
          const Divider(height: 24),
          _summaryRow('Subtotal (${_cartItems.length} items)', subtotal),
          _summaryRow('Shipping', shipping),
          _summaryRow('Tax (estimated)', tax),
          const Divider(height: 32),
          _summaryRow('Total', total, isTotal: true),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _placing ? null : _placeOrder,
              icon: const Icon(Icons.lock_outline),
              label: Text(_placing ? 'Placing...' : 'Place Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kMainColour,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user, color: Colors.green[600], size: 16),
                const SizedBox(width: 8),
                Text(
                  '256-bit SSL Encrypted',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Accepted payment methods',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onBackground.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _paymentIcon(
                      'assets/images/icons/Visa.webp',
                      fullWidth: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _paymentIcon(
                      'assets/images/icons/Mastercard.webp',
                      fullWidth: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _paymentIcon(
                      'assets/images/icons/Koko.webp',
                      fullWidth: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _paymentIcon(
                      'assets/images/icons/Mintpay.webp',
                      fullWidth: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _paymentIcon(
                      'assets/images/icons/COD.webp',
                      fullWidth: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _twoColRow(Widget left, Widget right) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Future<void> _getLocationAndFill({required bool forBilling}) async {
    if (!mounted) return;
    setState(() => _locating = true);
    try {
      if (!await _ensureLocationPermission()) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final places = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (places.isEmpty) {
        _showSnack('Unable to resolve location');
        return;
      }
      final p = places.first;
      final city =
      (p.locality
          ?.trim()
          .isNotEmpty == true
          ? p.locality!.trim()
          : (p.subAdministrativeArea ?? '').trim());
      final district =
      (p.subAdministrativeArea
          ?.trim()
          .isNotEmpty == true
          ? p.subAdministrativeArea!.trim()
          : (p.administrativeArea ?? '').trim());
      final zip = (p.postalCode ?? '').replaceAll(RegExp(r'[^0-9]'), '');

      setState(() {
        if (forBilling) {
          if (city.isNotEmpty) _billingCityCtrl.text = city;
          if (district.isNotEmpty) _billingDistrictCtrl.text = district;
          if (zip.isNotEmpty) _billingZipCtrl.text = zip;
        } else {
          if (city.isNotEmpty) _shippingCityCtrl.text = city;
          if (district.isNotEmpty) _shippingDistrictCtrl.text = district;
          if (zip.isNotEmpty) _shippingZipCtrl.text = zip;
          if (_billingSame) _syncBillingFromShipping();
        }
      });
      _showSnack('Location applied');
    } catch (e) {
      _showSnack('Location error: $e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<bool> _ensureLocationPermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      _showSnack('Location services disabled');
      return false;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) {
      _showSnack('Location permission denied');
      return false;
    }
    if (perm == LocationPermission.deniedForever) {
      _showSnack('Location permission permanently denied');
      return false;
    }
    return true;
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _getLocationButton({required VoidCallback onPressed}) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    final Color c = isDark ? Colors.white : Colors.black;
    return OutlinedButton.icon(
      onPressed: _locating ? null : onPressed,
      icon: const Icon(Icons.my_location),
      label: Text(_locating ? 'Getting location...' : 'Get location'),
      style: OutlinedButton.styleFrom(
        foregroundColor: c,
        side: BorderSide(color: c),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
