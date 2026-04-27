import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import '../stripe/stripe_unlock_store.dart';
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

enum AppRoute { setup, pinAuth, paywall, paymentThanks, home }

/// After unlock with the **panic (duress) PIN**: decoy portfolio, no send/swap/receive addrs.
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
    if (duress) {
      state = AppRoute.home;
      return;
    }
    unawaited(_goHomeAfterAccessCheck());
  }

  Future<void> _goHomeAfterAccessCheck() async {
    final unlocked = await StripeUnlockStore.isUnlocked();
    state = unlocked ? AppRoute.home : AppRoute.paywall;
  }

  /// After Stripe Checkout verification (deep link) — show thank-you screen.
  void completeStripeCheckoutAndShowThanks() {
    state = AppRoute.paymentThanks;
  }

  /// Thank-you screen → wallet home.
  void leavePaymentThanksToHome() {
    state = AppRoute.home;
  }

  void goSetup() => state = AppRoute.setup;

  void lockWallet() {
    _ref.read(duressModeProvider.notifier).state = false;
    state = AppRoute.pinAuth;
  }
}

// ── Wallet addresses ──────────────────────────────────────────────────────

final walletAddressesProvider = FutureProvider<WalletAddresses>((ref) async {
  final service = ref.watch(walletServiceProvider);
  return service.getAddresses();
});

// ── Mnemonic generation (backup screen) ───────────────────────────────────

final pendingMnemonicProvider = StateProvider<String?>((ref) => null);
