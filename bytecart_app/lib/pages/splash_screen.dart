// Splash Screen: introduces the brand (logo, headline, hero with reflection) and a swipe-to-start CTA.
// Portrait scales from a baseline width; landscape uses a two-column layout. Status bar adapts to theme.
// If a session exists, the user is redirected to Home immediately.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../theme/theme_colours.dart';
import 'home.dart';
import 'login.dart';

// Root splash screen widget with session check and responsive layout.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Session check: after first frame, redirect to Home if already authenticated.
  @override
  void initState() {
    super.initState();
    // If already authenticated, skip splash and go straight to Home.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final loggedIn = await ApiService.isLoggedIn();
      if (!mounted) return;
      if (loggedIn) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Status bar: adapt icon brightness to theme and keep a transparent background.
    final overlay = ((Theme.of(context).brightness == Brightness.dark)
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark)
        .copyWith(statusBarColor: Colors.transparent);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        // Responsive layout: landscape = two-column; portrait = vertically stacked with scaling.
        body: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.landscape) {
              final mq = MediaQuery.of(context);
              return MediaQuery(
                // Clamp text scale in landscape to avoid overflow in tight areas.
                data: mq.copyWith(
                  textScaleFactor:
                      (mq.textScaleFactor.clamp(1.0, 1.3)).toDouble(),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: const _LandscapeLayout(),
                  ),
                ),
              );
            }
            // Portrait baseline scaling for consistent proportions across devices.
            final mq = MediaQuery.of(context);
            const baseWidth = 411.0;
            final scale = (mq.size.width / baseWidth);
            double s(double v) => v * scale;

            return MediaQuery(
              // Freeze text scale in portrait for a consistent look.
              data: mq.copyWith(textScaleFactor: 1.0),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(s(24.0)),
                  child: Column(
                    children: [
                      _HeaderSection(logoHeight: s(30)),
                      SizedBox(height: s(40)),
                      _HeroSection(fontSize: s(50)),
                      SizedBox(height: s(32)),
                      Expanded(child: _ImageSection(scale: scale)),
                      _BottomSection(scale: scale),
                    ],
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

// App logo (top-left).
class _HeaderSection extends StatelessWidget {
  const _HeaderSection({this.logoHeight = 30});

  final double logoHeight;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Image(
        image: const AssetImage('assets/images/logo.webp'),
        height: logoHeight,
      ),
    );
  }
}

// Marketing headline (font size configurable).
class _HeroSection extends StatelessWidget {
  const _HeroSection({this.fontSize = 50});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Shop Smart.\nShop ByteCart.',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onBackground,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
          height: 1.1,
        ),
      ),
    );
  }
}

// Product hero image with mirrored reflection; scales in portrait, responsive in landscape.
class _ImageSection extends StatelessWidget {
  const _ImageSection({this.scale});

