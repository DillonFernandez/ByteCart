// Login Page: email/password authentication with a segmented control to navigate to Register.
// Responsive: fixed portrait baseline width (scaled down) and a centered landscape layout.
// Shows themed SnackBars, supports Remember Me, and navigates to Home on success.

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/theme_colours.dart';
import 'home.dart';
import 'register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Form controllers and local UI state.
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;
  int _selectedTab = 0; // 0 = Login, 1 = Register

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Perform login and handle success/error feedback and navigation.
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      setState(() => _isLoading = false);

      // Show themed success message.
      final isDark = Theme.of(context).brightness == Brightness.dark;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: isDark ? Colors.white : Colors.black,
          content: Text(
            "Welcome back ${result['user']['name']}!",
            style: TextStyle(color: isDark ? Colors.black : Colors.white),
          ),
        ),
      );

      // Navigate to Home and clear back stack.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _isLoading = false);

      // Show error message from API or exception.
      final theme = Theme.of(context);
      final msg = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.colorScheme.error,
          content: Text(
            msg,
            style: TextStyle(color: theme.colorScheme.onError),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme and layout constants.
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    const double designWidth =
        412.0; // Portrait baseline width for consistent scaling.

    // CHANGED: wrap content with Theme to style cursor/selection/handles
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
                // Title and subtitle.
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

                // Segmented control: Login (active) / Register (navigates).
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color:
                                  _selectedTab == 0
                                      ? Colors.white
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow:
                                  _selectedTab == 0
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
                                    _selectedTab == 0
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

                // Email input.
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
                      return 'Please enter your email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Password input with visibility toggle.
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
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
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: colorScheme.onBackground.withOpacity(0.5),
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
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

                // Remember me and forgot password actions.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          activeColor: kMainColour,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          // CHANGED: rounded checkbox
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
                      onPressed: () {
                        // Add forgot password flow here if implemented.
                      },
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

                // Primary login button with loading state.
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
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
                      _isLoading
                          ? const SizedBox(
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

                // Alternative auth divider text.
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

                // Social login buttons (placeholders for providers).
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Google sign-in entry point (if implemented).
                        },
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
                        onPressed: () {
                          // Apple sign-in entry point (if implemented).
                        },
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

    // Orientation-specific scaffolds.
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      // Portrait: fixed design width and scaled content for visual consistency.
      return Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          // Keep app bar colors stable.
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
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: designWidth,
                    child: MediaQuery(
                      // Lock text scaling for a consistent look.
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
      );
    } else {
      // Landscape: centered, scrollable layout with a wider max width.
      return Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          // Keep app bar colors stable.
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
              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: content,
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
