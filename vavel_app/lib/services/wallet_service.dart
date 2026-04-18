import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart' show StringUtils;
import 'package:eth_sig_util_plus/eth_sig_util_plus.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

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
import '../models/asset.dart' show AssetBalance, kAssetTiktok;
import '../models/asset_id.dart';
import '../utils/address_recipient_normalizer.dart';
import '../utils/ens_utils.dart';

/// User-selected gas for EVM sends (native ETH or ERC-20).
class EthereumSendGasOptions {
  const EthereumSendGasOptions({
    required this.gasLimit,
    this.maxFeePerGas,
    this.maxPriorityFeePerGas,
    this.legacyGasPriceWei,
  });

  final int gasLimit;
  final BigInt? maxFeePerGas;
  final BigInt? maxPriorityFeePerGas;
  final BigInt? legacyGasPriceWei;
}

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

  /// EIP-155 chain id used by this build (mainnet `1`, Sepolia `11155111`).
  final int ethereumChainId;

  /// Bitcoin network for address parsing and signing.
  final BitcoinNetwork bitcoinNetwork;

  const WalletService({
    required SolanaAdapter sol,
    required TonAdapter ton,
    required EthereumProvider eth,
    required BitcoinProvider btc,
    required SeedStore seedStore,
    required this.ethereumChainId,
    required this.bitcoinNetwork,
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
      safe(
        () => _sol.getToken2022Balance(
          _sol.addressFromKeypair(solKp),
          kAssetTiktok.solanaMint!,
          assetId: 'tiktok',
          symbol: kAssetTiktok.symbol,
          defaultDecimals: kAssetTiktok.decimals,
        ),
        'tiktok',
        'tik-tok',
        6,
      ),
      safe(() => _ton.getBalance(_ton.getAddress(publicKey: tonKp.publicKey)),
          'ton', 'TON', 9),
      safe(() => _eth.getBalance(ethKp.address), 'eth', 'ETH', 18),
      safe(() => _eth.getTokenBalance(ethKp.address), 'vavel', 'VAVEL', 18),
      safe(() => _btc.getBalance(btcKp.address), 'btc', 'BTC', 8),
    ]);

    return WalletBalances(
      {
        'sol': results[0],
        'tiktok': results[1],
        'ton': results[2],
        'eth': results[3],
        'vavel': results[4],
        'btc': results[5],
      },
      errors: chainErrors,
    );
  }

  bool _isValidEvmHexAddress(String s) {
    var h = s.trim();
    if (h.startsWith('0x') || h.startsWith('0X')) h = h.substring(2);
    return h.length == 40 && RegExp(r'^[0-9a-fA-F]{40}$').hasMatch(h);
  }

  /// Resolves `*.eth` via mainnet ENS, or validates and returns a normalized `0x` address.
  Future<String> resolveEthereumRecipient(String raw) async {
    final t = raw.trim();
    if (t.isEmpty) {
      throw StateError('Recipient is empty');
    }
    if (looksLikeEnsName(t)) {
      if (_eth.isDisabled) {
        throw StateError('Ethereum is disabled; cannot resolve ENS names.');
      }
      final name = normalizeEnsNameForResolution(t);
      if (name == null) {
        throw StateError('Invalid ENS name');
      }
      final resolved = await _eth.resolveEnsName(name);
      if (resolved == null || resolved.isEmpty) {
        throw StateError(
          'Could not resolve this ENS name. Check spelling and try again.',
        );
      }
      try {
        return EthereumAddress.fromHex(resolved).with0x;
      } catch (_) {
        throw StateError('ENS resolved to an invalid address');
      }
    }
    final n = normalizeRecipientAddress(AssetId.eth, t);
    if (!_isValidEvmHexAddress(n)) {
      throw StateError('Invalid Ethereum address');
    }
    return EthereumAddress.fromHex(n).with0x;
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

  Future<String> sendEthereum(
    String to,
    double ethAmount, {
    EthereumSendGasOptions? gas,
  }) async {
    final mnemonic = await _requireMnemonic();
    final ethKp = ethereumKeypairFromSeed(mnemonicToSeed(mnemonic));
    return _eth.sendEth(
      senderKey: ethKp.privateKey,
      toAddress: to,
      ethAmount: ethAmount,
      chainId: ethereumChainId,
      gasLimit: gas?.gasLimit,
      maxFeePerGas: gas?.maxFeePerGas,
      maxPriorityFeePerGas: gas?.maxPriorityFeePerGas,
      legacyGasPriceWei: gas?.legacyGasPriceWei,
    );
  }

  Future<String> sendVavel(
    String to,
    double vavelAmount, {
    EthereumSendGasOptions? gas,
  }) async {
    final mnemonic = await _requireMnemonic();
    final ethKp = ethereumKeypairFromSeed(mnemonicToSeed(mnemonic));
    return _eth.sendToken(
      senderKey: ethKp.privateKey,
      toAddress: to,
      vavelAmount: vavelAmount,
      chainId: ethereumChainId,
      gasLimit: gas?.gasLimit,
      maxFeePerGas: gas?.maxFeePerGas,
      maxPriorityFeePerGas: gas?.maxPriorityFeePerGas,
      legacyGasPriceWei: gas?.legacyGasPriceWei,
    );
  }

  /// Reads ERC-20 [decimals] from chain RPC. Returns `null` if disabled or the call fails.
  Future<int?> getErc20Decimals(String contractAddress) async {
    if (_eth.isDisabled) return null;
    return _eth.getErc20Decimals(contractAddress);
  }

  /// Signs EIP-712 typed data for WalletConnect `eth_signTypedData_v4`.
  Future<String> signWalletConnectTypedDataV4(String jsonData) async {
    if (_eth.isDisabled) {
      throw StateError('Ethereum is disabled (DISABLE_ETH=true).');
    }
    final mnemonic = await _requireMnemonic();
    final ethKp = ethereumKeypairFromSeed(mnemonicToSeed(mnemonic));
    return EthSigUtil.signTypedData(
      privateKeyInBytes: ethKp.privateKey.privateKey,
      jsonData: jsonData,
      version: TypedDataVersion.V4,
    );
  }

  /// Signs arbitrary bytes for WalletConnect `personal_sign` (EIP-191 personal message).
  Future<String> signWalletConnectPersonalMessage(List<int> payload) async {
    if (_eth.isDisabled) {
      throw StateError('Ethereum is disabled (DISABLE_ETH=true).');
    }
    final mnemonic = await _requireMnemonic();
    final ethKp = ethereumKeypairFromSeed(mnemonicToSeed(mnemonic));
    final sig = ethKp.privateKey.signPersonalMessageToUint8List(
      Uint8List.fromList(payload),
    );
    return bytesToHex(sig, include0x: true);
  }

  /// Broadcasts an `eth_sendTransaction` map from WalletConnect.
  Future<String> sendWalletConnectEthereumTransaction({
    required int chainId,
    required Map<String, dynamic> tx,
  }) async {
    if (_eth.isDisabled) {
      throw StateError('Ethereum is disabled (DISABLE_ETH=true).');
    }
    if (chainId != ethereumChainId) {
      throw StateError(
        'This wallet is on chain ID $ethereumChainId, but the dApp requested $chainId.',
      );
    }
    final mnemonic = await _requireMnemonic();
    final ethKp = ethereumKeypairFromSeed(mnemonicToSeed(mnemonic));
    return _eth.sendWalletConnectTransaction(
      credentials: ethKp.privateKey,
      chainId: chainId,
      tx: tx,
    );
  }

  /// Sends legacy P2PKH BTC using Blockstream UTXOs and `bitcoin_base` signing.
  Future<String> sendBitcoin(String to, double btcAmount) async {
    if (btcAmount <= 0) {
      throw StateError('Invalid BTC amount');
    }
    final sendSats = BigInt.from((btcAmount * 100000000).round());
    if (sendSats <= BigInt.zero) {
      throw StateError('Amount too small after conversion to satoshis');
    }

    final mnemonic = await _requireMnemonic();
    final seed = mnemonicToSeed(mnemonic);
    final btcKp = bitcoinKeypairFromSeed(seed);
    final ecPriv = ECPrivate.fromBytes(Uint8List.fromList(btcKp.privateKey));
    final pub = ecPriv.getPublic();
    final pubkeyHex = pub.toHex();
    final fromAddr = btcKp.address;

    final toWrapped = BitcoinAddress(to.trim(), network: bitcoinNetwork);
    final toBase = toWrapped.baseAddress;

    final changeBase =
        BitcoinAddress(fromAddr, network: bitcoinNetwork).baseAddress;

    var utxos = await _btc.fetchP2pkhUtxos(
      legacyAddress: fromAddr,
      publicKeyHex: pubkeyHex,
      network: bitcoinNetwork,
    );
    if (utxos.isEmpty) {
      throw StateError('No spendable UTXOs for this address');
    }
    utxos.sort((a, b) => b.utxo.value.compareTo(a.utxo.value));

    final rates = await _btc.getFeeRates();
    final satsPerVb = rates['6'] ?? rates['3'] ?? rates['1'] ?? 10;

    const dust = 546;

    BigInt sumUtxo(List<UtxoWithAddress> u) =>
        u.fold(BigInt.zero, (a, x) => a + x.utxo.value);

    Future<List<UtxoWithAddress>> gather(BigInt minSum) async {
      final out = <UtxoWithAddress>[];
      var sum = BigInt.zero;
      for (final u in utxos) {
        out.add(u);
        sum += u.utxo.value;
        if (sum >= minSum) return out;
      }
      throw StateError(
        'Insufficient BTC balance for this payment and network fee.',
      );
    }

    BigInt feeForVb(List<UtxoWithAddress> inputs, List<BitcoinOutput> outs) {
      final v = BitcoinTransactionBuilder.estimateTransactionSize(
        utxos: inputs,
        outputs: outs,
        network: bitcoinNetwork,
        enableRBF: true,
      );
      return BigInt.from(v * satsPerVb);
    }

    var inputs = await gather(sendSats + BigInt.from(2000));

    final feeTwoOut = feeForVb(
      inputs,
      [
        BitcoinOutput(address: toBase, value: sendSats),
        BitcoinOutput(address: changeBase, value: BigInt.from(dust)),
      ],
    );

    while (sumUtxo(inputs) < sendSats + feeTwoOut) {
      inputs = await gather(sendSats + feeTwoOut);
    }

    var sumIn = sumUtxo(inputs);
    var change = sumIn - sendSats - feeTwoOut;

    final List<BitcoinBaseOutput> outputs;
    final BigInt fee;
    if (change > BigInt.zero && change < BigInt.from(dust)) {
      outputs = [BitcoinOutput(address: toBase, value: sendSats)];
      fee = sumIn - sendSats;
    } else if (change >= BigInt.from(dust)) {
      fee = feeTwoOut;
      outputs = [
        BitcoinOutput(address: toBase, value: sendSats),
        BitcoinOutput(address: changeBase, value: change),
      ];
    } else {
      fee = feeTwoOut;
      outputs = [BitcoinOutput(address: toBase, value: sendSats)];
      if (sumIn < sendSats + fee) {
        throw StateError(
          'Insufficient BTC balance for this payment and network fee.',
        );
      }
    }

    final builder = BitcoinTransactionBuilder(
      utxos: inputs,
      outPuts: outputs,
      fee: fee,
      network: bitcoinNetwork,
      enableRBF: true,
    );

    final tx = builder.buildTransaction((trDigest, utxo, publicKey, sighash) {
      if (utxo.utxo.isP2tr) {
        return ecPriv.signBip340(trDigest, sighash: sighash);
      }
      return ecPriv.signECDSA(trDigest, sighash: sighash);
    });

    final rawHex = StringUtils.strip0x(tx.serialize());
    return _btc.broadcastTransaction(rawHex);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<String> _requireMnemonic() async {
    final mnemonic = await _seedStore.getMnemonic();
    if (mnemonic == null) throw StateError('No wallet found');
    return mnemonic;
  }
}
