import 'package:bytecart_app/theme/theme_colours.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/api_service.dart';

class AccountSettingsState {
  final bool loading;
  final String? errorMessage;
  final String? successMessage;
  final bool connectionError;
  final String name;
  final String email;

  AccountSettingsState({
    this.loading = false,
    this.errorMessage,
    this.successMessage,
    this.connectionError = false,
    this.name = '',
    this.email = '',
  });

  AccountSettingsState copyWith({
    bool? loading,
    String? errorMessage,
    String? successMessage,
    bool? connectionError,
    String? name,
    String? email,
  }) {
    return AccountSettingsState(
      loading: loading ?? this.loading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      connectionError: connectionError ?? this.connectionError,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }
}

class AccountSettingsNotifier extends StateNotifier<AccountSettingsState> {
  AccountSettingsNotifier() : super(AccountSettingsState()) {
    loadUserInfo();
  }

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final currentPassCtrl = TextEditingController();
  final newPassCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();
  final logoutPassCtrl = TextEditingController();
  final deletePassCtrl = TextEditingController();

  Future<void> loadUserInfo() async {
    state = state.copyWith(
      loading: true,
      errorMessage: null,
      successMessage: null,
      connectionError: false,
    );
    try {
      final user = await ApiService.getCachedUserProfile();
      nameCtrl.text = user['name'] ?? '';
      emailCtrl.text = user['email'] ?? '';
      state = state.copyWith(
        loading: false,
        name: nameCtrl.text,
        email: emailCtrl.text,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        errorMessage: 'Could not load user info. Please check your connection.',
        connectionError: true,
      );
    }
  }

  Future<void> updateProfile() async {
    state = state.copyWith(
      loading: true,
      errorMessage: null,
      successMessage: null,
      connectionError: false,
    );
    try {
      await ApiService.updateProfile(
        name: nameCtrl.text.trim(),
        email: emailCtrl.text.trim(),
      );
      state = state.copyWith(
        loading: false,
        successMessage: 'Profile updated successfully.',
      );
      await loadUserInfo();
    } catch (e) {
      state = state.copyWith(
        loading: false,
        errorMessage: 'Failed to update profile. Please try again.',
        connectionError: _isConnectionError(e),
      );
    }
  }

  Future<void> changePassword() async {
    if (newPassCtrl.text != confirmPassCtrl.text) {
      state = state.copyWith(
        errorMessage: 'Passwords do not match.',
        successMessage: null,
      );
      return;
    }
    state = state.copyWith(
      loading: true,
      errorMessage: null,
      successMessage: null,
      connectionError: false,
    );
    try {
      await ApiService.updatePassword(
        currentPassword: currentPassCtrl.text,
        newPassword: newPassCtrl.text,
        confirmPassword: confirmPassCtrl.text,
      );
      state = state.copyWith(
        loading: false,
        successMessage: 'Password changed successfully.',
      );
      currentPassCtrl.clear();
      newPassCtrl.clear();
      confirmPassCtrl.clear();
    } catch (e) {
      state = state.copyWith(
        loading: false,
        errorMessage:
            'Failed to change password. Please check your connection and try again.',
        connectionError: _isConnectionError(e),
      );
    }
  }

  Future<void> logoutOtherSessions() async {
    if (logoutPassCtrl.text.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Enter your password first.',
        successMessage: null,
      );
      return;
    }
    state = state.copyWith(
      loading: true,
      errorMessage: null,
      successMessage: null,
      connectionError: false,
    );
    try {
      await ApiService.logoutOtherSessions(logoutPassCtrl.text);
      state = state.copyWith(
        loading: false,
        successMessage: 'Logged out from other devices.',
      );
      logoutPassCtrl.clear();
    } catch (e) {
      state = state.copyWith(
        loading: false,
        errorMessage:
            'Failed to logout other sessions. Please check your connection.',
        connectionError: _isConnectionError(e),
      );
    }
  }

