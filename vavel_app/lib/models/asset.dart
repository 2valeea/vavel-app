export 'fee_estimate.dart';

enum AssetType { btc, eth, erc20, sol, ton }

class Asset {
  final String id; // e.g. "btc", "eth", "vavel"
  final String name; // "Bitcoin"
  final String symbol; // "BTC"
  final AssetType type;
  final int decimals; // BTC=8, ETH=18, ERC20 varies, SOL=9, TON=9
  final String? contract; // ERC20 contract address only
  final String? geckoId; // CoinGecko price ID

  const Asset({
    required this.id,
    required this.name,
    required this.symbol,
    required this.type,
    required this.decimals,
    this.contract,
    this.geckoId,
  });
}

/// Named asset constants — use these for identity comparisons.
const kAssetVavel = Asset(
  id: 'vavel',
  name: 'VAVEL',
  symbol: 'VAVEL',
  type: AssetType.erc20,
  decimals: 18,
  contract: '0x12345...', // replace with real contract address before release
  geckoId: null, // not on CoinGecko yet
);

const kAssetBtc = Asset(
  id: 'btc',
  name: 'Bitcoin',
  symbol: 'BTC',
  type: AssetType.btc,
  decimals: 8,
  geckoId: 'bitcoin',
);

const kAssetEth = Asset(
  id: 'eth',
  name: 'Ethereum',
  symbol: 'ETH',
  type: AssetType.eth,
  decimals: 18,
  geckoId: 'ethereum',
);

const kAssetSol = Asset(
  id: 'sol',
  name: 'Solana',
  symbol: 'SOL',
  type: AssetType.sol,
  decimals: 9,
  geckoId: 'solana',
);

const kAssetTon = Asset(
  id: 'ton',
  name: 'TON',
  symbol: 'TON',
  type: AssetType.ton,
  decimals: 9,
  geckoId: 'toncoin',
);

/// Canonical ordered list of supported assets. VAVEL is first as the primary token.
const List<Asset> kAssets = [
  kAssetVavel,
  kAssetBtc,
  kAssetEth,
  kAssetSol,
  kAssetTon
];

/// Unified balance type for any asset.
///
/// [raw] holds the integer amount in the asset's smallest unit
/// (satoshis, wei, lamports, nanotons, or ERC-20 token units).
/// Call [toDecimal] to convert to a human-readable [double].
class AssetBalance {
  final String assetId;
  final String symbol;
  final BigInt raw;
  final int decimals;

  const AssetBalance({
    required this.assetId,
    required this.symbol,
    required this.raw,
    required this.decimals,
  });

  /// Converts [raw] to a decimal value using [decimals].
  ///
  /// Example: raw=1500000000, decimals=9 → 1.5
  double toDecimal() {
    if (raw == BigInt.zero) return 0.0;
    final factor = BigInt.from(10).pow(decimals);
    final whole = raw ~/ factor;
    final remainder = raw % factor;
    return whole.toDouble() + remainder.toDouble() / factor.toDouble();
  }
}
