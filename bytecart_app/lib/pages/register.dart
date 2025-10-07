// Register Page: user account creation with form validation, consent dialog for terms/privacy,
// responsive portrait/landscape layouts, themed SnackBars, and navigation to Home on success.

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/theme_colours.dart';
import 'home.dart';
import 'legal_information.dart';

/// Entry widget for the registration flow.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Form state and text controllers.
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Local UI state.
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _acceptTerms = false;

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks.
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Submit handler: validates inputs, checks terms and password match,
  // calls API, shows feedback, and navigates to Home on success.
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please accept the terms to continue")),
      );
      return;
    }
    // Show mismatch via error SnackBar for a consistent UX.
    if (_passwordController.text != _confirmPasswordController.text) {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.colorScheme.error,
          content: Text(
            'Passwords do not match',
            style: TextStyle(color: theme.colorScheme.onError),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      setState(() => _isLoading = false);

      // Themed success feedback.
      final isDark = Theme.of(context).brightness == Brightness.dark;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: isDark ? Colors.white : Colors.black,
          content: Text(
            "Welcome ${result['user']['name']}!",
            style: TextStyle(color: isDark ? Colors.black : Colors.white),
          ),
        ),
      );

      // Navigate to Home and clear back stack.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _isLoading = false);

      // Show API or unexpected error.
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

  // Displays a consent dialog summarizing Terms & Conditions and Privacy Policy.
  // Sets _acceptTerms when user confirms.
  Future<void> _showConsentDialog() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
                        'Consent Required',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onBackground,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text.rich(
                        TextSpan(
                          text: "By registering, you agree to ByteCart’s ",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onBackground.withOpacity(0.85),
                            fontSize: 16,
                          ),
                          children: [
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const LegalInformationPage(),
                                      settings: RouteSettings(arguments: 0),
                                    ),
                                  );
                                },
                                child: Text(
                                  "Terms & Conditions",
                                  style: TextStyle(
                                    color: kMainColour,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            TextSpan(
                              text: " & ",
                              style: TextStyle(
                                color: colorScheme.onBackground.withOpacity(
                                  0.85,
                                ),
                              ),
                            ),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const LegalInformationPage(),
                                      settings: RouteSettings(arguments: 1),
                                    ),
                                  );
                                },
                                child: Text(
                                  "Privacy Policy",
                                  style: TextStyle(
                                    color: kMainColour,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            TextSpan(
                              text:
                                  ". You confirm that the information provided is accurate and that you are at least 18 years old.",
                              style: TextStyle(
                                color: colorScheme.onBackground.withOpacity(
                                  0.85,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
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
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kMainColour,
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
                            child: const Text('Okay'),
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
    if (result == true) {
      setState(() {
        _acceptTerms = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theming and layout constants.
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    const double designWidth = 412.0;

    // Reusable screen content for both orientations.
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
                // Header: title and subtitle.
                const SizedBox(height: 12),
                Text(
                  'Join ByteCart and start\nshopping today',
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
                  'Create your account to explore the latest electronics',
                  textAlign: TextAlign.left,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onBackground.withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 28),

                // Segmented control: navigate back to Login or stay on Register.
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Text(
                              'Login',
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
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Register',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Name field.
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: colorScheme.onBackground),
                  decoration: InputDecoration(
                    hintText: 'Full Name',
                    hintStyle: TextStyle(
                      color: colorScheme.onBackground.withOpacity(0.5),
                    ),
                    prefixIcon: Icon(
                      Icons.person_outline,
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
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Email field.
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

                // Password field with visibility toggle.
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  textInputAction: TextInputAction.next,
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
                      onPressed:
                          () => setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          }),
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

                // Confirm password field with visibility toggle.
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleRegister(),
                  style: TextStyle(color: colorScheme.onBackground),
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
                    hintStyle: TextStyle(
                      color: colorScheme.onBackground.withOpacity(0.5),
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: colorScheme.onBackground.withOpacity(0.5),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: colorScheme.onBackground.withOpacity(0.5),
                      ),
                      onPressed:
                          () => setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          }),
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
                      return 'Please confirm your password';
                    }
                    return null; // Mismatch handled in submit.
                  },
                ),
                const SizedBox(height: 14),

                // Terms & Privacy acceptance with deep links to details.
                Row(
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) async {
                        if (value == true && !_acceptTerms) {
                          await _showConsentDialog();
                        } else if (value == false && _acceptTerms) {
                          setState(() {
                            _acceptTerms = false;
                          });
                        }
                      },
                      activeColor: kMainColour,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      // CHANGED: rounded checkbox
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'I accept ',
                          style: TextStyle(
                            color: colorScheme.onBackground.withOpacity(0.7),
                          ),
                          children: [
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const LegalInformationPage(),
                                      settings: RouteSettings(arguments: 0),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Terms & Conditions',
                                  style: TextStyle(
                                    color: kMainColour,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            TextSpan(
                              text: ' & ',
                              style: TextStyle(
                                color: colorScheme.onBackground.withOpacity(
                                  0.7,
                                ),
                              ),
                            ),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const LegalInformationPage(),
                                      settings: RouteSettings(arguments: 1),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Privacy Policy',
                                  style: TextStyle(
                                    color: kMainColour,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Submit button with loading state (disabled until terms accepted).
                ElevatedButton(
                  onPressed:
                      (_isLoading || !_acceptTerms) ? null : _handleRegister,
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
                            'Register',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
                const SizedBox(height: 24),

                // Alternative registration methods.
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
                        'Or register with',
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

                // Social register buttons (hook up providers if available).
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Google register entry point (if implemented).
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
                          // Apple register entry point (if implemented).
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

    // Orientation-specific scaffolding: portrait scales to a baseline width; landscape centers wider content.
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.portrait) {
              // Portrait: fixed baseline width + scaled content for consistent look.
              return Center(
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
                          // Lock text scaling for predictable layout.
                          data: MediaQuery.of(
                            context,
                          ).copyWith(textScaler: const TextScaler.linear(1.0)),
                          child: content,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            } else {
              // Landscape: centered, scrollable column with a wider max width.
              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
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
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