  Future<void> deleteAccount(BuildContext context) async {
    if (deletePassCtrl.text.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Enter your password first.',
        successMessage: null,
      );
      return;
    }
    state = state.copyWith(
      loading: true,
      errorMessage: null,
      successMessage: null,
      connectionError: false,
    );
    try {
      await ApiService.deleteAccount(deletePassCtrl.text);
      state = state.copyWith(
        loading: false,
        successMessage: 'Account deleted successfully.',
      );
      Navigator.pop(context);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        errorMessage: 'Failed to delete account. Please check your connection.',
        connectionError: _isConnectionError(e),
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  bool _isConnectionError(Object e) {
    return e.toString().toLowerCase().contains('network') ||
        e.toString().toLowerCase().contains('socket') ||
        e.toString().toLowerCase().contains('connection');
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    currentPassCtrl.dispose();
    newPassCtrl.dispose();
    confirmPassCtrl.dispose();
    logoutPassCtrl.dispose();
    deletePassCtrl.dispose();
    super.dispose();
  }
}

final accountSettingsProvider =
    StateNotifierProvider<AccountSettingsNotifier, AccountSettingsState>(
      (ref) => AccountSettingsNotifier(),
    );

final showCurrentProvider = StateProvider<bool>((ref) => false);
final showNewProvider = StateProvider<bool>((ref) => false);
final showConfirmProvider = StateProvider<bool>((ref) => false);
final showLogoutProvider = StateProvider<bool>((ref) => false);
final showDeleteProvider = StateProvider<bool>((ref) => false);

class AccountSettingsPage extends ConsumerWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountSettingsProvider);
    final notifier = ref.read(accountSettingsProvider.notifier);

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.errorMessage != null) {
        _showBanner(
          context,
          state.errorMessage!,
          isError: true,
          isDark: isDark,
        );
        notifier.clearMessages();
      } else if (state.successMessage != null) {
        _showBanner(
          context,
          state.successMessage!,
          isError: false,
          isDark: isDark,
        );
        notifier.clearMessages();
      }
    });

    Widget body =
        state.loading
            ? const Center(child: CircularProgressIndicator())
            : (isLandscape
                ? _buildLandscapeSettingsBody(context, ref)
                : _buildPortraitSettingsBody(context, ref));

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        title: const Text(
          'Profile & Security',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: scheme.background,
        foregroundColor: scheme.onBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        color: isDark ? Colors.white : Colors.black,
        onRefresh:
            () => ref.read(accountSettingsProvider.notifier).loadUserInfo(),
        child: body,
      ),
    );
  }

  void _showBanner(
    BuildContext context,
    String msg, {
    required bool isError,
    required bool isDark,
  }) {
    final bg =
        isError
            ? (isDark ? Colors.red[700] : Colors.red[100])
            : (isDark ? Colors.green[700] : Colors.green[100]);
    final fg =
        isError
            ? (isDark ? Colors.white : Colors.red[900])
            : (isDark ? Colors.white : Colors.green[900]);
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: bg,
        content: Row(
          children: [
            Icon(icon, color: fg),
            const SizedBox(width: 12),
            Expanded(child: Text(msg, style: TextStyle(color: fg))),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildPortraitSettingsBody(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountSettingsProvider);
    final notifier = ref.read(accountSettingsProvider.notifier);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (state.connectionError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              size: 48,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
            const SizedBox(height: 16),
            Text(
              state.errorMessage ??
                  'Connection error. Please check your internet connection.',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => notifier.loadUserInfo(),
              icon: Icon(
                Icons.refresh,
                color: isDark ? Colors.white : Colors.black,
              ),
              label: Text(
                'Retry',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                foregroundColor: isDark ? Colors.white : Colors.black,
                elevation: 0,
              ),
            ),
          ],
        ),
      );
    }

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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _section(
                  title: 'Secure Account Management',
                  child: Text(
                    'Keep your account secure by regularly updating your password, enabling two-factor authentication, and reviewing your account settings. All changes are automatically saved and encrypted.',
                    style: TextStyle(
                      color: scheme.onBackground.withOpacity(0.85),
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _section(
                  title: 'Security Tips & Support',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _tip(
                        'Use a strong, unique password with at least 8 characters',
                        context,
                      ),
                      const SizedBox(height: 8),
                      _tip(
                        'Enable two-factor authentication for enhanced security',
                        context,
                      ),
                      const SizedBox(height: 8),
                      _tip(
                        'Review and manage active browser sessions regularly',
                        context,
                      ),
                      const SizedBox(height: 8),
                      _tip('Keep your contact information up to date', context),
                      const SizedBox(height: 8),
                      _tip(
                        'Contact support if you notice any suspicious activity',
                        context,
                      ),
                      const SizedBox(height: 12),
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
                const SizedBox(height: 16),
                _section(
                  title: 'Profile Information',
                  child: Column(
                    children: [
                      _inp(
                        notifier.nameCtrl,
                        'Name',
                        keyboardType: TextInputType.name,
                        context: context,
                      ),
                      const SizedBox(height: 12),
                      _inp(
                        notifier.emailCtrl,
                        'Email',
                        keyboardType: TextInputType.emailAddress,
                        context: context,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: notifier.updateProfile,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Update Profile'),
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
                const SizedBox(height: 16),
                _section(
                  title: 'Update Password',
                  child: Column(
                    children: [
                      _inp(
                        notifier.currentPassCtrl,
                        'Current Password',
                        obscure: true,
                        showToggle: true,
                        visible: ref.watch(showCurrentProvider),
                        onToggle:
                            () =>
                                ref.read(showCurrentProvider.notifier).state =
                                    !ref.read(showCurrentProvider),
                        context: context,
                      ),
                      const SizedBox(height: 12),
                      _inp(
                        notifier.newPassCtrl,
                        'New Password',
                        obscure: true,
                        showToggle: true,
                        visible: ref.watch(showNewProvider),
                        onToggle:
                            () =>
                                ref.read(showNewProvider.notifier).state =
                                    !ref.read(showNewProvider),
                        context: context,
                      ),
                      const SizedBox(height: 12),
                      _inp(
                        notifier.confirmPassCtrl,
                        'Confirm Password',
                        obscure: true,
                        showToggle: true,
                        visible: ref.watch(showConfirmProvider),
                        onToggle:
                            () =>
                                ref.read(showConfirmProvider.notifier).state =
                                    !ref.read(showConfirmProvider),
                        context: context,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: notifier.changePassword,
                          icon: const Icon(Icons.lock_outline),
                          label: const Text('Change Password'),
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
                const SizedBox(height: 16),
                _section(
                  title: 'Logout Other Sessions',
                  child: Column(
                    children: [
                      _inp(
                        notifier.logoutPassCtrl,
                        'Password',
                        obscure: true,
                        showToggle: true,
                        visible: ref.watch(showLogoutProvider),
                        onToggle:
                            () =>
                                ref.read(showLogoutProvider.notifier).state =
                                    !ref.read(showLogoutProvider),
                        context: context,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: notifier.logoutOtherSessions,
                          icon: const Icon(Icons.logout_outlined),
                          label: const Text('Logout Other Devices'),
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
                const SizedBox(height: 16),
                _section(
                  title: 'Delete Account',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This action is permanent. Please confirm your password to delete your account.',
                        style: TextStyle(
                          color: scheme.onBackground.withOpacity(0.8),
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _inp(
                        notifier.deletePassCtrl,
                        'Password',
                        obscure: true,
                        showToggle: true,
                        visible: ref.watch(showDeleteProvider),
                        onToggle:
                            () =>
                                ref.read(showDeleteProvider.notifier).state =
                                    !ref.read(showDeleteProvider),
                        context: context,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => notifier.deleteAccount(context),
                          icon: const Icon(Icons.delete_forever_outlined),
                          label: const Text('Delete Account'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
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

  Widget _buildLandscapeSettingsBody(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountSettingsProvider);
    final notifier = ref.read(accountSettingsProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (state.connectionError) {
      return _buildPortraitSettingsBody(context, ref);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final bool isWide = w >= 1000;
        final bool isMedium = w >= 800 && w < 1000;
        final rightMaxWidth = isWide ? 420.0 : 360.0;

        if (isWide || isMedium) {
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
                      behavior: const ScrollBehavior().copyWith(
                        overscroll: false,
                      ),
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _section(
                              title: 'Profile Information',
                              child: Column(
                                children: [
                                  _inp(
                                    notifier.nameCtrl,
                                    'Name',
                                    keyboardType: TextInputType.name,
                                    context: context,
                                  ),
                                  const SizedBox(height: 12),
                                  _inp(
                                    notifier.emailCtrl,
                                    'Email',
                                    keyboardType: TextInputType.emailAddress,
                                    context: context,
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: notifier.updateProfile,
                                      icon: const Icon(Icons.save_outlined),
                                      label: const Text('Update Profile'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kMainColour,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                            const SizedBox(height: 16),
                            _section(
                              title: 'Update Password',
                              child: Column(
                                children: [
                                  _inp(
                                    notifier.currentPassCtrl,
                                    'Current Password',
                                    obscure: true,
                                    showToggle: true,
                                    visible: ref.watch(showCurrentProvider),
                                    onToggle:
                                        () =>
                                            ref
                                                .read(
                                                  showCurrentProvider.notifier,
                                                )
                                                .state = !ref.read(
                                                  showCurrentProvider,
                                                ),
                                    context: context,
                                  ),
                                  const SizedBox(height: 12),
                                  _inp(
                                    notifier.newPassCtrl,
                                    'New Password',
                                    obscure: true,
                                    showToggle: true,
                                    visible: ref.watch(showNewProvider),
                                    onToggle:
                                        () =>
                                            ref
                                                .read(showNewProvider.notifier)
                                                .state = !ref.read(
                                                  showNewProvider,
                                                ),
                                    context: context,
                                  ),
                                  const SizedBox(height: 12),
                                  _inp(
                                    notifier.confirmPassCtrl,
                                    'Confirm Password',
                                    obscure: true,
                                    showToggle: true,
                                    visible: ref.watch(showConfirmProvider),
                                    onToggle:
                                        () =>
                                            ref
                                                .read(
                                                  showConfirmProvider.notifier,
                                                )
                                                .state = !ref.read(
                                                  showConfirmProvider,
                                                ),
                                    context: context,
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: notifier.changePassword,
                                      icon: const Icon(Icons.lock_outline),
                                      label: const Text('Change Password'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kMainColour,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                            const SizedBox(height: 16),
                            _section(
                              title: 'Logout Other Sessions',
                              child: Column(
                                children: [
                                  _inp(
                                    notifier.logoutPassCtrl,
                                    'Password',
                                    obscure: true,
                                    showToggle: true,
                                    visible: ref.watch(showLogoutProvider),
                                    onToggle:
                                        () =>
                                            ref
                                                .read(
                                                  showLogoutProvider.notifier,
                                                )
                                                .state = !ref.read(
                                                  showLogoutProvider,
                                                ),
                                    context: context,
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: notifier.logoutOtherSessions,
                                      icon: const Icon(Icons.logout_outlined),
                                      label: const Text('Logout Other Devices'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kMainColour,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                            const SizedBox(height: 16),
                            _section(
                              title: 'Delete Account',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'This action is permanent. Please confirm your password to delete your account.',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onBackground
                                          .withOpacity(0.8),
                                      fontSize: 14,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _inp(
                                    notifier.deletePassCtrl,
                                    'Password',
                                    obscure: true,
                                    showToggle: true,
                                    visible: ref.watch(showDeleteProvider),
                                    onToggle:
                                        () =>
                                            ref
                                                .read(
                                                  showDeleteProvider.notifier,
                                                )
                                                .state = !ref.read(
                                                  showDeleteProvider,
                                                ),
                                    context: context,
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          () => notifier.deleteAccount(context),
                                      icon: const Icon(
                                        Icons.delete_forever_outlined,
                                      ),
                                      label: const Text('Delete Account'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _section(
                                title: 'Secure Account Management',
                                child: Text(
                                  'Keep your account secure by regularly updating your password, enabling two-factor authentication, and reviewing your account settings. All changes are automatically saved and encrypted.',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground
                                        .withOpacity(0.85),
                                    height: 1.35,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _section(
                                title: 'Security Tips & Support',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _tip(
                                      'Use a strong, unique password with at least 8 characters',
                                      context,
                                    ),
                                    const SizedBox(height: 8),
                                    _tip(
                                      'Enable two-factor authentication for enhanced security',
                                      context,
                                    ),
                                    const SizedBox(height: 8),
                                    _tip(
                                      'Review and manage active browser sessions regularly',
                                      context,
                                    ),
                                    const SizedBox(height: 8),
                                    _tip(
                                      'Keep your contact information up to date',
                                      context,
                                    ),
                                    const SizedBox(height: 8),
                                    _tip(
                                      'Contact support if you notice any suspicious activity',
                                      context,
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () {},
                                        icon: const Icon(Icons.support_agent),
                                        label: const Text('Contact Support'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: kMainColour,
                                          side: const BorderSide(
                                            color: kMainColour,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
            ),
          );
        }

        return _buildPortraitSettingsBody(context, ref);
      },
    );
  }

  Widget _section({
    required String title,
    required Widget child,
    BuildContext? context,
  }) {
    final theme = context != null ? Theme.of(context) : ThemeData();
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

  Widget _inp(
    TextEditingController c,
    String label, {
    bool obscure = false,
    TextInputType? keyboardType,
    bool showToggle = false,
    bool visible = false,
    VoidCallback? onToggle,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return TextField(
      controller: c,
      keyboardType: keyboardType,
      obscureText: obscure && !visible,
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
        suffixIcon:
            showToggle
                ? IconButton(
                  icon: Icon(
                    visible ? Icons.visibility : Icons.visibility_off,
                    color: colorScheme.onBackground.withOpacity(0.5),
                  ),
                  onPressed: onToggle,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                )
                : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _tip(String text, BuildContext context) {
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
}
