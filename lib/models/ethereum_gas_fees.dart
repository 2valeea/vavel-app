import 'package:eip1559/eip1559.dart' as eip1559;
import 'package:flutter/foundation.dart' show immutable;

/// One EIP-1559 fee suggestion (max fee + priority tip), in wei.
class GasFeeTier {
  const GasFeeTier({
    required this.maxFeePerGas,
    required this.maxPriorityFeePerGas,
  });

  final BigInt maxFeePerGas;
  final BigInt maxPriorityFeePerGas;

  factory GasFeeTier.fromEip1559Fee(eip1559.Fee f) => GasFeeTier(
        maxFeePerGas: f.maxFeePerGas,
        maxPriorityFeePerGas: f.maxPriorityFeePerGas,
      );

  GasFeeTier copyWith({
    BigInt? maxFeePerGas,
    BigInt? maxPriorityFeePerGas,
  }) =>
      GasFeeTier(
        maxFeePerGas: maxFeePerGas ?? this.maxFeePerGas,
        maxPriorityFeePerGas: maxPriorityFeePerGas ?? this.maxPriorityFeePerGas,
      );
}

/// Network fee quotes for UI speed buttons (slow / standard / fast).
class EthereumNetworkGasFees {
  const EthereumNetworkGasFees({
    required this.eip1559,
    this.slow,
    this.standard,
    this.fast,
    this.legacyGasPriceWei,
  });

  final bool eip1559;
  final GasFeeTier? slow;
  final GasFeeTier? standard;
  final GasFeeTier? fast;

  /// Legacy gas price (wei) when [eip1559] is false.
  final BigInt? legacyGasPriceWei;

  bool get hasTiers =>
      slow != null && standard != null && fast != null;

  static EthereumNetworkGasFees disabled() => const EthereumNetworkGasFees(
        eip1559: false,
        slow: null,
        standard: null,
        fast: null,
        legacyGasPriceWei: null,
      );
}

/// Key for [ethMaxTotalFeeProvider] (Riverpod family equality).
@immutable
class EthereumMaxFeeArgs {
  const EthereumMaxFeeArgs({
    required this.maxFeePerGas,
    required this.gasLimit,
  });

  final BigInt maxFeePerGas;
  final int gasLimit;

  @override
  bool operator ==(Object other) =>
      other is EthereumMaxFeeArgs &&
      other.maxFeePerGas == maxFeePerGas &&
      other.gasLimit == gasLimit;

  @override
  int get hashCode => Object.hash(maxFeePerGas, gasLimit);
}
