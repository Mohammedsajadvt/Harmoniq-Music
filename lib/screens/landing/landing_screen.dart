import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/animated_gradient_text.dart';
import '../../widgets/creator_profile_sheet.dart';
import '../../widgets/glass_card.dart';
import '../main_navigation_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgFloatController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _bgFloatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgFloatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _getStarted() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainNavigationScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Dynamic Animated Floating Album Art Backgrounds
          AnimatedBuilder(
            animation: _bgFloatController,
            builder: (context, child) {
              final double t = _bgFloatController.value;
              return Stack(
                children: [
                  // Album 1 (Top Right float)
                  Positioned(
                    top: -60 + (t * 40),
                    right: -50 - (t * 30),
                    child: Transform.rotate(
                      angle: 0.25 - (t * 0.1),
                      child: Container(
                        width: size.width * 0.75,
                        height: size.width * 0.75,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/album1.jpg'),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.35),
                              blurRadius: 40,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Album 2 (Middle Left float)
                  Positioned(
                    top: size.height * 0.28 - (t * 35),
                    left: -80 + (t * 30),
                    child: Transform.rotate(
                      angle: -0.3 + (t * 0.12),
                      child: Container(
                        width: size.width * 0.65,
                        height: size.width * 0.65,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/album2.jpg'),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withOpacity(0.35),
                              blurRadius: 40,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 2. Glowing Ambient Orbs
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final double scale = 0.85 + (_pulseController.value * 0.3);
              return Positioned(
                bottom: 120,
                right: -50,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.accent.withOpacity(0.25),
                          AppColors.primary.withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // 3. Dark Frosted Blur Layer for readability & aesthetic depth
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.background.withOpacity(0.4),
                      AppColors.background.withOpacity(0.85),
                      AppColors.background,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.5, 0.85],
                  ),
                ),
              ),
            ),
          ),

          // 4. Foreground Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 1),

                  // App Logo with glowing ring
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.5),
                              blurRadius: 40,
                              spreadRadius: 6,
                            ),
                            BoxShadow(
                              color: AppColors.secondary.withOpacity(0.4),
                              blurRadius: 60,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      ClipOval(
                        child: Image.asset(
                          'assets/images/app_logo.jpg',
                          width: 125,
                          height: 125,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .scale(duration: 800.ms, curve: Curves.easeOutBack)
                      .fadeIn(),

                  const SizedBox(height: 24),

                  // App Name Title
                  const AnimatedGradientText(
                    text: 'HARMONIQ',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 200.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),

                  const SizedBox(height: 8),

                  const Text(
                    'Powered by Spotify Web API',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1DB954),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 350.ms),

                  const Spacer(flex: 2),

                  // Feature Glass Card
                  GlassCard(
                    borderRadius: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    child: Column(
                      children: [
                        _buildFeatureRow(
                          icon: Icons.graphic_eq_rounded,
                          title: 'High-Fidelity Streaming',
                          subtitle: 'Lossless indie tracks & curated playlists',
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(color: Colors.white10, height: 1),
                        ),
                        _buildFeatureRow(
                          icon: Icons.favorite_border_rounded,
                          title: 'Offline Favorites',
                          subtitle: 'Persistent local storage for quick access',
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(color: Colors.white10, height: 1),
                        ),
                        _buildFeatureRow(
                          icon: Icons.explore_rounded,
                          title: 'Zero Auth Required',
                          subtitle: 'Jump straight into unlimited music freedom',
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 450.ms)
                      .slideY(begin: 0.15, end: 0, curve: Curves.easeOutQuad),

                  const Spacer(flex: 2),

                  // "Get Started" Animated Neon Button
                  GestureDetector(
                    onTap: _getStarted,
                    child: Container(
                      width: double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: AppColors.neonGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.5),
                            blurRadius: 24,
                            spreadRadius: 2,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Start Listening Now',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white24,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Creator Branding Badge (Interactive & Fully Responsive)
                  GestureDetector(
                    onTap: () => CreatorProfileSheet.show(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.secondary.withOpacity(0.4), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded, size: 14, color: AppColors.secondary),
                              SizedBox(width: 5),
                              Text(
                                'Mohammed Sajad VT',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '@mohammed.sajad.vt',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 700.ms),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.secondary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
