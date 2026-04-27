import 'package:flutter/material.dart';

/// Root [Navigator] key for SnackBars outside the widget that triggered an action (e.g. Stripe deep links).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
