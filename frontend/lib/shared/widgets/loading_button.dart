import 'package:flutter/material.dart';

/// Filled button with a spinner that appears while [loading] is true. Disables
/// the button automatically so callers don't need to remember to check both.
class LoadingButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;
  final Widget child;

  const LoadingButton({
    super.key,
    required this.loading,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : child,
    );
  }
}
