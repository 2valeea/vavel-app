import 'package:flutter/material.dart';

import '../security/secure_window.dart';

/// Turns on secure window flags while this widget is mounted (ref-counted).
class SensitiveScreenGuard extends StatefulWidget {
  const SensitiveScreenGuard({super.key, required this.child});

  final Widget child;

  @override
  State<SensitiveScreenGuard> createState() => _SensitiveScreenGuardState();
}

class _SensitiveScreenGuardState extends State<SensitiveScreenGuard> {
  @override
  void initState() {
    super.initState();
    SecureWindow.pushSecure();
  }

  @override
  void dispose() {
    SecureWindow.popSecure();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
