/// Thrown by [FeeService] when fee estimation fails for any reason.
///
/// Always carries a [userMessage] suitable for display in the UI.
/// The original error is preserved in [cause] for logging.
class FeeEstimationException implements Exception {
  /// Chain that failed, e.g. `'ethereum'` or `'bitcoin'`.
  final String network;

  /// Human-readable message safe to show directly in the UI.
  final String userMessage;

  /// Original exception, preserved for logging/crash reporting.
  final Object? cause;

  const FeeEstimationException({
    required this.network,
    required this.userMessage,
    this.cause,
  });

  @override
  String toString() => 'FeeEstimationException($network): $userMessage';
}

/// Estimated network fee for a pending transaction.
///
/// [nativeAmount] is expressed in the chain's smallest unit:
///   • Bitcoin  → satoshis
///   • Ethereum → wei
///
/// [usd] is the pre-converted USD value of [nativeAmount].
class FeeEstimate {
  final String network; // "bitcoin" | "ethereum"
  final BigInt nativeAmount; // sats or wei
  final double usd; // already converted

  const FeeEstimate({
    required this.network,
    required this.nativeAmount,
    required this.usd,
  });
}
