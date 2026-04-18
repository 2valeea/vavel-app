import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/network.dart';

export '../models/network.dart';

const _kNetworkKey = 'app_network';
const _storage = FlutterSecureStorage();

/// Persisted active network — **mainnet only** (real BTC / TON / ETH).
/// Legacy testnet preference is migrated away on load.
final networkProvider = StateNotifierProvider<NetworkNotifier, AppNetwork>(
    (ref) => NetworkNotifier());

class NetworkNotifier extends StateNotifier<AppNetwork> {
  NetworkNotifier() : super(AppNetwork.mainnet) {
    _load();
  }

  Future<void> _load() async {
    final saved = await _storage.read(key: _kNetworkKey);
    if (saved == AppNetwork.testnet.name) {
      await _storage.write(key: _kNetworkKey, value: AppNetwork.mainnet.name);
    }
    state = AppNetwork.mainnet;
  }

  /// Testnet is disabled in the app UI; only mainnet is persisted.
  Future<void> setNetwork(AppNetwork network) async {
    final next =
        network == AppNetwork.testnet ? AppNetwork.mainnet : network;
    state = next;
    await _storage.write(key: _kNetworkKey, value: next.name);
  }
}
