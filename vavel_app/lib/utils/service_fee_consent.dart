import 'package:shared_preferences/shared_preferences.dart';

/// Bump suffix (e.g. v1 → v2) if the fee model or copy changes materially.
const String kServiceFeeConsentPrefsKey = 'vavel_service_fee_consent_v1';

Future<void> grantServiceFeeConsent() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kServiceFeeConsentPrefsKey, true);
}

Future<bool> isServiceFeeConsentGranted() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(kServiceFeeConsentPrefsKey) == true;
}

/// Clears stored consent so the fee dialog is shown again on next Send.
Future<void> clearServiceFeeConsent() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(kServiceFeeConsentPrefsKey);
}
