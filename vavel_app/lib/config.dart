// Compile-time configuration injected via `--dart-define`.
//
// Never commit production secrets to source control.
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class RpcConfig {
  // ── Solana ────────────────────────────────────────────────────────────────

  static String get solanaRpcPrimary {
    const fromDefine = String.fromEnvironment(
      'SOLANA_RPC_PRIMARY',
      defaultValue: '',
    );
    if (fromDefine.isNotEmpty) return fromDefine;

    final heliusApiKey = dotenv.env['HELIUS_API_KEY']?.trim() ?? '';
    if (heliusApiKey.isNotEmpty) {
      return 'https://mainnet.helius-rpc.com/?api-key=$heliusApiKey';
    }
    return 'https://api.mainnet-beta.solana.com';
  }

  static const solanaRpcBackup = String.fromEnvironment('SOLANA_RPC_BACKUP');

  static const _solanaFallbackRaw =
      String.fromEnvironment('SOLANA_RPC_FALLBACK_URLS');

  static List<String> get solanaFallbackUrls {
    const publicFallback = 'https://api.mainnet-beta.solana.com';
    final seen = <String>{solanaRpcPrimary};
    final result = <String>[];

    if (solanaRpcBackup.isNotEmpty && seen.add(solanaRpcBackup)) {
      result.add(solanaRpcBackup);
    }
    for (final url in _solanaFallbackRaw.split(',').map((s) => s.trim())) {
      if (url.isNotEmpty && seen.add(url)) result.add(url);
    }
    if (seen.add(publicFallback)) result.add(publicFallback);
    return result;
  }

  // ── TON ───────────────────────────────────────────────────────────────────

  static const tonRpcUrl = String.fromEnvironment(
    'TONCENTER_RPC_URL',
    defaultValue: 'https://toncenter.com/api/v2/jsonRPC',
  );

  static const tonApiKey = String.fromEnvironment('TONCENTER_API_KEY');

  // ── Ethereum (ETH + VAVAL ERC-20) ───────────────────────────────────────

  static const ethRpcUrl = String.fromEnvironment(
    'ETH_RPC_URL',
    defaultValue: 'https://eth.llamarpc.com',
  );

  static const _ethFallbackRaw = String.fromEnvironment('ETH_FALLBACK_URLS');

  static List<String> get ethRpcUrls {
    final extras = _ethFallbackRaw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s != ethRpcUrl)
        .toList();
    return [ethRpcUrl, ...extras];
  }

  static bool get ethIsPublicFallback =>
      ethRpcUrl == 'https://eth.llamarpc.com';

  static const disableEth =
      bool.fromEnvironment('DISABLE_ETH', defaultValue: false);

  /// Mainnet ERC-20 contract for VAVAL (also accepts legacy `VAVEL_TOKEN_CONTRACT`).
  static const _vavalTokenContract =
      String.fromEnvironment('VAVAL_TOKEN_CONTRACT', defaultValue: '');
  static const _vavelTokenContractLegacy =
      String.fromEnvironment('VAVEL_TOKEN_CONTRACT', defaultValue: '');

  static String get vavalTokenContract {
    final a = _vavalTokenContract.trim();
    if (a.isNotEmpty) return a;
    return _vavelTokenContractLegacy.trim();
  }

  static bool get vavalTokenConfigured {
    final a = vavalTokenContract;
    return a.startsWith('0x') && a.length == 42;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static bool isValidHttpsUrl(String url) =>
      url.isNotEmpty && Uri.tryParse(url)?.scheme == 'https';

  static bool get solanaIsPublicFallback =>
      solanaRpcPrimary == 'https://api.mainnet-beta.solana.com';

  // ── Push (FCM / Huawei token → your backend) ───────────────────────────

  /// Body: `{ "walletAddress": "<primary chain id>", "token": "…", "platform": "android|ios", "pushProvider": "fcm" | "hms" }`
  static const pushRegisterUrl =
      String.fromEnvironment('PUSH_REGISTER_URL', defaultValue: '');

  static const pushRegisterBearer =
      String.fromEnvironment('PUSH_REGISTER_BEARER', defaultValue: '');
}