  final double? scale;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    if (scale != null && !isLandscape) {
      // Portrait: scale from baseline values.
      final s = (double v) => v * scale!;
      final double mainHeight = s(420.0);
      final double reflectHeight = s(340.0);
      final double rightOffset = s(-25.0);
      final double bottomOffset = s(-48.0);
      final double leftOffset = s(-36.0);

      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topRight,
        children: [
          Positioned(
            top: 0,
            right: rightOffset,
            child: Transform.rotate(
              angle: -0.25,
              child: Image.asset(
                'assets/images/splash_img_1.webp',
                height: mainHeight,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            bottom: bottomOffset,
            left: leftOffset,
            child: Transform.rotate(
              angle: -0.25,
              child: Transform.scale(
                scaleY: -1,
                child: Opacity(
                  opacity: 0.35,
                  child: ShaderMask(
                    shaderCallback:
                        (rect) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white, Colors.transparent],
                          stops: [0.0, 0.95],
                        ).createShader(rect),
                    blendMode: BlendMode.dstIn,
                    child: Image.asset(
                      'assets/images/splash_img_2.webp',
                      height: reflectHeight,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Landscape/default: responsive sizes and offsets.
    final double mainHeight =
        isLandscape ? (size.height * 0.85).clamp(180.0, 500.0) : 420.0;
    final double reflectHeight =
        isLandscape ? (size.height * 0.70).clamp(140.0, 420.0) : 340.0;
    final double rightOffset = isLandscape ? -8.0 : -25.0;
    final double bottomOffset = isLandscape ? -24.0 : -48.0;
    final double leftOffset = isLandscape ? -16.0 : -36.0;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topRight,
      children: [
        Positioned(
          top: 0,
          right: rightOffset,
          child: Transform.rotate(
            angle: -0.25,
            child: Image.asset(
              'assets/images/splash_img_1.webp',
              height: mainHeight,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Positioned(
          bottom: bottomOffset,
          left: leftOffset,
          child: Transform.rotate(
            angle: -0.25,
            child: Transform.scale(
              scaleY: -1,
              child: Opacity(
                opacity: 0.35,
                child: ShaderMask(
                  shaderCallback:
                      (rect) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white, Colors.transparent],
                        stops: [0.0, 0.95],
                      ).createShader(rect),
                  blendMode: BlendMode.dstIn,
                  child: Image.asset(
                    'assets/images/splash_img_2.webp',
                    height: reflectHeight,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Tagline and the swipe-to-start call-to-action.
class _BottomSection extends StatelessWidget {
  const _BottomSection({this.scale = 1.0});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final onBg = Theme.of(context).colorScheme.onBackground;
    double s(double v) => v * scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Discover, Compare, and Buy the Best Electronics and\nAccessories at Unbeatable Prices.',
          style: TextStyle(
            color: onBg.withOpacity(0.7),
            fontSize: s(14),
            height: 1.4,
          ),
          textAlign: TextAlign.left,
        ),
        SizedBox(height: s(32)),
        _SwipeSlider(scale: scale),
        SizedBox(height: s(8)),
      ],
    );
  }
}

// Interactive slider: swipe to navigate to LoginPage; animates thumb and progress fill.
class _SwipeSlider extends StatefulWidget {
  const _SwipeSlider({this.scale = 1.0});

  final double scale;

  @override
  State<_SwipeSlider> createState() => _SwipeSliderState();
}

class _SwipeSliderState extends State<_SwipeSlider>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  VoidCallback? _controllerListener;

  double _dragX = 0.0;
  double _trackWidth = 0.0;

  double get _thumbSize => 56.0 * widget.scale;

  double get _sliderHeight => 64.0 * widget.scale;

  double get _maxDrag => (_trackWidth - _thumbSize).clamp(0.0, double.infinity);

  double get _percent =>
      _maxDrag == 0 ? 0 : (_dragX / _maxDrag).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    if (_controllerListener != null) {
      _controller.removeListener(_controllerListener!);
    }
    _controller.dispose();
    super.dispose();
  }

  // Animate the thumb to a target position using an ease-out curve.
  void _animateTo(double target) {
    _controller.stop();
    if (_controllerListener != null) {
      _controller.removeListener(_controllerListener!);
    }
    final start = _dragX;
    final dist = target - start;

    _controllerListener = () {
      final t = Curves.easeOutCubic.transform(_controller.value);
      setState(() => _dragX = start + dist * t);
    };

    _controller
      ..addListener(_controllerListener!)
      ..forward(from: 0);
  }

  // Navigate when threshold reached; otherwise snap back.
  void _onRelease() {
    const threshold = 0.65;
    if (_percent >= threshold) {
      _animateTo(_maxDrag);
      Future.delayed(const Duration(milliseconds: 320), () {
        if (!mounted) return;
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const LoginPage())).then((_) {
          if (!mounted) return;
          setState(() {
            _dragX = 0.0; // reset to start when coming back
          });
        });
      });
    } else {
      _animateTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onBg = theme.colorScheme.onBackground;

    return LayoutBuilder(
      builder: (context, constraints) {
        _trackWidth = (constraints.maxWidth - (8.0 * widget.scale)).clamp(
          0.0,
          double.infinity,
        );
        _dragX = _dragX.clamp(0.0, _maxDrag);

        return GestureDetector(
          onPanStart: (_) => _controller.stop(),
          onPanUpdate: (details) {
            setState(() {
              _dragX = (_dragX + details.delta.dx).clamp(0.0, _maxDrag);
            });
          },
          onPanEnd: (_) => _onRelease(),
          child: Container(
            height: _sliderHeight,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.circular(_sliderHeight / 2),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                FractionallySizedBox(
                  widthFactor: _percent,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kMainColour, Color(0xFF2A8CFF)],
                      ),
                      borderRadius: BorderRadius.circular(_sliderHeight / 2),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'Swipe to get started',
                    style: TextStyle(
                      color:
                          _percent > 0.35
                              ? Colors.white
                              : onBg.withOpacity(0.7),
                      fontWeight: FontWeight.w700,
                      fontSize: 16.0 * widget.scale,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Positioned(
                  left: _dragX + (4.0 * widget.scale),
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      color: kMainColour,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kMainColour.withOpacity(0.45),
                          blurRadius: 18 * widget.scale,
                          spreadRadius: 1 * widget.scale,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Landscape layout: left column (scrollable content), right column (product image).
class _LandscapeLayout extends StatelessWidget {
  const _LandscapeLayout();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Responsive headline size for landscape.
    final double heroFont = (size.width * 0.045).clamp(32.0, 46.0).toDouble();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left column: scrollable content (logo, headline, CTA).
        Expanded(
          flex: 6,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _HeaderSection(),
                          const SizedBox(height: 16),
                          _HeroSection(fontSize: heroFont),
                        ],
                      ),
                      const _BottomSection(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 24),
        // Right column: product image with reflection.
        Expanded(flex: 5, child: _ImageSection()),
      ],
    );
  }
}
