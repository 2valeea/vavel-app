import 'dart:async' show TimeoutException;
import 'dart:developer' show log;
import 'package:flutter/foundation.dart' show kDebugMode;

import '../bitcoin/bitcoin_adapter.dart' show BitcoinProvider;
import '../ethereum/ethereum_adapter.dart' show EthereumProvider;
import '../services/price_service.dart' show PriceProvider;
import '../http/safe_http_client.dart' show NonJsonRpcResponse;
import '../models/fee_estimate.dart';

class FeeService {
  final BitcoinProvider btc;
  final EthereumProvider eth;
  final PriceProvider prices;

  FeeService({required this.btc, required this.eth, required this.prices});

  /// Estimates the BTC network fee in USD for a typical SegWit transaction.
  ///
  /// Throws [FeeEstimationException] on any RPC or network failure.
  Future<FeeEstimate> estimateBitcoinFeeUsd() async {
    try {
      final rates = await btc.getFeeRates();
      final satsPerVb = rates['2'] ?? rates.values.first;
      final feeSats = await btc.estimateFeeSats(satsPerVb: satsPerVb);
      final btcUsd = await prices.getUsdPrice('BTC');
      final feeBtc = feeSats.toDouble() / 1e8;
      return FeeEstimate(
          network: 'bitcoin', nativeAmount: feeSats, usd: feeBtc * btcUsd);
    } on FeeEstimationException {
      rethrow;
    } catch (e) {
      throw FeeEstimationException(
        network: 'bitcoin',
        userMessage: _humanize(e, 'bitcoin'),
        cause: e,
      );
    }
  }

  /// Estimates the Ethereum network fee in USD for a transaction with
  /// [gasLimit] gas units.
  ///
  /// Throws [FeeEstimationException] on any RPC or network failure.
  Future<FeeEstimate> estimateEthereumFeeUsd({required int gasLimit}) async {
    try {
      final feeWei = await eth.estimateTxFeeWei(gasLimit: gasLimit);
      final ethUsd = await prices.getUsdPrice('ETH');
      final feeEth = feeWei.toDouble() / 1e18;
      return FeeEstimate(
          network: 'ethereum', nativeAmount: feeWei, usd: feeEth * ethUsd);
    } on FeeEstimationException {
      rethrow;
    } catch (e) {
      throw FeeEstimationException(
        network: 'ethereum',
        userMessage: _humanize(e, 'ethereum'),
        cause: e,
      );
    }
  }

  /// Converts a raw exception into a short, user-facing message.
  ///
  /// [network] names the chain (e.g. `'ethereum'`, `'bitcoin'`) so the message
  /// can point the developer to the right build-config variable.
  static String _humanize(Object e, String network) {
    if (e is NonJsonRpcResponse) {
      if (e.isAuthError) {
        // Covers HTTP 401/403 AND plain-text "Must be authenticated" (HTTP 200)
        // from endpoints like llamarpc that set Content-Type: application/json
        // but return a non-JSON auth error body.
        if (kDebugMode) {
          log(
            '[FeeService/$network] auth error — HTTP ${e.statusCode}: '
            '"${e.bodyStart.length > 60 ? e.bodyStart.substring(0, 60) : e.bodyStart}"',
            name: 'vavel_wallet',
          );
        }
        final hint = switch (network) {
          'ethereum' => '--dart-define=ETH_RPC_URL=https://...',
          'solana' => '--dart-define=SOLANA_RPC_PRIMARY=https://...',
          'ton' => '--dart-define=TONCENTER_API_KEY=YOUR_KEY',
          _ => 'an authenticated RPC endpoint',
        };
        return 'RPC requires authentication (HTTP ${e.statusCode}). '
            'Set $hint with a valid API key.';
      }
      if (e.isRateLimited) {
        if (kDebugMode) {
          log('[FeeService/$network] rate-limited (429)', name: 'vavel_wallet');
        }
        return 'RPC rate-limited (429). Try again later or switch to an authenticated endpoint.';
      }
      return 'RPC returned an unexpected response (${e.statusCode}).';
    }
    if (e is TimeoutException) return 'RPC timed out. Check your connection.';
    return 'Fee estimate unavailable. Try again later.';
  }
}
