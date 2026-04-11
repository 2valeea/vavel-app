import 'package:flutter/material.dart';

/// Fade + subtle horizontal slide for stack pushes (wallet-style motion).
class PremiumPageRoute<T> extends PageRouteBuilder<T> {
  PremiumPageRoute({
    required Widget child,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: const Duration(milliseconds: 340),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.035, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

Future<T?> pushPremium<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(PremiumPageRoute<T>(child: page));
}

Future<T?> pushReplacementPremium<T>(BuildContext context, Widget page) {
  return Navigator.of(context)
      .pushReplacement<T, void>(PremiumPageRoute<T>(child: page));
}
