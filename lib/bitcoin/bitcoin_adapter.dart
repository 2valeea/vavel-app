import 'package:dio/dio.dart';
import '../models/asset.dart' show AssetBalance;

class BitcoinProvider {
  final Dio _dio;
  final String baseUrl;

  BitcoinProvider(
    this._dio, {
    this.baseUrl = 'https://blockstream.info/api',
  });

  /// Returns confirmed + unconfirmed balance in satoshis.
  Future<BigInt> getBalanceSats(String address) async {
    final resp =
        await _dio.get<Map<String, dynamic>>('$baseUrl/address/$address');
    final chain = resp.data!['chain_stats'] as Map<String, dynamic>;
    final mempool = resp.data!['mempool_stats'] as Map<String, dynamic>;

    final funded = (chain['funded_txo_sum'] as num).toInt() +
        (mempool['funded_txo_sum'] as num).toInt();
    final spent = (chain['spent_txo_sum'] as num).toInt() +
        (mempool['spent_txo_sum'] as num).toInt();
    return BigInt.from(funded - spent);
  }

  /// Returns confirmed + unconfirmed balance as an [AssetBalance].
  Future<AssetBalance> getBalance(String address) async {
    final sats = await getBalanceSats(address);
    return AssetBalance(assetId: 'btc', symbol: 'BTC', raw: sats, decimals: 8);
  }

  /// Fee estimates in sats/vB keyed by confirmation target (e.g. `{"1": 20, "2": 15}`).
  Future<Map<String, int>> getFeeRates() async {
    final resp = await _dio.get<Map<String, dynamic>>('$baseUrl/fee-estimates');
    return resp.data!.map((k, v) => MapEntry(k, (v as num).round()));
  }

  /// Rough fee for a typical single-input, two-output SegWit tx (141 vbytes).
  /// This is a *UI estimate*; real fee depends on the UTXO set.
  Future<BigInt> estimateFeeSats({int satsPerVb = 10}) async {
    const vbytes = 141;
    return BigInt.from(vbytes * satsPerVb);
  }

  /// Broadcasts a raw signed transaction and returns the txid.
  Future<String> broadcastTransaction(String rawHex) async {
    final response = await _dio.post<String>(
      '$baseUrl/tx',
      data: rawHex,
      options: Options(contentType: 'text/plain'),
    );
    return response.data!;
  }
}
