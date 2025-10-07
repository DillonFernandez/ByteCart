import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/api_service.dart';
import 'package:bytecart_app/theme/theme_colours.dart';

class PaymentMethodState {
  final bool loading;
  final bool saving;
  final String selected;
  final String cardNumber;
  final String cardholder;
  final String expiry;
  final String cvv;
  final String? error;
  final bool connectionError;
  final String? success;

  PaymentMethodState({
    this.loading = false,
    this.saving = false,
    this.selected = "",
    this.cardNumber = "",
    this.cardholder = "",
    this.expiry = "",
    this.cvv = "",
    this.error,
    this.connectionError = false,
    this.success,
  });

  PaymentMethodState copyWith({
    bool? loading,
    bool? saving,
    String? selected,
    String? cardNumber,
    String? cardholder,
    String? expiry,
    String? cvv,
    String? error,
    bool? connectionError,
    String? success,
  }) => PaymentMethodState(
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    selected: selected ?? this.selected,
    cardNumber: cardNumber ?? this.cardNumber,
    cardholder: cardholder ?? this.cardholder,
    expiry: expiry ?? this.expiry,
    cvv: cvv ?? this.cvv,
    error: error,
    connectionError: connectionError ?? false,
    success: success,
  );
}

class PaymentMethodNotifier extends StateNotifier<PaymentMethodState> {
  PaymentMethodNotifier() : super(PaymentMethodState(loading: true)) {
    loadPaymentInfo();
  }

  final cardNumberCtrl = TextEditingController();
  final cardholderCtrl = TextEditingController();
  final expiryCtrl = TextEditingController();
  final cvvCtrl = TextEditingController();

  Future<void> loadPaymentInfo() async {
    state = state.copyWith(
      loading: true,
      error: null,
      connectionError: false,
      success: null,
    );
    try {
      final data = await ApiService.getPaymentMethod();
      String raw = (data['masked_card'] ?? '').toString().trim();
      String masked = raw;
      if (raw.isNotEmpty && RegExp(r'^\d{4}$').hasMatch(raw)) {
        masked = '**** **** **** $raw';
      }
      cardNumberCtrl.text = masked;
      cardholderCtrl.text = data['cardholder_name'] ?? '';
      expiryCtrl.text = data['expiry_date'] ?? '';
      cvvCtrl.clear();
      state = state.copyWith(
        selected: data['payment_method'] ?? '',
        cardNumber: masked,
        cardholder: data['cardholder_name'] ?? '',
        expiry: data['expiry_date'] ?? '',
        cvv: '',
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
                : "Failed to load payment method. Please try again.",
        connectionError: isConn,
      );
    }
  }

  void setSelected(String value) {
    state = state.copyWith(selected: value, error: null, success: null);
  }

  void setCardNumber(String value) {
    state = state.copyWith(cardNumber: value, error: null, success: null);
  }

  void setCardholder(String value) {
    state = state.copyWith(cardholder: value, error: null, success: null);
  }

  void setExpiry(String value) {
    state = state.copyWith(expiry: value, error: null, success: null);
  }

  void setCVV(String value) {
    state = state.copyWith(cvv: value, error: null, success: null);
  }

