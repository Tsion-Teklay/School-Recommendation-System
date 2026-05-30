import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../core/design_system.dart';
import '../../core/typography.dart';
import 'custom_components.dart';

/// Custom bottom navigation bar with navy blue theme and unique styling
/// Replaces standard Material NavigationBar with branded design
class AppBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final List<NavigationItem> items;
  final Function(int) onDestinationSelected;

  const AppBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = index == selectedIndex;

          return _NavigationItem(
            item: item,
            isSelected: isSelected,
            onTap: () => onDestinationSelected(index),
          );
        }).toList(),
      ),
    );
  }
}

/// Custom navigation rail with navy blue theme and unique styling
/// Replaces standard Material NavigationRail with branded design
class AppNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final List<NavigationItem> items;
  final Function(int) onDestinationSelected;
  final bool extended;
  final double? width;

  const AppNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onDestinationSelected,
    this.extended = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? (extended ? 240 : 80),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(
            color: AppColors.textTertiary.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: [
          // Header with logo
          if (extended) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Image.asset('assets/logo.png', height: 24),
                  SpacingHelper.sm,
                  Text(
                    'School Rec',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Image.asset('assets/logo.png', height: 32),
            ),
          const SizedBox(height: 16),
          // Navigation items
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = index == selectedIndex;

            return _RailNavigationItem(
              item: item,
              isSelected: isSelected,
              extended: extended,
              onTap: () => onDestinationSelected(index),
            );
          }),
        ],
      ),
    );
  }
}

/// Custom navigation item for bottom navigation
class _NavigationItem extends StatelessWidget {
  final NavigationItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.primary.withOpacity(0.1),
          highlightColor: AppColors.primary.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.icon,
                    size: 20,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 20,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom navigation item for rail navigation
class _RailNavigationItem extends StatelessWidget {
  final NavigationItem item;
  final bool isSelected;
  final bool extended;
  final VoidCallback onTap;

