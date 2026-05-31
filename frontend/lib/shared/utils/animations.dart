import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';

/// Comprehensive animation system for Fidel Guide
/// Provides unique page transitions and micro-interactions that match the navy blue theme
class AppAnimations {
  AppAnimations._();

  // ============================================
  // PAGE TRANSITIONS
  // ============================================

  /// Modern slide-in transition from right with fade
  static CustomTransitionPage<T> slideInFromRight<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        var offsetAnimation = animation.drive(tween);
        var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: curve),
        );

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Fade-in transition with scale effect
  static CustomTransitionPage<T> fadeInScale<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOutBack;

        var scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: curve),
        );

        var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: curve),
        );

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Bottom sheet slide-up transition
  static CustomTransitionPage<T> slideUpFromBottom<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  /// Smooth fade transition for modal-like screens
  static CustomTransitionPage<T> smoothFade<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOut;

        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: curve),
          child: child,
        );
      },
    );
  }

  /// No-op transition for instant screen changes
  static CustomTransitionPage<T> noTransition<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: Duration.zero,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
    );
  }

  /// Navy-blue themed transition with color sweep effect
  static CustomTransitionPage<T> navySweep<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.0),
                    AppColors.primary.withOpacity(animation.value * 0.3),
                    AppColors.primary.withOpacity(0.0),
                  ],
                  stops: [0.0, animation.value, 1.0],
                ),
              ),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: child,
        );
      },
    );
  }

  /// Rotation transition with scale effect
  static CustomTransitionPage<T> rotateIn<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOutBack;

        var rotationAnimation = Tween<double>(begin: 0.1, end: 0.0).animate(
          CurvedAnimation(parent: animation, curve: curve),
        );

        var scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: curve),
        );

        return RotationTransition(
          turns: rotationAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Bounce slide transition for playful interactions
  static CustomTransitionPage<T> bounceSlide<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.elasticOut;

        var tween = Tween(begin: const Offset(0.0, 0.3), end: Offset.zero).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  /// Expand from center transition
  static CustomTransitionPage<T> expandFromCenter<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOutCubic;

        var scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: curve),
        );

        return ScaleTransition(
          scale: scaleAnimation,
          alignment: Alignment.center,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  // ============================================
  // MICRO-INTERACTIONS
  // ============================================

  /// Creates a scale animation on tap
  static Widget tapScale({
    required Widget child,
    VoidCallback? onTap,
    double scaleDown = 0.95,
    Duration duration = const Duration(milliseconds: 100),
  }) {
    return _TapScale(
      onTap: onTap,
      scaleDown: scaleDown,
      duration: duration,
      child: child,
    );
  }

  /// Creates a fade-in animation for list items
  static Widget fadeInListItem({
    required Widget child,
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return _FadeInListItem(
      child: child,
      delay: delay,
      duration: duration,
    );
  }

  /// Creates a slide-in animation for list items
  static Widget slideInListItem({
    required Widget child,
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 300),
    Offset beginOffset = const Offset(0.3, 0),
  }) {
    return _SlideInListItem(
      child: child,
      delay: delay,
      duration: duration,
      beginOffset: beginOffset,
    );
  }

  /// Creates a shimmer loading effect
  static Widget shimmer({
    required Widget child,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return _ShimmerLoading(
      child: child,
      baseColor: baseColor ?? AppColors.surfaceVariant,
      highlightColor: highlightColor ?? AppColors.surfaceHighlight,
    );
  }

  /// Creates a pulse animation for attention-grabbing elements
  static Widget pulse({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    return _PulseAnimation(
      child: child,
      duration: duration,
      minScale: minScale,
      maxScale: maxScale,
    );
  }

  // ============================================
  // ANIMATED WIDGETS
  // ============================================

  /// Animated container with smooth color transitions
  static Widget animatedContainer({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    BoxDecoration? decoration,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? width,
    double? height,
  }) {
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      decoration: decoration,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      child: child,
    );
  }

  /// Animated opacity with configurable duration
  static Widget animatedOpacity({
    required Widget child,
    required bool show,
    Duration duration = const Duration(milliseconds: 200),
    Curve curve = Curves.easeInOut,
  }) {
    return AnimatedOpacity(
      opacity: show ? 1.0 : 0.0,
      duration: duration,
      curve: curve,
      child: child,
    );
  }

  /// Animated size with smooth transitions
  static Widget animatedSize({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    Alignment alignment = Alignment.topCenter,
  }) {
    return AnimatedSize(
      duration: duration,
      curve: curve,
      alignment: alignment,
      child: child,
    );
  }
}

// ============================================
// PRIVATE ANIMATION WIDGET IMPLEMENTATIONS
// ============================================

class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final Duration duration;

  const _TapScale({
    required this.child,
    this.onTap,
    this.scaleDown = 0.95,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

class _FadeInListItem extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const _FadeInListItem({
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<_FadeInListItem> createState() => _FadeInListItemState();
}

class _FadeInListItemState extends State<_FadeInListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: widget.child,
    );
  }
}

class _SlideInListItem extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;

  const _SlideInListItem({
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 300),
    this.beginOffset = const Offset(0.3, 0),
  });

  @override
  State<_SlideInListItem> createState() => _SlideInListItemState();
}

class _SlideInListItemState extends State<_SlideInListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _offset = Tween<Offset>(begin: widget.beginOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offset,
      child: FadeTransition(
        opacity: _controller,
        child: widget.child,
      ),
    );
  }
}

class _ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const _ShimmerLoading({
    required this.child,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  State<_ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<_ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: GradientRotation(_animation.value * 0.5),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const _PulseAnimation({
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.minScale = 0.95,
    this.maxScale = 1.05,
  });

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: widget.minScale, end: widget.maxScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: widget.child,
    );
  }
}