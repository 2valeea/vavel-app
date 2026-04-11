/// Thrown when `WC_PROJECT_ID` is missing or fails basic format checks.
class WalletConnectProjectIdMissing implements Exception {
  const WalletConnectProjectIdMissing();

  static const String dialogTitle = 'WalletConnect is not configured';

  static const String dialogBody =
      'This screen needs a Reown (WalletConnect Cloud) project ID.\n\n'
      '1. Create a free project at https://dashboard.reown.com/\n'
      '2. Copy the Project ID\n'
      '3. Run or build the app with:\n\n'
      '   flutter run --dart-define=WC_PROJECT_ID=YOUR_PROJECT_ID\n\n'
      'Without this, pairing and dApp connections cannot start.';

  @override
  String toString() => 'WalletConnectProjectIdMissing';
}

/// Thrown when [ReownWalletKit.createInstance] fails (invalid ID, network, relay, etc.).
class WalletConnectInitializationFailed implements Exception {
  WalletConnectInitializationFailed(this.cause);

  final Object cause;

  static const String dialogTitle = 'WalletConnect could not start';

  static String dialogBodyFor(Object cause) =>
      'The WalletConnect SDK rejected initialization or could not reach the relay. '
      'Double-check that your WC_PROJECT_ID is correct and active in the Reown dashboard, '
      'and that the device has network access.\n\n'
      'Technical detail:\n$cause';

  @override
  String toString() => 'WalletConnectInitializationFailed: $cause';
}