  const _RailNavigationItem({
    required this.item,
    required this.isSelected,
    required this.extended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Material(
        color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          splashColor: AppColors.primary.withOpacity(0.1),
          highlightColor: AppColors.primary.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  size: 24,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                if (extended) ...[
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    item.label,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Navigation item data model
class NavigationItem {
  final String label;
  final IconData icon;
  final String? badge;
  final bool showBadge;

  const NavigationItem({
    required this.label,
    required this.icon,
    this.badge,
    this.showBadge = false,
  });
}

/// Navigation ripple effect with navy blue theme
class NavigationRipple extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const NavigationRipple({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: AppColors.primary.withOpacity(0.2),
        highlightColor: AppColors.primary.withOpacity(0.1),
        child: child,
      ),
    );
  }
}

/// Animated navigation indicator with unique effects
class NavigationIndicator extends StatefulWidget {
  final bool isSelected;
  final Duration animationDuration;

  const NavigationIndicator({
    super.key,
    required this.isSelected,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<NavigationIndicator> createState() => _NavigationIndicatorState();
}

class _NavigationIndicatorState extends State<NavigationIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    if (widget.isSelected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(NavigationIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 4,
        height: 20,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

/// Smart navigation suggestions based on context and user behavior
class SmartNavigationSuggestions extends StatelessWidget {
  final String currentPath;
  final List<NavigationSuggestion> suggestions;
  final Function(String) onSuggestionTap;

  const SmartNavigationSuggestions({
    super.key,
    required this.currentPath,
    required this.suggestions,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.primary,
                size: AppSizing.iconSm,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Suggested for you',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: suggestions.map((suggestion) {
              return _SuggestionChip(
                suggestion: suggestion,
                onTap: () => onSuggestionTap(suggestion.path),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final NavigationSuggestion suggestion;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.suggestion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRipple(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppBorderRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              suggestion.icon,
              size: AppSizing.iconSm,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              suggestion.label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Navigation suggestion data model
class NavigationSuggestion {
  final String label;
  final IconData icon;
  final String path;
  final String? reason;

  const NavigationSuggestion({
    required this.label,
    required this.icon,
    required this.path,
    this.reason,
  });
}

/// Quick action navigation pattern for frequently used actions
class QuickActionsBar extends StatelessWidget {
  final List<QuickAction> actions;
  final bool isHorizontal;

  const QuickActionsBar({
    super.key,
    required this.actions,
    this.isHorizontal = true,
  });

  @override
  Widget build(BuildContext context) {
    final layout = isHorizontal
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: actions.map((action) => _QuickActionButton(action: action)).toList(),
          )
        : Column(
            children: actions.map((action) => _QuickActionButton(action: action)).toList(),
          );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: layout,
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final QuickAction action;

  const _QuickActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return NavigationRipple(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(AppBorderRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Icon(
                action.icon,
                color: action.color,
                size: AppSizing.iconMd,
              ),
            ),
            if (action.label != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                action.label!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Quick action data model
class QuickAction {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final Color color;

  const QuickAction({
    required this.icon,
    this.label,
    required this.onTap,
    required this.color,
  });
}

/// Custom floating navigation button with unique styling
class AppFloatingNavigation extends StatelessWidget {
  final List<NavigationItem> items;
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final Widget? child;

  const AppFloatingNavigation({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child ?? const SizedBox.shrink(),
        Positioned(
          bottom: 20,
          right: 20,
          child: _FloatingNavMenu(
            items: items,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
          ),
        ),
      ],
    );
  }
}

class _FloatingNavMenu extends StatefulWidget {
  final List<NavigationItem> items;
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const _FloatingNavMenu({
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  State<_FloatingNavMenu> createState() => _FloatingNavMenuState();
}

class _FloatingNavMenuState extends State<_FloatingNavMenu>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppDuration.medium,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.75).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Main FAB
        Material(
          color: Colors.transparent,
          child: InkResponse(
            onTap: _toggle,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 28,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        // Expanded menu items
        AnimatedSize(
          duration: AppDuration.medium,
          curve: Curves.easeInOut,
          alignment: Alignment.topRight,
          child: _isExpanded
              ? ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final isSelected = index == widget.selectedIndex;

                        return _FloatingNavItem(
                          item: item,
                          isSelected: isSelected,
                          onTap: () {
                            widget.onDestinationSelected(index);
                            _toggle();
                          },
                        );
                      }).toList(),
                    ),
                  ),
              )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _FloatingNavItem extends StatelessWidget {
  final NavigationItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _FloatingNavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                item.label,
                style: AppTypography.bodyMedium.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom navigation bar with unique styling for top-level navigation
class AppNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showLogo;
  final bool transparent;

  const AppNavigationBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showLogo = true,
    this.transparent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: transparent ? Colors.transparent : AppColors.surface,
        border: transparent
            ? null
            : Border(
                bottom: BorderSide(
                  color: AppColors.textTertiary.withOpacity(0.2),
                  width: 1,
                ),
              ),
        boxShadow: transparent
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              if (leading != null) leading!,
              if (showLogo) ...[
                Image.asset('assets/logo.png', height: 32),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Custom navigation breadcrumbs for hierarchical navigation
class AppBreadcrumbs extends StatelessWidget {
  final List<BreadcrumbItem> items;
  final Function(BreadcrumbItem)? onTap;

  const AppBreadcrumbs({
    super.key,
    required this.items,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isLast || onTap == null
                      ? null
                      : () => onTap!(item),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 16,
                        color: isLast
                            ? AppColors.textSecondary
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.label,
                        style: AppTypography.labelSmall.copyWith(
                          color: isLast
                              ? AppColors.textSecondary
                              : AppColors.primary,
                          fontWeight: isLast ? FontWeight.normal : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class BreadcrumbItem {
  final String label;
  final IconData icon;
  final String? route;

  const BreadcrumbItem({
    required this.label,
    required this.icon,
    this.route,
  });
}

/// Custom navigation tabs with unique styling
class AppNavigationTabs extends StatelessWidget {
  final int selectedIndex;
  final List<NavigationItem> items;
  final Function(int) onDestinationSelected;

  const AppNavigationTabs({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.textTertiary.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = index == selectedIndex;

            return _TabItem(
              item: item,
              isSelected: isSelected,
              onTap: () => onDestinationSelected(index),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final NavigationItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 24,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom navigation drawer with unique styling
class AppNavigationDrawer extends StatelessWidget {
  final List<NavigationItem> items;
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final Widget? header;
  final Widget? footer;

  const AppNavigationDrawer({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.header,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          if (header != null)
            header!
          else
            _DefaultDrawerHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = index == selectedIndex;

                return _DrawerItem(
                  item: item,
                  isSelected: isSelected,
                  onTap: () {
                    onDestinationSelected(index);
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
          if (footer != null) footer!,
        ],
      ),
    );
  }
}

class _DefaultDrawerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/logo.png', height: 40),
              const SizedBox(width: AppSpacing.md),
              Text(
                'School Rec',
                style: AppTypography.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SpacingHelper.lg,
          Text(
            'Find the perfect school',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final NavigationItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
      child: ListTile(
        leading: Icon(
          item.icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(
          item.label,
          style: AppTypography.bodyMedium.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isSelected
            ? Container(
                width: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}