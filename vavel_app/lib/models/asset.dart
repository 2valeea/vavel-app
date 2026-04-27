enum AssetType { eth, erc20, sol, token2022, ton }

class Asset {
  final String id;
  final String name;
  final String symbol;
  final AssetType type;
  final int decimals;
  final String? solanaMint;
  final String? geckoId;

  const Asset({
    required this.id,
    required this.name,
    required this.symbol,
    required this.type,
    required this.decimals,
    this.solanaMint,
    this.geckoId,
  });
}

const kAssetVaval = Asset(
  id: 'vaval',
  name: 'Vaval',
  symbol: 'VAVAL',
  type: AssetType.erc20,
  decimals: 18,
  geckoId: null,
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

const kAssetTiktok = Asset(
  id: 'tiktok',
  name: 'tik-tok',
  symbol: 'tik-tok',
  type: AssetType.token2022,
  decimals: 6,
  solanaMint: '8GXhm9R1wYUgnWKUW3bEcUjAENz5EyLkBqQneuvapump',
  geckoId: null,
);

const kAssetTon = Asset(
  id: 'ton',
  name: 'TON',
  symbol: 'TON',
  type: AssetType.ton,
  decimals: 9,
  geckoId: 'toncoin',
);

const List<Asset> kAssets = [
  kAssetVaval,
  kAssetEth,
  kAssetSol,
  kAssetTiktok,
  kAssetTon,
];

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

  double toDecimal() {
    if (raw == BigInt.zero) return 0.0;
    final factor = BigInt.from(10).pow(decimals);
    final whole = raw ~/ factor;
    final remainder = raw % factor;
    return whole.toDouble() + remainder.toDouble() / factor.toDouble();
  }
}
