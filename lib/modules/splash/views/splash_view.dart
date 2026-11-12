import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_haptics.dart';
import '../controllers/splash_controller.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  late final SplashController controller;

  // 1. Main entrance choreographer (1400ms)
  late final AnimationController _mainController;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _logoOpacityAnimation;
  late final Animation<double> _ringsScaleAnimation;
  late final Animation<double> _ringsOpacityAnimation;
  late final Animation<Offset> _titleSlideAnimation;
  late final Animation<double> _titleOpacityAnimation;
  late final Animation<double> _titleSpacingAnimation;
  late final Animation<Offset> _taglineSlideAnimation;
  late final Animation<double> _taglineOpacityAnimation;
  late final Animation<double> _loaderOpacityAnimation;

  // 2. Ambient breathing aura pulse controller (2000ms loop)
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScaleAnimation;
  late final Animation<double> _pulseAuraAnimation;

  // 3. Shimmer progress bar controller (1200ms loop)
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<SplashController>();

    // 1. Entrance choreography
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Spring overshoot logo entrance (Grab/Gojek physics)
    _logoScaleAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.05, 0.45, curve: Curves.easeIn),
      ),
    );

    // Expanding concentric rings
    _ringsScaleAnimation = Tween<double>(begin: 0.6, end: 1.45).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.9, curve: Curves.easeOutQuad),
      ),
    );

    _ringsOpacityAnimation = Tween<double>(begin: 0.0, end: 0.45).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeIn),
      ),
    );

    // Brand title slide + expanding letter-spacing
    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _titleOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeIn),
      ),
    );

    _titleSpacingAnimation = Tween<double>(begin: -0.5, end: 1.2).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    // Tagline slide & fade
    _taglineSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.45),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _taglineOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 0.85, curve: Curves.easeIn),
      ),
    );

    // Loader fade
    _loaderOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
      ),
    );

    // 2. Continuous breathing pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseScaleAnimation = Tween<double>(begin: 1.0, end: 1.045).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _pulseAuraAnimation = Tween<double>(begin: 0.28, end: 0.58).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    // 3. Shimmer capsule progress
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Trigger entrance with subtle haptic feedback
    _mainController.forward();
    AppHaptics.light();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        final isExiting = controller.isExiting.value;
        return AnimatedScale(
          scale: isExiting ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: isExiting ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.background,
                gradient: RadialGradient(
                  center: Alignment(0, -0.15),
                  radius: 1.25,
                  colors: [
                    Color(0xFF0F261C), // Deep emerald glow center
                    Color(0xFF0E1624), // Midnight slate
                    Color(0xFF080C14), // Deep obsidian border
                  ],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Ambient Background Breathing Aura
                  AnimatedBuilder(
                    animation: _pulseAuraAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: _pulseAuraAnimation.value),
                              AppColors.primaryLight.withValues(alpha: _pulseAuraAnimation.value * 0.4),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      );
                    },
                  ),

                  // 2. Expanding Concentric Glow Rings
                  ScaleTransition(
                    scale: _ringsScaleAnimation,
                    child: FadeTransition(
                      opacity: _ringsOpacityAnimation,
                      child: Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ScaleTransition(
                    scale: _ringsScaleAnimation,
                    child: FadeTransition(
                      opacity: _ringsOpacityAnimation,
                      child: Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryLight.withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 3. Centered Content (Logo, Brand Title, Tagline, Loader)
                  SafeArea(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 3),

                          // App Logo with Spring Entrance & Continuous Pulse
                          ScaleTransition(
                            scale: _logoScaleAnimation,
                            child: FadeTransition(
                              opacity: _logoOpacityAnimation,
                              child: AnimatedBuilder(
                                animation: _pulseScaleAnimation,
                                builder: (context, child) => Transform.scale(
                                  scale: _pulseScaleAnimation.value,
                                  child: child,
                                ),
                                child: Container(
                                  width: 98,
                                  height: 98,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(26),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.45),
                                        blurRadius: 36,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 10),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.55),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(26),
                                    child: Image.asset(
                                      'assets/icons/app_logo.png',
                                      width: 98,
                                      height: 98,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Brand Title with Staggered Entrance & Letter Spacing Expansion
                          SlideTransition(
                            position: _titleSlideAnimation,
                            child: FadeTransition(
                              opacity: _titleOpacityAnimation,
                              child: AnimatedBuilder(
                                animation: _titleSpacingAnimation,
                                builder: (context, child) => Text(
                                  AppConstants.appName,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: _titleSpacingAnimation.value,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Tagline with Slide & Fade in Capsule Badge
                          SlideTransition(
                            position: _taglineSlideAnimation,
                            child: FadeTransition(
                              opacity: _taglineOpacityAnimation,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant.withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  AppConstants.appTagline,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const Spacer(flex: 3),

                          // Modern Fluid Shimmer Capsule Loader
                          FadeTransition(
                            opacity: _loaderOpacityAnimation,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 120,
                                    height: 3.5,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: AnimatedBuilder(
                                        animation: _shimmerController,
                                        builder: (context, child) {
                                          return Align(
                                            alignment: Alignment(
                                              -1.2 + (_shimmerController.value * 2.4),
                                              0,
                                            ),
                                            child: Container(
                                              width: 48,
                                              height: 3.5,
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Colors.transparent,
                                                    AppColors.primaryLight,
                                                    AppColors.primary,
                                                    Colors.transparent,
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(4),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.primary.withValues(alpha: 0.8),
                                                    blurRadius: 8,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'SECURING VAULT & DATA...',
                                    style: TextStyle(
                                      color: AppColors.textMuted.withValues(alpha: 0.8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
