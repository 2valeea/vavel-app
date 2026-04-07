import '../crypto/mnemonic.dart';
import '../crypto/solana_keypair.dart';
import '../crypto/ton_keypair.dart';
import '../crypto/ethereum_keypair.dart';
import '../crypto/bitcoin_keypair.dart';
import '../secure_storage/keychain_store.dart' show SeedStore;
import '../solana/solana_adapter.dart';
import '../ton/ton_adapter.dart';
import '../ethereum/ethereum_adapter.dart' show EthereumProvider;
import '../bitcoin/bitcoin_adapter.dart' show BitcoinProvider;
import '../models/asset.dart' show AssetBalance;

class WalletAddresses {
  final String solana;
  final String ton;
  final String ethereum;
  final String bitcoin;

  const WalletAddresses({
    required this.solana,
    required this.ton,
    required this.ethereum,
    required this.bitcoin,
  });
}

class WalletBalances {
  final Map<String, AssetBalance> _balances;

  /// Per-chain fetch errors keyed by asset id (e.g. `'sol'`, `'btc'`).
  /// Empty when all chains fetched successfully.
  final Map<String, Object> errors;

  const WalletBalances(this._balances, {this.errors = const {}});

  /// Returns the [AssetBalance] for the given asset [id] (e.g. 'btc', 'eth').
  AssetBalance? operator [](String id) => _balances[id];

  /// Whether any chain returned a fetch error.
  bool get hasErrors => errors.isNotEmpty;
}

class WalletService {
  final SolanaAdapter _sol;
  final TonAdapter _ton;
  final EthereumProvider _eth;
  final BitcoinProvider _btc;
  final SeedStore _seedStore;

  const WalletService({
    required SolanaAdapter sol,
    required TonAdapter ton,
    required EthereumProvider eth,
    required BitcoinProvider btc,
    required SeedStore seedStore,
  })  : _sol = sol,
        _ton = ton,
        _eth = eth,
        _btc = btc,
        _seedStore = seedStore;

  // ── Wallet lifecycle ──────────────────────────────────────────────────────

  /// Generates a new BIP39 mnemonic, saves it to secure storage, and returns it.
  ///
  /// [words] must be 12 or 24.
  Future<String> createNewWallet([int words = 12]) async {
    assert(words == 12 || words == 24, 'words must be 12 or 24');
    final mnemonic = await generateMnemonic(words);
    await _seedStore.saveMnemonic(mnemonic);
    return mnemonic;
  }

  /// Validates [mnemonic] and, if valid, saves it to secure storage.
  ///
  /// Throws [StateError] if the mnemonic is invalid.
  Future<void> importWallet(String mnemonic) async {
    if (!validateMnemonic(mnemonic)) {
      throw StateError('Invalid mnemonic');
    }
    await _seedStore.saveMnemonic(mnemonic);
  }

  // ── Addresses ─────────────────────────────────────────────────────────────

  Future<WalletAddresses> getAddresses() async {
    final mnemonic = await _requireMnemonic();
    final seed = mnemonicToSeed(mnemonic);
    final solKp = await solanaKeypairFromMnemonic(mnemonic);
    final tonKp = await tonKeypairFromMnemonic(mnemonic);
    final ethKp = ethereumKeypairFromSeed(seed);
    final btcKp = bitcoinKeypairFromSeed(seed);
    return WalletAddresses(
      solana: _sol.addressFromKeypair(solKp),
      ton: _ton.getAddress(publicKey: tonKp.publicKey),
      ethereum: ethKp.address,
      bitcoin: btcKp.address,
    );
  }

  // ── Balances ──────────────────────────────────────────────────────────────

  /// Fetches balances for all chains concurrently.
  ///
  /// Individual chain failures return a zero [AssetBalance] so the home screen
  /// always loads — a per-asset zero will be shown when a network call fails.
  Future<WalletBalances> getBalances() async {
    final mnemonic = await _requireMnemonic();
    final seed = mnemonicToSeed(mnemonic);
    final solKp = await solanaKeypairFromMnemonic(mnemonic);
    final tonKp = await tonKeypairFromMnemonic(mnemonic);
    final ethKp = ethereumKeypairFromSeed(seed);
    final btcKp = bitcoinKeypairFromSeed(seed);

    // Explicit try-catch is used here instead of Future.catchError because
    // it is more predictable with Dart's async/await and type system.
    AssetBalance zeroBalance(String id, String sym, int dec) => AssetBalance(
          assetId: id,
          symbol: sym,
          raw: BigInt.zero,
          decimals: dec,
        );

    final chainErrors = <String, Object>{};

    Future<AssetBalance> safe(
      Future<AssetBalance> Function() fetch,
      String id,
      String sym,
      int dec,
    ) async {
      try {
        return await fetch();
      } catch (e) {
        chainErrors[id] = e; // record which chain failed and why
        return zeroBalance(id, sym, dec);
      }
    }

    final results = await Future.wait<AssetBalance>([
      safe(() => _sol.getBalance(_sol.addressFromKeypair(solKp)), 'sol', 'SOL',
          9),
      safe(() => _ton.getBalance(_ton.getAddress(publicKey: tonKp.publicKey)),
          'ton', 'TON', 9),
      safe(() => _eth.getBalance(ethKp.address), 'eth', 'ETH', 18),
      safe(() => _eth.getTokenBalance(ethKp.address), 'vavel', 'VAVEL', 18),
      safe(() => _btc.getBalance(btcKp.address), 'btc', 'BTC', 8),
    ]);

    return WalletBalances(
      {
        'sol': results[0],
        'ton': results[1],
        'eth': results[2],
        'vavel': results[3],
        'btc': results[4],
      },
      errors: chainErrors,
    );
  }

  Future<String> sendSolana(String toBase58, double solAmount) async {
    final mnemonic = await _requireMnemonic();
    final solKp = await solanaKeypairFromMnemonic(mnemonic);
    return _sol.sendSol(from: solKp, toBase58: toBase58, sol: solAmount);
  }

  Future<void> sendTon(String to, String tonAmount) async {
    final mnemonic = await _requireMnemonic();
    final tonKp = await tonKeypairFromMnemonic(mnemonic);
    await _ton.sendTon(
      publicKey: tonKp.publicKey,
      secretKey: tonKp.privateKey,
      to: to,
      ton: tonAmount,
    );
  }

  Future<String> sendEthereum(String to, double ethAmount) async {
    final mnemonic = await _requireMnemonic();
    final ethKp = ethereumKeypairFromSeed(mnemonicToSeed(mnemonic));
    return _eth.sendEth(
      senderKey: ethKp.privateKey,
      toAddress: to,
      ethAmount: ethAmount,
    );
  }

  Future<String> sendVavel(String to, double vavelAmount) async {
    final mnemonic = await _requireMnemonic();
    final ethKp = ethereumKeypairFromSeed(mnemonicToSeed(mnemonic));
    return _eth.sendToken(
      senderKey: ethKp.privateKey,
      toAddress: to,
      vavelAmount: vavelAmount,
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<String> _requireMnemonic() async {
    final mnemonic = await _seedStore.getMnemonic();
    if (mnemonic == null) throw StateError('No wallet found');
    return mnemonic;
  }
}
