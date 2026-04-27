import 'package:shared_preferences/shared_preferences.dart';

/// Local flag after a successful Stripe PaymentSheet for full wallet access.
abstract final class StripeUnlockStore {
  static const _prefsKey = 'stripe_wallet_unlocked_v1';

  static Future<bool> isUnlocked() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_prefsKey) == true;
  }

  static Future<void> setUnlocked() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_prefsKey, true);
  }
}
