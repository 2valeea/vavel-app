import '../models/asset.dart';
import '../bitcoin/bitcoin_adapter.dart' show BitcoinProvider;
import '../ethereum/ethereum_adapter.dart' show EthereumProvider;

class PortfolioService {
  final BitcoinProvider btcProvider;
  final EthereumProvider ethProvider;

  PortfolioService({
    required this.btcProvider,
    required this.ethProvider,
  });

  /// Returns an [AssetBalance] for every asset in [kAssets] that can be
  /// queried from [btcAddress] or [ethAddress].
  ///
  /// SOL and TON assets are skipped here; their balances are handled
  /// by the respective chain adapters in [WalletService].
  Future<List<AssetBalance>> getBalances({
    required String btcAddress,
    required String ethAddress,
  }) async {
    final results = <AssetBalance>[];

    for (final asset in kAssets) {
      switch (asset.type) {
        case AssetType.btc:
          final sats = await btcProvider.getBalanceSats(btcAddress);
          results.add(AssetBalance(
            assetId: asset.id,
            symbol: asset.symbol,
            raw: sats,
            decimals: asset.decimals,
          ));

        case AssetType.eth:
          final wei = await ethProvider.getEthBalanceWei(ethAddress);
          results.add(AssetBalance(
            assetId: asset.id,
            symbol: asset.symbol,
            raw: wei,
            decimals: asset.decimals,
          ));

        case AssetType.erc20:
          if (asset.contract == null) break;
          final raw = await ethProvider.getErc20Balance(
            contract: asset.contract!,
            owner: ethAddress,
          );
          results.add(AssetBalance(
            assetId: asset.id,
            symbol: asset.symbol,
            raw: raw,
            decimals: asset.decimals,
          ));

        case AssetType.sol:
        case AssetType.token2022:
        case AssetType.ton:
          // Handled by SolanaAdapter / TonAdapter in WalletService.
          break;
      }
    }

    return results;
  }
}
