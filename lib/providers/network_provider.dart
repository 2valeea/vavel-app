import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/network.dart';

export '../models/network.dart';

const _kNetworkKey = 'app_network';
const _storage = FlutterSecureStorage();

/// Persisted active network — defaults to mainnet on first launch.
final networkProvider = StateNotifierProvider<NetworkNotifier, AppNetwork>(
    (ref) => NetworkNotifier());

class NetworkNotifier extends StateNotifier<AppNetwork> {
  NetworkNotifier() : super(AppNetwork.mainnet) {
    _load();
  }

  Future<void> _load() async {
    final saved = await _storage.read(key: _kNetworkKey);
    if (saved == AppNetwork.testnet.name) state = AppNetwork.testnet;
  }

  Future<void> setNetwork(AppNetwork network) async {
    state = network;
    await _storage.write(key: _kNetworkKey, value: network.name);
  }
}
