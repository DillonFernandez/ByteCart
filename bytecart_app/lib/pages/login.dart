import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../services/api_service.dart';
import '../theme/theme_colours.dart';
import 'home.dart';
import 'register.dart';

class LoginState {
  final bool isLoading;
  final bool isPasswordVisible;
  final bool rememberMe;
  final String? errorMessage;
  final bool connectionError;
  final String? successMessage;

  LoginState({
    this.isLoading = false,
    this.isPasswordVisible = false,
    this.rememberMe = false,
    this.errorMessage,
    this.connectionError = false,
    this.successMessage,
  });

  LoginState copyWith({
    bool? isLoading,
    bool? isPasswordVisible,
    bool? rememberMe,
    String? errorMessage,
    bool? connectionError,
    String? successMessage,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      rememberMe: rememberMe ?? this.rememberMe,
      errorMessage: errorMessage,
      connectionError: connectionError ?? this.connectionError,
      successMessage: successMessage,
    );
  }
}

class LoginNotifier extends StateNotifier<LoginState> {
  LoginNotifier() : super(LoginState());

  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  void setRememberMe(bool value) {
    state = state.copyWith(rememberMe: value);
  }

  void clearMessages() {
    state = state.copyWith(
      errorMessage: null,
      successMessage: null,
      connectionError: false,
    );
  }

  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
      connectionError: false,
    );
    try {
      final result = await ApiService.login(email: email, password: password);
      state = state.copyWith(
        isLoading: false,
        successMessage: "Welcome back ${result['user']['name']}!",
      );
      return result;
    } on ApiException catch (e) {
      String msg;
      if (e.message.toLowerCase().contains('network') ||
          e.message.toLowerCase().contains('connection')) {
        msg = "Connection error. Please check your internet and try again.";
        state = state.copyWith(
          isLoading: false,
          errorMessage: msg,
          connectionError: true,
        );
      } else {
        msg = "Login failed. Please check your credentials and try again.";
        state = state.copyWith(
          isLoading: false,
          errorMessage: msg,
          connectionError: false,
        );
      }
      return null;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: "An unexpected error occurred. Please try again.",
        connectionError: true,
      );
      return null;
    }
  }
}

final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>(
  (ref) => LoginNotifier(),
);

final selectedTabProvider = StateProvider<int>((ref) => 0);

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginState = ref.watch(loginProvider);
    final loginNotifier = ref.read(loginProvider.notifier);
    final selectedTab = ref.watch(selectedTabProvider);

    final _formKey = GlobalKey<FormState>();
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    const double designWidth = 412.0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (loginState.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: isDark ? Colors.red[400] : Colors.red[100],
            content: Row(
              children: [
                if (loginState.connectionError)
                  Icon(
                    Icons.wifi_off,
                    color: isDark ? Colors.white : Colors.red,
                    size: 22,
                  ),
                if (loginState.connectionError) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loginState.errorMessage!,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.red[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
        loginNotifier.clearMessages();
      } else if (loginState.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: isDark ? Colors.green[400] : Colors.green[100],
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: isDark ? Colors.white : Colors.green[900],
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loginState.successMessage!,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.green[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
        loginNotifier.clearMessages();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      }
    });

    Future<void> _refresh() async {
      _emailController.clear();
      _passwordController.clear();
      loginNotifier.clearMessages();
    }

    final content = Theme(
      data: theme.copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: kMainColour,
          selectionColor: kMainColour.withOpacity(isDark ? 0.35 : 0.25),
          selectionHandleColor: kMainColour,
        ),
      ),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome back to\nByteCart',
                  textAlign: TextAlign.left,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onBackground,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to continue shopping for electronics',
                  textAlign: TextAlign.left,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onBackground.withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap:
                              () =>
                                  ref.read(selectedTabProvider.notifier).state =
                                      0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color:
                                  selectedTab == 0
                                      ? Colors.white
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow:
                                  selectedTab == 0
                                      ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                      : null,
                            ),
                            child: Text(
                              'Login',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:
                                    selectedTab == 0
                                        ? Colors.black
                                        : colorScheme.onBackground.withOpacity(
                                          0.6,
                                        ),
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            ref.read(selectedTabProvider.notifier).state = 1;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterPage(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Text(
                              'Register',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colorScheme.onBackground.withOpacity(
                                  0.6,
                                ),
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: colorScheme.onBackground),
                  decoration: InputDecoration(
                    hintText: 'E-mail ID',
                    hintStyle: TextStyle(
                      color: colorScheme.onBackground.withOpacity(0.5),
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: colorScheme.onBackground.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: kMainColour, width: 2),
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email address';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !loginState.isPasswordVisible,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) async {
                    if (_formKey.currentState!.validate()) {
                      await loginNotifier.login(
                        email: _emailController.text.trim(),
                        password: _passwordController.text,
                      );
                    }
                  },
                  style: TextStyle(color: colorScheme.onBackground),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(
                      color: colorScheme.onBackground.withOpacity(0.5),
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: colorScheme.onBackground.withOpacity(0.5),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        loginState.isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: colorScheme.onBackground.withOpacity(0.5),
                      ),
                      onPressed: () {
                        loginNotifier.togglePasswordVisibility();
                      },
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: kMainColour, width: 2),
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: loginState.rememberMe,
                          onChanged: (value) {
                            loginNotifier.setRememberMe(value ?? false);
                          },
                          activeColor: kMainColour,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        Text(
                          'Remember me',
                          style: TextStyle(
                            color: colorScheme.onBackground.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: kMainColour,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Forget Password?'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed:
                      loginState.isLoading
                          ? null
                          : () async {
                            if (_formKey.currentState!.validate()) {
                              await loginNotifier.login(
                                email: _emailController.text.trim(),
                                password: _passwordController.text,
                              );
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kMainColour,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child:
                      loginState.isLoading
                          ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: colorScheme.onBackground.withOpacity(0.2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Or login with',
                        style: TextStyle(
                          color: colorScheme.onBackground.withOpacity(0.5),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: colorScheme.onBackground.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: Image.asset(
                          isDark
                              ? 'assets/images/icons/google_d.webp'
                              : 'assets/images/icons/google_l.webp',
                          width: 20,
                          height: 20,
                        ),
                        label: const Text('Google'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.onBackground,
                          side: BorderSide(
                            color: colorScheme.onBackground.withOpacity(0.2),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: Image.asset(
                          isDark
                              ? 'assets/images/icons/apple_d.webp'
                              : 'assets/images/icons/apple_l.webp',
                          width: 20,
                          height: 20,
                        ),
                        label: const Text('Apple'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.onBackground,
                          side: BorderSide(
                            color: colorScheme.onBackground.withOpacity(0.2),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );

    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      return Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          backgroundColor: colorScheme.background,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          foregroundColor: colorScheme.onBackground,
          elevation: 0,
        ),
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: designWidth),
              child: RefreshIndicator(
                color: isDark ? Colors.white : Colors.black,
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: designWidth,
                      child: MediaQuery(
                        data: MediaQuery.of(
                          context,
                        ).copyWith(textScaler: const TextScaler.linear(1.0)),
                        child: content,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          backgroundColor: colorScheme.background,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          foregroundColor: colorScheme.onBackground,
          elevation: 0,
        ),
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return RefreshIndicator(
                color: isDark ? Colors.white : Colors.black,
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: content,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
  }
}
