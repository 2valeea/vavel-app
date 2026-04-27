import 'package:wallet/wallet.dart' show EthereumAddress;

import '../crypto/ethereum_keypair.dart';
import '../crypto/mnemonic.dart';
import '../crypto/solana_keypair.dart';
import '../crypto/ton_keypair.dart';
import '../ethereum/ethereum_adapter.dart';
import '../secure_storage/keychain_store.dart' show SeedStore;
import '../solana/solana_adapter.dart';
import '../ton/ton_adapter.dart';
import '../models/asset.dart' show AssetBalance, kAssetTiktok;
import '../utils/ens_utils.dart';

class WalletAddresses {
  final String solana;
  final String ton;
  final String ethereum;

  const WalletAddresses({
    required this.solana,
    required this.ton,
    required this.ethereum,
  });
}

class WalletBalances {
  final Map<String, AssetBalance> _balances;

  final Map<String, Object> errors;

  const WalletBalances(this._balances, {this.errors = const {}});

  AssetBalance? operator [](String id) => _balances[id];

  bool get hasErrors => errors.isNotEmpty;
}

/// User-selected gas for EVM sends (native ETH or ERC-20 VAVAL).
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

class WalletService {
  final SolanaAdapter _sol;
  final TonAdapter _ton;
  final EthereumProvider _eth;
  final SeedStore _seedStore;

  final int ethereumChainId;

  const WalletService({
    required SolanaAdapter sol,
    required TonAdapter ton,
    required EthereumProvider eth,
    required SeedStore seedStore,
    required this.ethereumChainId,
  })  : _sol = sol,
        _ton = ton,
        _eth = eth,
        _seedStore = seedStore;

  Future<String> createNewWallet([int words = 12]) async {
    assert(words == 12 || words == 24, 'words must be 12 or 24');
    final mnemonic = await generateMnemonic(words);
    await _seedStore.saveMnemonic(mnemonic);
    return mnemonic;
  }

  Future<void> importWallet(String mnemonic) async {
    if (!validateMnemonic(mnemonic)) {
      throw StateError('Invalid mnemonic');
    }
    await _seedStore.saveMnemonic(mnemonic);
  }

  Future<WalletAddresses> getAddresses() async {
    final mnemonic = await _requireMnemonic();
    final seed = mnemonicToSeed(mnemonic);
    final solKp = await solanaKeypairFromMnemonic(mnemonic);
    final tonKp = await tonKeypairFromMnemonic(mnemonic);
    final ethKp = ethereumKeypairFromSeed(seed);
    return WalletAddresses(
      solana: _sol.addressFromKeypair(solKp),
      ton: _ton.getAddress(publicKey: tonKp.publicKey),
      ethereum: ethKp.address,
    );
  }

  Future<WalletBalances> getBalances() async {
    final mnemonic = await _requireMnemonic();
    final seed = mnemonicToSeed(mnemonic);
    final solKp = await solanaKeypairFromMnemonic(mnemonic);
    final tonKp = await tonKeypairFromMnemonic(mnemonic);
    final ethKp = ethereumKeypairFromSeed(seed);

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
        chainErrors[id] = e;
        return zeroBalance(id, sym, dec);
      }
    }

    final results = await Future.wait<AssetBalance>([
      safe(() => _eth.getTokenBalance(ethKp.address), 'vaval', 'VAVAL', 18),
      safe(() => _eth.getBalance(ethKp.address), 'eth', 'ETH', 18),
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
    ]);

    return WalletBalances(
      {
        'vaval': results[0],
        'eth': results[1],
        'sol': results[2],
        'tiktok': results[3],
        'ton': results[4],
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
    var n = t.trim();
    if (n.startsWith('0x') || n.startsWith('0X')) {
      n = '0x${n.substring(2).toLowerCase()}';
    } else {
      n = '0x${n.toLowerCase()}';
    }
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

  Future<String> sendVaval(
    String to,
    double amount, {
    EthereumSendGasOptions? gas,
  }) async {
    final mnemonic = await _requireMnemonic();
    final ethKp = ethereumKeypairFromSeed(mnemonicToSeed(mnemonic));
    return _eth.sendToken(
      senderKey: ethKp.privateKey,
      toAddress: to,
      vavelAmount: amount,
      chainId: ethereumChainId,
      gasLimit: gas?.gasLimit,
      maxFeePerGas: gas?.maxFeePerGas,
      maxPriorityFeePerGas: gas?.maxPriorityFeePerGas,
      legacyGasPriceWei: gas?.legacyGasPriceWei,
    );
  }

  Future<String> _requireMnemonic() async {
    final mnemonic = await _seedStore.getMnemonic();
    if (mnemonic == null) throw StateError('No wallet found');
    return mnemonic;
  }
}
