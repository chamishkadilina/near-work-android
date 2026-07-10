import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nearwork/core/constants/app_colors.dart';
import 'package:nearwork/features/auth/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const _termsUrl =
      'https://sites.google.com/view/nearwork-terms-of-use/home';
  static const _privacyUrl =
      'https://sites.google.com/view/nearwork-privacy-policy/home';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Staggered entrance: each element fades/slides in on its own slice
  // of the same controller, so nothing needs its own timer.
  late final Animation<double> _logo = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _title = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.15, 0.75, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _tagline = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.25, 0.85, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _button = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _terms = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Fades in + slides up 16px, driven by [animation].
  Widget _fadeSlideIn(Animation<double> animation, Widget child) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * 16),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _BrandBackground(size: size),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Top spacing
                  SizedBox(height: size.height * 0.16),

                  // Logo
                  _fadeSlideIn(
                    _logo,
                    Image.asset(
                      'assets/icons/nearwork_logo.png',
                      width: 156,
                      height: 156,
                    ),
                  ),

                  _fadeSlideIn(
                    _title,
                    const Text(
                      'NearWork',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  _fadeSlideIn(
                    _tagline,
                    const Text(
                      'Find Jobs Near You',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),

                  // Move Google button closer to center
                  SizedBox(height: size.height * 0.24),

                  _fadeSlideIn(
                    _button,
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        // Both states share the same width: double.infinity +
                        // Center wrapper, so swapping between them doesn't
                        // shift horizontal position.
                        return SizedBox(
                          width: double.infinity,
                          child: Center(
                            child: authProvider.isAuthenticating
                                ? const SizedBox(
                                    height: 48,
                                    width: 48,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 4,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: () =>
                                        authProvider.signInWithGoogle(),
                                    child: SvgPicture.asset(
                                      height: 48,
                                      'assets/icons/google_signin_button.svg',
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),

                  const Spacer(),

                  _fadeSlideIn(_terms, _TermsText(onLinkTap: _launchUrl)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsText extends StatelessWidget {
  final void Function(String url) onLinkTap;

  const _TermsText({required this.onLinkTap});

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(fontSize: 14, color: AppColors.textSecondary);

    const linkStyle = TextStyle(
      fontSize: 14,
      color: AppColors.primaryDark,
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          const Text('By continuing, you agree to our ', style: baseStyle),

          GestureDetector(
            onTap: () => onLinkTap(LoginScreen._termsUrl),
            child: const Text('Terms of Use', style: linkStyle),
          ),

          const Text(' and ', style: baseStyle),

          GestureDetector(
            onTap: () => onLinkTap(LoginScreen._privacyUrl),
            child: const Text('Privacy Policy', style: linkStyle),
          ),

          const Text('.', style: baseStyle),
        ],
      ),
    );
  }
}

class _BrandBackground extends StatelessWidget {
  final Size size;

  const _BrandBackground({required this.size});

  Widget _blob({
    required double top,
    double? left,
    double? right,
    required double diameter,
    required double opacity,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: opacity),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: Colors.white),

          _blob(
            top: -size.width * 0.4,
            left: -size.width * 0.3,
            diameter: size.width * 1.6,
            opacity: 0.10,
          ),

          _blob(
            top: -size.width * 0.15,
            right: -size.width * 0.35,
            diameter: size.width * 0.9,
            opacity: 0.14,
          ),
        ],
      ),
    );
  }
}
