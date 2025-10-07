import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../services/api_service.dart';
import '../theme/theme_colours.dart';
import 'home.dart';
import 'legal_information.dart';

final nameControllerProvider = Provider.autoDispose(
  (ref) => TextEditingController(),
);
final emailControllerProvider = Provider.autoDispose(
  (ref) => TextEditingController(),
);
final passwordControllerProvider = Provider.autoDispose(
  (ref) => TextEditingController(),
);
final confirmPasswordControllerProvider = Provider.autoDispose(
  (ref) => TextEditingController(),
);

final isPasswordVisibleProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);
final isConfirmPasswordVisibleProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);
final isLoadingProvider = StateProvider.autoDispose<bool>((ref) => false);
final acceptTermsProvider = StateProvider.autoDispose<bool>((ref) => false);

class RegisterMessage {
  final String? message;
  final bool isError;
  final IconData? icon;

  RegisterMessage({this.message, this.isError = false, this.icon});
}

final registerMessageProvider = StateProvider.autoDispose<RegisterMessage?>(
  (ref) => null,
);

class RegisterController extends StateNotifier<void> {
  final Ref ref;

  RegisterController(this.ref) : super(null);

  Future<void> register(BuildContext context) async {
    final formKey = ref.read(_formKeyProvider);
    final nameCtrl = ref.read(nameControllerProvider);
    final emailCtrl = ref.read(emailControllerProvider);
    final passCtrl = ref.read(passwordControllerProvider);
    final confirmCtrl = ref.read(confirmPasswordControllerProvider);
    final acceptTerms = ref.read(acceptTermsProvider);

    if (!formKey.currentState!.validate()) return;
    if (!acceptTerms) {
      ref.read(registerMessageProvider.notifier).state = RegisterMessage(
        message: "Please accept the terms to continue.",
        isError: true,
        icon: Icons.privacy_tip_outlined,
      );
      return;
    }
    if (passCtrl.text != confirmCtrl.text) {
      ref.read(registerMessageProvider.notifier).state = RegisterMessage(
        message: "Passwords do not match. Please try again.",
        isError: true,
        icon: Icons.lock_person_outlined,
      );
      return;
    }

    ref.read(isLoadingProvider.notifier).state = true;
    ref.read(registerMessageProvider.notifier).state = null;

    try {
      final result = await ApiService.register(
        name: nameCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        password: passCtrl.text,
        confirmPassword: confirmCtrl.text,
      );
      ref.read(isLoadingProvider.notifier).state = false;

      ref.read(registerMessageProvider.notifier).state = RegisterMessage(
        message: "Welcome ${result['user']['name']}!",
        isError: false,
        icon: Icons.check_circle_outline,
      );

      Future.delayed(const Duration(milliseconds: 800), () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      });
    } on ApiException catch (e) {
      ref.read(isLoadingProvider.notifier).state = false;
      ref.read(registerMessageProvider.notifier).state = RegisterMessage(
        message: e.message ?? "Registration failed. Please try again.",
        isError: true,
        icon: Icons.error_outline,
      );
    } catch (e) {
      ref.read(isLoadingProvider.notifier).state = false;
      ref.read(registerMessageProvider.notifier).state = RegisterMessage(
        message: "Connection error. Please check your internet and try again.",
        isError: true,
        icon: Icons.wifi_off,
      );
    }
  }
}

final registerControllerProvider =
    StateNotifierProvider.autoDispose<RegisterController, void>(
      (ref) => RegisterController(ref),
    );

final _formKeyProvider = Provider.autoDispose<GlobalKey<FormState>>(
  (ref) => GlobalKey<FormState>(),
);

final _registerPageContextProvider = StateProvider<BuildContext?>(
  (ref) => null,
);

class RegisterPage extends ConsumerWidget {
  const RegisterPage({super.key});

  Future<void> _showConsentDialog(BuildContext context, WidgetRef ref) async {
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
                                      settings: const RouteSettings(
                                        arguments: 0,
                                      ),
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
                                      settings: const RouteSettings(
                                        arguments: 1,
                                      ),
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
      ref.read(acceptTermsProvider.notifier).state = true;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    const double designWidth = 412.0;

    final nameController = ref.watch(nameControllerProvider);
    final emailController = ref.watch(emailControllerProvider);
    final passwordController = ref.watch(passwordControllerProvider);
    final confirmPasswordController = ref.watch(
      confirmPasswordControllerProvider,
    );
    final isPasswordVisible = ref.watch(isPasswordVisibleProvider);
    final isConfirmPasswordVisible = ref.watch(
      isConfirmPasswordVisibleProvider,
    );
    final isLoading = ref.watch(isLoadingProvider);
    final acceptTerms = ref.watch(acceptTermsProvider);
    final message = ref.watch(registerMessageProvider);
    final formKey = ref.watch(_formKeyProvider);

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
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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

                TextFormField(
                  controller: nameController,
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

                TextFormField(
                  controller: emailController,
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

                TextFormField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible,
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
                        isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: colorScheme.onBackground.withOpacity(0.5),
                      ),
                      onPressed:
                          () =>
                              ref
                                  .read(isPasswordVisibleProvider.notifier)
                                  .state = !isPasswordVisible,
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

                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: !isConfirmPasswordVisible,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted:
                      (_) => ref
                          .read(registerControllerProvider.notifier)
                          .register(context),
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
                        isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: colorScheme.onBackground.withOpacity(0.5),
                      ),
                      onPressed:
                          () =>
                              ref
                                  .read(
                                    isConfirmPasswordVisibleProvider.notifier,
                                  )
                                  .state = !isConfirmPasswordVisible,
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
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Checkbox(
                      value: acceptTerms,
                      onChanged: (value) async {
                        if (value == true && !acceptTerms) {
                          await _showConsentDialog(context, ref);
                        } else if (value == false && acceptTerms) {
                          ref.read(acceptTermsProvider.notifier).state = false;
                        }
                      },
                      activeColor: kMainColour,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                                      settings: const RouteSettings(
                                        arguments: 0,
                                      ),
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
                                      settings: const RouteSettings(
                                        arguments: 1,
                                      ),
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

                if (message != null && message.message != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            message.isError
                                ? (isDark ? Colors.red[700] : Colors.red[100])
                                : (isDark
                                    ? Colors.green[700]
                                    : Colors.green[100]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            message.icon ??
                                (message.isError
                                    ? Icons.error_outline
                                    : Icons.check_circle_outline),
                            color:
                                message.isError
                                    ? (isDark
                                        ? Colors.red[100]
                                        : Colors.red[700])
                                    : (isDark
                                        ? Colors.green[100]
                                        : Colors.green[700]),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              message.message!,
                              style: TextStyle(
                                color:
                                    message.isError
                                        ? (isDark
                                            ? Colors.red[100]
                                            : Colors.red[900])
                                        : (isDark
                                            ? Colors.green[100]
                                            : Colors.green[900]),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                ElevatedButton(
                  onPressed:
                      (isLoading || !acceptTerms)
                          ? null
                          : () => ref
                              .read(registerControllerProvider.notifier)
                              .register(context),
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
                      isLoading
                          ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDark ? Colors.white : Colors.black,
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

    return ProviderScope(
      overrides: [_registerPageContextProvider.overrideWith((ref) => context)],
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: OrientationBuilder(
            builder: (context, orientation) {
              if (orientation == Orientation.portrait) {
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
                            data: MediaQuery.of(context).copyWith(
                              textScaler: const TextScaler.linear(1.0),
                            ),
                            child: content,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              } else {
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
      ),
    );
  }
}