  Future<void> save() async {
    if (state.selected.isEmpty) {
      state = state.copyWith(
        error: "Please select a payment method",
        success: null,
      );
      return;
    }
    String digits = cardNumberCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (state.selected == "Visa/MasterCard") {
      if (digits.length < 12 || digits.length > 19) {
        state = state.copyWith(
          error: "Enter a valid card number (12–19 digits)",
          success: null,
        );
        return;
      }
      if (cardholderCtrl.text.trim().isEmpty) {
        state = state.copyWith(error: "Enter cardholder name", success: null);
        return;
      }
      final exp = expiryCtrl.text.trim();
      final expOk =
          RegExp(r'^\d{2}/\d{2}$').hasMatch(exp) &&
          (() {
            final mm = int.tryParse(exp.split('/')[0]) ?? 0;
            return mm >= 1 && mm <= 12;
          }());
      if (!expOk) {
        state = state.copyWith(
          error: "Enter a valid expiry (MM/YY)",
          success: null,
        );
        return;
      }
      final cvvDigits = cvvCtrl.text.replaceAll(RegExp(r'\D'), '');
      if (cvvDigits.length < 3 || cvvDigits.length > 4) {
        state = state.copyWith(
          error: "Enter a valid CVV (3–4 digits)",
          success: null,
        );
        return;
      }
    }
    state = state.copyWith(saving: true, error: null, success: null);
    try {
      await ApiService.updatePaymentMethod({
        "payment_method": state.selected,
        "card_number": state.selected == "Visa/MasterCard" ? digits : null,
        "cardholder_name":
            state.selected == "Visa/MasterCard" ? cardholderCtrl.text : null,
        "expiry_date":
            state.selected == "Visa/MasterCard" ? expiryCtrl.text : null,
        "cvv": state.selected == "Visa/MasterCard" ? cvvCtrl.text : null,
      });
      if (state.selected == "Visa/MasterCard") {
        final last4 =
            digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
        cardNumberCtrl.text = '**** **** **** $last4';
        cvvCtrl.clear();
      }
      state = state.copyWith(
        saving: false,
        error: null,
        success: "Payment method updated successfully",
        cardNumber: cardNumberCtrl.text,
        cvv: '',
      );
    } catch (e) {
      final isConn = _isConnectionError(e);
      state = state.copyWith(
        saving: false,
        error:
            isConn
                ? "Connection error. Please check your internet and try again."
                : "Failed to update payment method. Please try again.",
        connectionError: isConn,
      );
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

final paymentMethodProvider =
    StateNotifierProvider<PaymentMethodNotifier, PaymentMethodState>(
      (ref) => PaymentMethodNotifier(),
    );

class PaymentMethodsPage extends ConsumerWidget {
  const PaymentMethodsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paymentMethodProvider);
    final notifier = ref.read(paymentMethodProvider.notifier);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final isDark = theme.brightness == Brightness.dark;

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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        title: const Text(
          'Payment Methods',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: scheme.background,
        foregroundColor: scheme.onBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          if (banner != null) banner,
          Expanded(
            child:
                isLandscape
                    ? _LandscapePaymentBody(notifier: notifier, state: state)
                    : _PortraitPaymentBody(notifier: notifier, state: state),
          ),
        ],
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
    final scheme = Theme.of(context).colorScheme;
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
    final scheme = Theme.of(context).colorScheme;
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

class _LandscapePaymentBody extends StatelessWidget {
  final PaymentMethodNotifier notifier;
  final PaymentMethodState state;

  const _LandscapePaymentBody({required this.notifier, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      bottom: false,
      child: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: Theme(
          data: theme.copyWith(
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: kMainColour,
              selectionColor: kMainColour.withOpacity(isDark ? 0.35 : 0.25),
              selectionHandleColor: kMainColour,
            ),
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [_buildInfoSection(context)],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _section(
                        context: context,
                        title: 'Select Payment Method',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _iconsRow(context),
                            const SizedBox(height: 12),
                            _buildOption(
                              context,
                              notifier,
                              state,
                              "Visa/MasterCard",
                            ),
                            const SizedBox(height: 10),
                            _buildOption(context, notifier, state, "Koko"),
                            const SizedBox(height: 10),
                            _buildOption(context, notifier, state, "Mintpay"),
                            const SizedBox(height: 10),
                            _buildOption(context, notifier, state, "COD"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (state.selected == "Visa/MasterCard")
                        _section(
                          context: context,
                          title: 'Card Details',
                          child: _buildCardSection(context, notifier, state),
                        ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: state.saving ? null : notifier.save,
                          icon: const Icon(Icons.save_outlined),
                          label:
                              state.saving
                                  ? const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Text("Save Payment Method"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kMainColour,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
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
    );
  }
}

class _PortraitPaymentBody extends StatelessWidget {
  final PaymentMethodNotifier notifier;
  final PaymentMethodState state;

  const _PortraitPaymentBody({required this.notifier, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      bottom: false,
      child: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: Theme(
          data: theme.copyWith(
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: kMainColour,
              selectionColor: kMainColour.withOpacity(isDark ? 0.35 : 0.25),
              selectionHandleColor: kMainColour,
            ),
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoSection(context),
                const SizedBox(height: 16),
                _section(
                  context: context,
                  title: 'Select Payment Method',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _iconsRow(context),
                      const SizedBox(height: 12),
                      _buildOption(context, notifier, state, "Visa/MasterCard"),
                      const SizedBox(height: 10),
                      _buildOption(context, notifier, state, "Koko"),
                      const SizedBox(height: 10),
                      _buildOption(context, notifier, state, "Mintpay"),
                      const SizedBox(height: 10),
                      _buildOption(context, notifier, state, "COD"),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (state.selected == "Visa/MasterCard")
                  _section(
                    context: context,
                    title: 'Card Details',
                    child: _buildCardSection(context, notifier, state),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: state.saving ? null : notifier.save,
                    icon: const Icon(Icons.save_outlined),
                    label:
                        state.saving
                            ? const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            )
                            : const Text("Save Payment Method"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kMainColour,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
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
        ),
      ),
    );
  }
}

Widget _buildOption(
  BuildContext context,
  PaymentMethodNotifier notifier,
  PaymentMethodState state,
  String name,
) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final selected = state.selected == name;

  return GestureDetector(
    onTap: () => notifier.setSelected(name),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              selected
                  ? kMainColour
                  : (isDark ? Colors.white12 : Colors.black12),
          width: 2,
        ),
        color:
            selected
                ? (isDark
                    ? Colors.white.withOpacity(0.05)
                    : kMainColour.withOpacity(0.05))
                : (isDark ? Colors.grey[900] : Colors.white),
      ),
      child: Row(
        children: [
          Radio<String>(
            value: name,
            groupValue: state.selected,
            onChanged: (v) => notifier.setSelected(v ?? ""),
            activeColor: kMainColour,
          ),
          const SizedBox(width: 8),
          Text(name, style: theme.textTheme.bodyMedium),
        ],
      ),
    ),
  );
}

Widget _buildCardSection(
  BuildContext context,
  PaymentMethodNotifier notifier,
  PaymentMethodState state,
) {
  return Column(
    children: [
      _inp(
        context,
        notifier.cardNumberCtrl,
        "Card Number",
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9* ]')),
          LengthLimitingTextInputFormatter(23),
        ],
        onChanged: (v) => _formatCardNumberMasked(notifier.cardNumberCtrl),
      ),
      const SizedBox(height: 12),
      _inp(context, notifier.cardholderCtrl, "Cardholder Name"),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _inp(
              context,
              notifier.expiryCtrl,
              "Expiry (MM/YY)",
              keyboardType: TextInputType.datetime,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                LengthLimitingTextInputFormatter(5),
              ],
              onChanged: (v) => _formatExpiry(notifier.expiryCtrl),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _inp(
              context,
              notifier.cvvCtrl,
              "CVV",
              isPassword: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
            ),
          ),
        ],
      ),
    ],
  );
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
  final digits = c.text.replaceAll(RegExp(r'\D'), '');
  final clipped = digits.substring(0, digits.length.clamp(0, 4));
  String out;
  if (clipped.length <= 2) {
    out = clipped;
  } else {
    out = '${clipped.substring(0, 2)}/${clipped.substring(2)}';
  }
  if (c.text != out) {
    final pos = out.length;
    c.value = TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: pos),
    );
  }
}

