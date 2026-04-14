import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/wallet_service.dart';
import 'wallet_provider.dart';

final balanceProvider = FutureProvider<WalletBalances>((ref) async {
  final service = ref.watch(walletServiceProvider);
  return service.getBalances();
});
