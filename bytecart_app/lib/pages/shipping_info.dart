import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/api_service.dart';
import 'package:bytecart_app/theme/theme_colours.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShippingInfoState {
  final bool loading;
  final bool saving;
  final bool billingSame;
  final bool locatingShip;
  final bool locatingBill;
  final Map<String, String> fields;
  final String? errorMessage;
  final String? successMessage;

  ShippingInfoState({
    this.loading = true,
    this.saving = false,
    this.billingSame = false,
    this.locatingShip = false,
    this.locatingBill = false,
    this.fields = const {},
    this.errorMessage,
    this.successMessage,
  });

  ShippingInfoState copyWith({
    bool? loading,
    bool? saving,
    bool? billingSame,
    bool? locatingShip,
    bool? locatingBill,
    Map<String, String>? fields,
    String? errorMessage,
    String? successMessage,
  }) {
    return ShippingInfoState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      billingSame: billingSame ?? this.billingSame,
      locatingShip: locatingShip ?? this.locatingShip,
      locatingBill: locatingBill ?? this.locatingBill,
      fields: fields ?? this.fields,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class ShippingInfoNotifier extends StateNotifier<ShippingInfoState> {
  ShippingInfoNotifier() : super(ShippingInfoState()) {
    fetchInfo();
  }

  Future<void> fetchInfo() async {
    try {
      final data = await ApiService.getShippingInfo();
      state = state.copyWith(
        loading: false,
        fields: {
          'phone_number': data['phone_number'] ?? '',
          'shipping_street_address': data['shipping_street_address'] ?? '',
          'shipping_city': data['shipping_city'] ?? '',
          'shipping_district': data['shipping_district'] ?? '',
          'shipping_zip_code': data['shipping_zip_code'] ?? '',
          'shipping_apartment_suite': data['shipping_apartment_suite'] ?? '',
          'billing_street_address': data['billing_street_address'] ?? '',
          'billing_city': data['billing_city'] ?? '',
          'billing_district': data['billing_district'] ?? '',
          'billing_zip_code': data['billing_zip_code'] ?? '',
          'billing_apartment_suite': data['billing_apartment_suite'] ?? '',
        },
        billingSame: data['is_billing_same_as_shipping'] ?? false,
        errorMessage: null,
        successMessage: null,
      );
    } catch (_) {
      state = state.copyWith(
        loading: false,
        errorMessage:
            'Unable to load address info. Please check your connection.',
      );
    }
  }

  Future<void> save(Map<String, String> fields, bool billingSame) async {
    state = state.copyWith(
      saving: true,
      errorMessage: null,
      successMessage: null,
    );
    try {
      await ApiService.updateShippingInfo({
        ...fields,
        "is_billing_same_as_shipping": billingSame ? 1 : 0,
      });
      state = state.copyWith(
        saving: false,
        successMessage: "Address updated successfully",
        errorMessage: null,
        fields: fields,
        billingSame: billingSame,
      );
    } catch (_) {
      state = state.copyWith(
        saving: false,
        errorMessage: 'Unable to save address. Please check your connection.',
        successMessage: null,
      );
    }
  }

  void setBillingSame(bool value) {
    state = state.copyWith(billingSame: value);
  }

  void setField(String key, String value) {
    final updated = Map<String, String>.from(state.fields);
    updated[key] = value;
    state = state.copyWith(fields: updated);
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  Future<void> getLocationAndFill({required bool billing}) async {
    if (billing) {
      state = state.copyWith(
        locatingBill: true,
        errorMessage: null,
        successMessage: null,
      );
    } else {
      state = state.copyWith(
        locatingShip: true,
        errorMessage: null,
        successMessage: null,
      );
    }
    try {
      if (!await _ensureLocationPermission()) {
        _setLocationBusy(billing, false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final places = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (places.isEmpty) {
        _setLocationBusy(billing, false);
        state = state.copyWith(errorMessage: 'Unable to resolve location.');
        return;
      }
      final p = places.first;
      final city =
          (p.locality?.trim().isNotEmpty == true
              ? p.locality!.trim()
              : (p.subAdministrativeArea ?? '').trim());
      final district =
          (p.subAdministrativeArea?.trim().isNotEmpty == true
              ? p.subAdministrativeArea!.trim()
              : (p.administrativeArea ?? '').trim());
      final zip = (p.postalCode ?? '').replaceAll(RegExp(r'[^0-9]'), '');

      final updated = Map<String, String>.from(state.fields);
      if (billing) {
        if (city.isNotEmpty) updated['billing_city'] = city;
        if (district.isNotEmpty) updated['billing_district'] = district;
        if (zip.isNotEmpty) updated['billing_zip_code'] = zip;
      } else {
        if (city.isNotEmpty) updated['shipping_city'] = city;
        if (district.isNotEmpty) updated['shipping_district'] = district;
        if (zip.isNotEmpty) updated['shipping_zip_code'] = zip;
      }
      state = state.copyWith(
        fields: updated,
        successMessage: 'Location applied',
        errorMessage: null,
      );
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Unable to get location. Please check your connection.',
        successMessage: null,
      );
    } finally {
      _setLocationBusy(billing, false);
    }
  }

  void _setLocationBusy(bool billing, bool value) {
    if (billing) {
      state = state.copyWith(locatingBill: value);
    } else {
      state = state.copyWith(locatingShip: value);
    }
  }

  Future<bool> _ensureLocationPermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      state = state.copyWith(errorMessage: 'Location services disabled.');
      return false;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) {
      state = state.copyWith(errorMessage: 'Location permission denied.');
      return false;
    }
    if (perm == LocationPermission.deniedForever) {
      state = state.copyWith(
        errorMessage: 'Location permission permanently denied.',
      );
      return false;
    }
    return true;
  }
}

final shippingInfoProvider =
    StateNotifierProvider<ShippingInfoNotifier, ShippingInfoState>(
      (ref) => ShippingInfoNotifier(),
    );

final shippingControllersProvider =
    Provider.autoDispose<Map<String, TextEditingController>>((ref) {
      final ctrls = <String, TextEditingController>{
        'phone_number': TextEditingController(),
        'shipping_street_address': TextEditingController(),
        'shipping_city': TextEditingController(),
        'shipping_district': TextEditingController(),
        'shipping_zip_code': TextEditingController(),
        'shipping_apartment_suite': TextEditingController(),
        'billing_street_address': TextEditingController(),
        'billing_city': TextEditingController(),
        'billing_district': TextEditingController(),
        'billing_zip_code': TextEditingController(),
        'billing_apartment_suite': TextEditingController(),
      };
      ref.onDispose(() {
        for (final c in ctrls.values) {
          c.dispose();
        }
      });
      return ctrls;
    });

class ShippingInfoPage extends ConsumerWidget {
  const ShippingInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shippingInfoProvider);
    final ctrls = ref.watch(shippingControllersProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final isDark = theme.brightness == Brightness.dark;

    for (final entry in ctrls.entries) {
      final v = state.fields[entry.key] ?? '';
      if (entry.value.text != v) {
        entry.value.text = v;
        entry.value.selection = TextSelection.collapsed(offset: v.length);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.errorMessage != null) {
        _showError(context, state.errorMessage!);
        ref.read(shippingInfoProvider.notifier).clearMessages();
      } else if (state.successMessage != null) {
        _showSuccess(context, state.successMessage!);
        ref.read(shippingInfoProvider.notifier).clearMessages();
      }
    });

    if (state.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        title: const Text(
          'Manage Addresses',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: scheme.background,
        foregroundColor: scheme.onBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body:
          isLandscape
              ? _buildLandscapeShippingBody(context, ref, ctrls)
              : SafeArea(
                top: false,
                bottom: false,
                child: RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(shippingInfoProvider.notifier).fetchInfo();
                  },
                  color: isDark ? Colors.white : Colors.black,
                  backgroundColor: scheme.background,
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
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildInfoSection(context),
                            const SizedBox(height: 16),
                            _section(
                              context: context,
                              title: 'Shipping Info',
                              trailing: _getLocationButton(
                                context: context,
                                busy: state.locatingShip,
                                onPressed:
                                    () => ref
                                        .read(shippingInfoProvider.notifier)
                                        .getLocationAndFill(billing: false),
                              ),
                              child: Column(
                                children: [
                                  _inp(
                                    context,
                                    ctrls['phone_number']!,
                                    'Phone Number',
                                    keyboardType: TextInputType.phone,
                                    onChanged: (v) {
                                      ref
                                          .read(shippingInfoProvider.notifier)
                                          .setField('phone_number', v);
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _inp(
                                    context,
                                    ctrls['shipping_street_address']!,
                                    'Street',
                                    onChanged: (v) {
                                      ref
                                          .read(shippingInfoProvider.notifier)
                                          .setField(
                                            'shipping_street_address',
                                            v,
                                          );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _inp(
                                    context,
                                    ctrls['shipping_apartment_suite']!,
                                    'Apartment/Suite',
                                    onChanged: (v) {
                                      ref
                                          .read(shippingInfoProvider.notifier)
                                          .setField(
                                            'shipping_apartment_suite',
                                            v,
                                          );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _inp(
                                    context,
                                    ctrls['shipping_city']!,
                                    'City',
                                    onChanged: (v) {
                                      ref
                                          .read(shippingInfoProvider.notifier)
                                          .setField('shipping_city', v);
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _inp(
                                    context,
                                    ctrls['shipping_district']!,
                                    'District',
                                    onChanged: (v) {
                                      ref
                                          .read(shippingInfoProvider.notifier)
                                          .setField('shipping_district', v);
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _inp(
                                    context,
                                    ctrls['shipping_zip_code']!,
                                    'Zip Code',
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) {
                                      ref
                                          .read(shippingInfoProvider.notifier)
                                          .setField('shipping_zip_code', v);
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: state.billingSame,
                                        onChanged:
                                            (v) => ref
                                                .read(
                                                  shippingInfoProvider.notifier,
                                                )
                                                .setBillingSame(v ?? false),
                                        activeColor: kMainColour,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                      ),
                                      const Text(
                                        "Billing address same as shipping",
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (!state.billingSame) const SizedBox(height: 16),
                            if (!state.billingSame)
                              _section(
                                context: context,
                                title: 'Billing Info',
                                trailing: _getLocationButton(
                                  context: context,
                                  busy: state.locatingBill,
                                  onPressed:
                                      () => ref
                                          .read(shippingInfoProvider.notifier)
                                          .getLocationAndFill(billing: true),
                                ),
                                child: Column(
                                  children: [
                                    _inp(
                                      context,
                                      ctrls['billing_street_address']!,
                                      'Street',
                                      onChanged: (v) {
                                        ref
                                            .read(shippingInfoProvider.notifier)
                                            .setField(
                                              'billing_street_address',
                                              v,
                                            );
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    _inp(
                                      context,
                                      ctrls['billing_apartment_suite']!,
                                      'Apartment/Suite',
                                      onChanged: (v) {
                                        ref
                                            .read(shippingInfoProvider.notifier)
                                            .setField(
                                              'billing_apartment_suite',
                                              v,
                                            );
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    _inp(
                                      context,
                                      ctrls['billing_city']!,
                                      'City',
                                      onChanged: (v) {
                                        ref
                                            .read(shippingInfoProvider.notifier)
                                            .setField('billing_city', v);
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    _inp(
                                      context,
                                      ctrls['billing_district']!,
                                      'District',
                                      onChanged: (v) {
                                        ref
                                            .read(shippingInfoProvider.notifier)
                                            .setField('billing_district', v);
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    _inp(
                                      context,
                                      ctrls['billing_zip_code']!,
                                      'Zip Code',
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) {
                                        ref
                                            .read(shippingInfoProvider.notifier)
                                            .setField('billing_zip_code', v);
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed:
                                    state.saving
                                        ? null
                                        : () {
                                          ref
                                              .read(
                                                shippingInfoProvider.notifier,
                                              )
                                              .save({
                                                for (final entry
                                                    in ctrls.entries)
                                                  entry.key: entry.value.text,
                                              }, state.billingSame);
                                        },
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
                                        : const Text("Save Address"),
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
                ),
              ),
    );
  }

  Widget _buildLandscapeShippingBody(
    BuildContext context,
    WidgetRef ref,
    Map<String, TextEditingController> ctrls,
  ) {
    final state = ref.watch(shippingInfoProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final double w = MediaQuery.of(context).size.width;
    final bool isWide = w >= 1000;
    final bool isMedium = w >= 800 && w < 1000;

    if (isWide || isMedium) {
      final rightMaxWidth = isWide ? 420.0 : 360.0;
      return SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ScrollConfiguration(
                  behavior: const ScrollBehavior().copyWith(overscroll: false),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _section(
                            context: context,
                            title: 'Shipping Info',
                            trailing: _getLocationButton(
                              context: context,
                              busy: state.locatingShip,
                              onPressed:
                                  () => ref
                                      .read(shippingInfoProvider.notifier)
                                      .getLocationAndFill(billing: false),
                            ),
                            child: Column(
                              children: [
                                _inp(
                                  context,
                                  ctrls['phone_number']!,
                                  'Phone Number',
                                  keyboardType: TextInputType.phone,
                                  onChanged: (v) {
                                    ref
                                        .read(shippingInfoProvider.notifier)
                                        .setField('phone_number', v);
                                  },
                                ),
                                const SizedBox(height: 12),
                                _inp(
                                  context,
                                  ctrls['shipping_street_address']!,
                                  'Street',
                                  onChanged: (v) {
                                    ref
                                        .read(shippingInfoProvider.notifier)
                                        .setField('shipping_street_address', v);
                                  },
                                ),
                                const SizedBox(height: 12),
                                _inp(
                                  context,
                                  ctrls['shipping_apartment_suite']!,
                                  'Apartment/Suite',
                                  onChanged: (v) {
                                    ref
                                        .read(shippingInfoProvider.notifier)
                                        .setField(
                                          'shipping_apartment_suite',
                                          v,
                                        );
                                  },
                                ),
                                const SizedBox(height: 12),
                                _inp(
                                  context,
                                  ctrls['shipping_city']!,
                                  'City',
                                  onChanged: (v) {
                                    ref
                                        .read(shippingInfoProvider.notifier)
                                        .setField('shipping_city', v);
                                  },
                                ),
                                const SizedBox(height: 12),
                                _inp(
                                  context,
                                  ctrls['shipping_district']!,
                                  'District',
                                  onChanged: (v) {
                                    ref
                                        .read(shippingInfoProvider.notifier)
                                        .setField('shipping_district', v);
                                  },
                                ),
                                const SizedBox(height: 12),
                                _inp(
                                  context,
                                  ctrls['shipping_zip_code']!,
                                  'Zip Code',
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) {
                                    ref
                                        .read(shippingInfoProvider.notifier)
                                        .setField('shipping_zip_code', v);
                                  },
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: state.billingSame,
                                      onChanged:
                                          (v) => ref
                                              .read(
                                                shippingInfoProvider.notifier,
                                              )
                                              .setBillingSame(v ?? false),
                                      activeColor: kMainColour,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                    const Text(
                                      "Billing address same as shipping",
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (!state.billingSame)
                            _section(
                              context: context,
                              title: 'Billing Info',
                              trailing: _getLocationButton(
                                context: context,
                                busy: state.locatingBill,
                                onPressed:
                                    () => ref
                                        .read(shippingInfoProvider.notifier)
                                        .getLocationAndFill(billing: true),
                              ),
                              child: Column(
                                children: [
                                  _inp(
                                    context,
                                    ctrls['billing_street_address']!,
                                    'Street',
                                    onChanged: (v) {
                                      ref
                                          .read(shippingInfoProvider.notifier)
                                          .setField(
                                            'billing_street_address',
                                            v,
                                          );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _inp(
                                    context,
                                    ctrls['billing_apartment_suite']!,
                                    'Apartment/Suite',
                                    onChanged: (v) {
                                      ref
                                          .read(shippingInfoProvider.notifier)
                                          .setField(
                                            'billing_apartment_suite',
                                            v,
                                          );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _inp(
                                    context,
                                    ctrls['billing_city']!,
                                    'City',
                                    onChanged: (v) {
                                      ref
                                          .read(shippingInfoProvider.notifier)
                                          .setField('billing_city', v);
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _inp(
                                    context,
                                    ctrls['billing_district']!,
                                    'District',
                                    onChanged: (v) {
                                      ref
                                          .read(shippingInfoProvider.notifier)
                                          .setField('billing_district', v);
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _inp(
                                    context,
                                    ctrls['billing_zip_code']!,
                                    'Zip Code',
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) {
                                      ref
                                          .read(shippingInfoProvider.notifier)
                                          .setField('billing_zip_code', v);
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  state.saving
                                      ? null
                                      : () {
                                        ref
                                            .read(shippingInfoProvider.notifier)
                                            .save({
                                              for (final entry in ctrls.entries)
                                                entry.key: entry.value.text,
                                            }, state.billingSame);
                                      },
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
                                      : const Text("Save Address"),
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
              ),
              const SizedBox(width: 20),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: rightMaxWidth),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
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
                        child: _buildInfoSection(context),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SafeArea(
      top: false,
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          await ref.read(shippingInfoProvider.notifier).fetchInfo();
        },
        color: isDark ? Colors.white : Colors.black,
        backgroundColor: Theme.of(context).colorScheme.background,
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
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _section(
                    context: context,
                    title: 'Shipping Info',
                    trailing: _getLocationButton(
                      context: context,
                      busy: state.locatingShip,
                      onPressed:
                          () => ref
                              .read(shippingInfoProvider.notifier)
                              .getLocationAndFill(billing: false),
                    ),
                    child: Column(
                      children: [
                        _inp(
                          context,
                          ctrls['phone_number']!,
                          'Phone Number',
                          keyboardType: TextInputType.phone,
                          onChanged: (v) {
                            ref
                                .read(shippingInfoProvider.notifier)
                                .setField('phone_number', v);
                          },
                        ),
                        const SizedBox(height: 12),
                        _inp(
                          context,
                          ctrls['shipping_street_address']!,
                          'Street',
                          onChanged: (v) {
                            ref
                                .read(shippingInfoProvider.notifier)
                                .setField('shipping_street_address', v);
                          },
                        ),
                        const SizedBox(height: 12),
                        _inp(
                          context,
                          ctrls['shipping_apartment_suite']!,
                          'Apartment/Suite',
                          onChanged: (v) {
                            ref
                                .read(shippingInfoProvider.notifier)
                                .setField('shipping_apartment_suite', v);
                          },
                        ),
                        const SizedBox(height: 12),
                        _inp(
                          context,
                          ctrls['shipping_city']!,
                          'City',
                          onChanged: (v) {
                            ref
                                .read(shippingInfoProvider.notifier)
                                .setField('shipping_city', v);
                          },
                        ),
                        const SizedBox(height: 12),
                        _inp(
                          context,
                          ctrls['shipping_district']!,
                          'District',
                          onChanged: (v) {
                            ref
                                .read(shippingInfoProvider.notifier)
                                .setField('shipping_district', v);
                          },
                        ),
                        const SizedBox(height: 12),
                        _inp(
                          context,
                          ctrls['shipping_zip_code']!,
                          'Zip Code',
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            ref
                                .read(shippingInfoProvider.notifier)
                                .setField('shipping_zip_code', v);
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Checkbox(
                              value: state.billingSame,
                              onChanged:
                                  (v) => ref
                                      .read(shippingInfoProvider.notifier)
                                      .setBillingSame(v ?? false),
                              activeColor: kMainColour,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            const Text("Billing address same as shipping"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!state.billingSame) const SizedBox(height: 16),
                  if (!state.billingSame)
                    _section(
                      context: context,
                      title: 'Billing Info',
                      trailing: _getLocationButton(
                        context: context,
                        busy: state.locatingBill,
                        onPressed:
                            () => ref
                                .read(shippingInfoProvider.notifier)
                                .getLocationAndFill(billing: true),
                      ),
                      child: Column(
                        children: [
                          _inp(
                            context,
                            ctrls['billing_street_address']!,
                            'Street',
                            onChanged: (v) {
                              ref
                                  .read(shippingInfoProvider.notifier)
                                  .setField('billing_street_address', v);
                            },
                          ),
                          const SizedBox(height: 12),
                          _inp(
                            context,
                            ctrls['billing_apartment_suite']!,
                            'Apartment/Suite',
                            onChanged: (v) {
                              ref
                                  .read(shippingInfoProvider.notifier)
                                  .setField('billing_apartment_suite', v);
                            },
                          ),
                          const SizedBox(height: 12),
                          _inp(
                            context,
                            ctrls['billing_city']!,
                            'City',
                            onChanged: (v) {
                              ref
                                  .read(shippingInfoProvider.notifier)
                                  .setField('billing_city', v);
                            },
                          ),
                          const SizedBox(height: 12),
                          _inp(
                            context,
                            ctrls['billing_district']!,
                            'District',
                            onChanged: (v) {
                              ref
                                  .read(shippingInfoProvider.notifier)
                                  .setField('billing_district', v);
                            },
                          ),
                          const SizedBox(height: 12),
                          _inp(
                            context,
                            ctrls['billing_zip_code']!,
                            'Zip Code',
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              ref
                                  .read(shippingInfoProvider.notifier)
                                  .setField('billing_zip_code', v);
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          state.saving
                              ? null
                              : () {
                                ref.read(shippingInfoProvider.notifier).save({
                                  for (final entry in ctrls.entries)
                                    entry.key: entry.value.text,
                                }, state.billingSame);
                              },
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
                              : const Text("Save Address"),
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
                  _buildInfoSection(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _showSuccess(BuildContext context, String msg) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final bg = isDark ? Colors.white : Colors.black;
  final fg = isDark ? Colors.black : Colors.white;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: bg,
      content: Row(
        children: [
          Icon(Icons.check_circle, color: fg),
          const SizedBox(width: 12),
          Expanded(child: Text(msg, style: TextStyle(color: fg))),
        ],
      ),
    ),
  );
}

void _showError(BuildContext context, String msg) {
  final cs = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: cs.error,
      content: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(msg, style: TextStyle(color: cs.onError))),
        ],
      ),
    ),
  );
}

Widget _getLocationButton({
  required BuildContext context,
  required bool busy,
  required VoidCallback onPressed,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final Color c = isDark ? Colors.white : Colors.black;
  return OutlinedButton.icon(
    onPressed: busy ? null : onPressed,
    icon: const Icon(Icons.my_location),
    label: Text(busy ? 'Getting location...' : 'Get location'),
    style: OutlinedButton.styleFrom(
      foregroundColor: c,
      side: BorderSide(color: c),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}

Widget _section({
  required BuildContext context,
  required String title,
  required Widget child,
  Widget? trailing,
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
            if (trailing != null) trailing,
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

Widget _inp(
  BuildContext context,
  TextEditingController c,
  String label, {
  bool obscure = false,
  TextInputType? keyboardType,
  void Function(String)? onChanged,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;

  return TextField(
    controller: c,
    keyboardType: keyboardType,
    obscureText: obscure,
    style: TextStyle(color: colorScheme.onBackground),
    onChanged: onChanged,
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
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kMainColour, width: 2),
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
    "Your address information is kept private and secure",
    "We deliver to most locations across Sri Lanka",
    "Delivery times may vary by location and availability",
    "Include apartment/suite numbers for accurate delivery",
    "Contact support for special delivery instructions",
  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _section(
        context: context,
        title: 'Secure Address Management',
        child: Text(
          'Keep your shipping and billing information up to date for faster checkout and accurate deliveries. All address information is encrypted and kept secure.',
          style: TextStyle(
            color: scheme.onBackground.withOpacity(0.85),
            height: 1.35,
          ),
        ),
      ),
      const SizedBox(height: 16),
      _section(
        context: context,
        title: 'Shipping Tips & Support',
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
