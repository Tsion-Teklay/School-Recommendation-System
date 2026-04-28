import 'package:flutter/material.dart';

/// Breakpoints we use everywhere. Mirrors Material 3 window-size classes.
class Breakpoints {
  static const double compact = 600;
  static const double medium = 1200;
}

/// Wraps a screen body in a Scaffold whose chrome adapts to the viewport:
///   < 600px wide  → AppBar + body (mobile portrait).
///   600–1200px    → AppBar + body, body padded to a max width (tablet).
///   > 1200px      → AppBar + centered body capped at 1100px (desktop).
///
/// Bottom nav / side nav comes in Phase 9 once we have multiple top-level
/// destinations (browse, dashboard, forum). For Phase 7 the auth screens are
/// standalone forms so a single content column is enough.
class ResponsiveShell extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? leading;

  const ResponsiveShell({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions, leading: leading),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth >= Breakpoints.medium
              ? 1100.0
              : (constraints.maxWidth >= Breakpoints.compact
                  ? constraints.maxWidth - 48
                  : double.infinity);
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}
