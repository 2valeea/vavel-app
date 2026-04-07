/// Supported blockchain networks.
enum AppNetwork {
  /// Live network — uses authenticated RPC endpoints from `--dart-define`.
  mainnet,

  /// Test network — uses free public testnet endpoints, no real funds.
  ///
  /// • Solana  : Devnet   (api.devnet.solana.com)
  /// • Ethereum: Sepolia  (rpc.sepolia.org)
  /// • TON     : Testnet  (testnet.toncenter.com)
  /// • Bitcoin : Testnet3 (blockstream.info/testnet/api)
  testnet,
}
