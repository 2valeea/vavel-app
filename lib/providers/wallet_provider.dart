import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/wallet_service.dart';
import '../services/wallet_service_factory.dart';
import '../secure_storage/keychain_store.dart';
import 'network_provider.dart' show networkProvider;

// ── Secure storage ────────────────────────────────────────────────────────

final seedStoreProvider = Provider<SeedStore>((ref) {
  return const SeedStore(
    FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
});

// ── Singleton service ─────────────────────────────────────────────────────

/// Rebuilds automatically when [networkProvider] changes, triggering a
/// fresh [balanceProvider] fetch against the new chain endpoints.
final walletServiceProvider = Provider<WalletService>((ref) {
  final network = ref.watch(networkProvider);
  return createWalletService(ref.read(seedStoreProvider), network: network);
});

// ── App state ─────────────────────────────────────────────────────────────

enum AppRoute { setup, pinAuth, home }

final appRouteProvider = StateNotifierProvider<AppRouteNotifier, AppRoute>(
  (ref) => AppRouteNotifier(ref.read(seedStoreProvider)),
);

class AppRouteNotifier extends StateNotifier<AppRoute> {
  final SeedStore _seedStore;

  AppRouteNotifier(this._seedStore) : super(AppRoute.setup) {
    _init();
  }

  Future<void> _init() async {
    final hasWallet = await _seedStore.hasMnemonic();
    state = hasWallet ? AppRoute.pinAuth : AppRoute.setup;
  }

  void goHome() => state = AppRoute.home;
  void goSetup() => state = AppRoute.setup;
  void lockWallet() => state = AppRoute.pinAuth;
}

// ── Wallet addresses ──────────────────────────────────────────────────────

final walletAddressesProvider = FutureProvider<WalletAddresses>((ref) async {
  final service = ref.watch(walletServiceProvider);
  return service.getAddresses();
});

// ── Mnemonic generation (temporary, for backup screen) ────────────────────

final pendingMnemonicProvider = StateProvider<String?>((ref) => null);
