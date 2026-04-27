/// Thrown when USD fee estimation fails for Ethereum gas preview.
class FeeEstimationException implements Exception {
  FeeEstimationException(this.userMessage);
  final String userMessage;
}

/// Estimated network fee for a pending transaction (EVM).
class FeeEstimate {
  final BigInt nativeAmount;
  final double usd;

  const FeeEstimate({
    required this.nativeAmount,
    required this.usd,
  });
}