Widget _inp(
  BuildContext context,
  TextEditingController c,
  String label, {
  bool isPassword = false,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
  ValueChanged<String>? onChanged,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;

  return TextField(
    controller: c,
    keyboardType: keyboardType,
    obscureText: isPassword,
    inputFormatters: inputFormatters,
    onChanged: onChanged,
    style: TextStyle(color: colorScheme.onBackground),
    decoration: InputDecoration(
      hintText: label,
      hintStyle: TextStyle(color: colorScheme.onBackground.withOpacity(0.5)),
      filled: true,
      fillColor: isDark ? Colors.grey[800] : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: kMainColour, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}

Widget _tip(BuildContext context, String text) {
  final scheme = Theme.of(context).colorScheme;
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

Widget _buildInfoSection(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  const tips = <String>[
    "All card payments are encrypted and securely processed",
    "Refunds are processed within 5-7 business days for eligible transactions",
    "Installment options (Koko, Mintpay) are subject to provider approval",
    "Cash on Delivery available for select locations and order values",
    "Contact support for payment-related questions or issues",
  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _section(
        context: context,
        title: 'Secure Payment Processing',
        child: Text(
          'Choose your preferred payment method for a seamless checkout experience. All payment information is encrypted and securely processed to protect your financial data.',
          style: TextStyle(
            color: scheme.onBackground.withOpacity(0.85),
            height: 1.35,
          ),
        ),
      ),
      const SizedBox(height: 16),
      _section(
        context: context,
        title: 'Payment Options & Support',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...tips.expand(
              (t) => [_tip(context, t), const SizedBox(height: 8)],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.support_agent),
                label: const Text('Contact Support'),
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
    ],
  );
}

Widget _iconsRow(BuildContext context) {
  return Row(
    children: [
      Expanded(
        child: _paymentIcon(
          context,
          'assets/images/icons/Visa.webp',
          fullWidth: true,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _paymentIcon(
          context,
          'assets/images/icons/Mastercard.webp',
          fullWidth: true,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _paymentIcon(
          context,
          'assets/images/icons/Koko.webp',
          fullWidth: true,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _paymentIcon(
          context,
          'assets/images/icons/Mintpay.webp',
          fullWidth: true,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _paymentIcon(
          context,
          'assets/images/icons/COD.webp',
          fullWidth: true,
        ),
      ),
    ],
  );
}

Widget _paymentIcon(
  BuildContext context,
  String asset, {
  bool fullWidth = false,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
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
