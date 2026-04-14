import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void showWcSuccessSnackBar(
  ScaffoldMessengerState messenger, {
  required String title,
  String? subtitle,
}) {
  HapticFeedback.lightImpact();
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      backgroundColor: const Color(0xFF1B5E20),
      duration: const Duration(seconds: 4),
      content: _WcSnackBody(
        icon: Icons.check_circle_outline,
        title: title,
        subtitle: subtitle,
      ),
    ),
  );
}

void showWcInfoSnackBar(
  ScaffoldMessengerState messenger, {
  required String title,
  String? subtitle,
}) {
  HapticFeedback.selectionClick();
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      backgroundColor: const Color(0xFF37474F),
      duration: const Duration(seconds: 3),
      content: _WcSnackBody(
        icon: Icons.info_outline,
        title: title,
        subtitle: subtitle,
      ),
    ),
  );
}

void showWcErrorSnackBar(
  ScaffoldMessengerState messenger, {
  required String title,
  String? subtitle,
}) {
  HapticFeedback.mediumImpact();
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      backgroundColor: const Color(0xFFB71C1C),
      duration: const Duration(seconds: 5),
      content: _WcSnackBody(
        icon: Icons.error_outline,
        title: title,
        subtitle: subtitle,
      ),
    ),
  );
}

class _WcSnackBody extends StatelessWidget {
  const _WcSnackBody({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
