import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Custom badge/tag component to replace Material Chips
/// Designed with the navy blue color scheme and modern styling
class AppBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool outlined;
  final EdgeInsetsGeometry? padding;
  final bool small;

  const AppBadge({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.backgroundColor,
    this.onTap,
    this.outlined = false,
    this.padding,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    final effectiveBgColor = backgroundColor ?? effectiveColor.withOpacity(0.1);
    final effectivePadding = padding ?? (small 
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 6));

    Widget badge = Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: outlined ? null : effectiveBgColor,
        border: Border.all(
          color: outlined ? effectiveColor : effectiveColor.withOpacity(0.3),
          width: outlined ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(small ? 6 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: small ? 12 : 14, color: effectiveColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: effectiveColor,
              fontSize: small ? 11 : 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(small ? 6 : 8),
          child: badge,
        ),
      );
    }

    return badge;
  }
}

/// Custom filled button with navy blue theme styling
class AppButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool outlined;
  final bool isLoading;
  final bool fullWidth;
  final double? height;
  final double? borderRadius;

  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.outlined = false,
    this.isLoading = false,
    this.fullWidth = false,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBgColor = backgroundColor ?? 
        (outlined ? null : AppColors.primary);
    final effectiveFgColor = foregroundColor ?? 
        (outlined ? AppColors.primary : AppColors.textInverse);
    final effectiveHeight = height ?? 52.0;
    final effectiveBorderRadius = borderRadius ?? 16.0;

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        child: Container(
          height: effectiveHeight,
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: outlined 
                ? null 
                : LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: outlined ? null : effectiveBgColor,
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            border: outlined
                ? Border.all(color: effectiveBgColor!, width: 2)
                : null,
            boxShadow: onPressed != null && !isLoading
                ? [
                    BoxShadow(
                      color: effectiveBgColor!.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(effectiveFgColor!),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: effectiveFgColor),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          color: effectiveFgColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );

    return button;
  }
}

/// Custom text input field with navy blue theme styling
class AppTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? errorText;
  final bool enabled;
  final VoidCallback? onTap;
  final Function(String)? onChanged;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.errorText,
    this.enabled = true,
    this.onTap,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: errorText != null 
                  ? AppColors.error 
                  : (enabled ? AppColors.outline : AppColors.outlineVariant),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                child: Row(
                  children: [
                    if (prefixIcon != null) ...[
                      Icon(
                        prefixIcon,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: TextField(
                        controller: controller,
                        obscureText: obscureText,
                        keyboardType: keyboardType,
                        maxLines: maxLines,
                        enabled: enabled,
                        onChanged: onChanged,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: hint,
                          hintStyle: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (suffixIcon != null) ...[
                      const SizedBox(width: 8),
                      suffixIcon!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: TextStyle(
              color: AppColors.error,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// Custom loading indicator with navy blue theme
class AppLoadingIndicator extends StatelessWidget {
  final double? size;
  final Color? color;
  final String? message;

  const AppLoadingIndicator({
    super.key,
    this.size,
    this.color,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    final effectiveSize = size ?? 24.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: effectiveSize,
          height: effectiveSize,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// Custom loading skeleton for cards and lists
class AppSkeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const AppSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height ?? 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: _ShimmerAnimation(),
    );
  }
}

class _ShimmerAnimation extends StatefulWidget {
  @override
  State<_ShimmerAnimation> createState() => _ShimmerAnimationState();
}

class _ShimmerAnimationState extends State<_ShimmerAnimation>
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
                AppColors.surfaceVariant,
                AppColors.surfaceHighlight,
                AppColors.surfaceVariant,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: GradientRotation(_animation.value * 0.5),
            ).createShader(bounds);
          },
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

/// Custom choice chip for selection
class AppChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final IconData? icon;
  final Color? selectedColor;

  const AppChoiceChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.icon,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = selectedColor ?? AppColors.accent;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelected?.call(!selected),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? effectiveColor : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? effectiveColor : AppColors.outline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: selected ? AppColors.textInverse : AppColors.textSecondary),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.textInverse : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom filter chip with close button
class AppFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onSelected;
  final VoidCallback? onClear;
  final IconData? icon;

  const AppFilterChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.onClear,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.outline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: selected ? AppColors.primary : AppColors.textSecondary),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (selected && onClear != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onClear,
                  child: Icon(Icons.close, size: 14, color: AppColors.primary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}