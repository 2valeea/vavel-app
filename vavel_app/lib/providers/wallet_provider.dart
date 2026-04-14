import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
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

enum AppRoute { setup, pinAuth, home, dappConnect }

/// After unlock with the **panic (duress) PIN**: decoy portfolio, no send/swap/WC/receive addrs.
final duressModeProvider = StateProvider<bool>((ref) => false);

final duressPinConfiguredProvider = FutureProvider<bool>(
  (ref) => AuthService.hasDuressPin(),
);

final appRouteProvider = StateNotifierProvider<AppRouteNotifier, AppRoute>(
  (ref) => AppRouteNotifier(ref),
);

class AppRouteNotifier extends StateNotifier<AppRoute> {
  final Ref _ref;
  late final SeedStore _seedStore = _ref.read(seedStoreProvider);

  AppRouteNotifier(this._ref) : super(AppRoute.setup) {
    _init();
  }

  Future<void> _init() async {
    final hasWallet = await _seedStore.hasMnemonic();
    state = hasWallet ? AppRoute.pinAuth : AppRoute.setup;
  }

  void goHome({bool duress = false}) {
    _ref.read(duressModeProvider.notifier).state = duress;
    state = AppRoute.home;
  }

  void goSetup() => state = AppRoute.setup;

  void lockWallet() {
    _ref.read(duressModeProvider.notifier).state = false;
    state = AppRoute.pinAuth;
  }

  void goDappConnect() => state = AppRoute.dappConnect;
}

// ── Wallet addresses ──────────────────────────────────────────────────────

final walletAddressesProvider = FutureProvider<WalletAddresses>((ref) async {
  final service = ref.watch(walletServiceProvider);
  return service.getAddresses();
});

// ── Mnemonic generation (temporary, for backup screen) ────────────────────

final pendingMnemonicProvider = StateProvider<String?>((ref) => null);
