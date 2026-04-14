import 'package:flutter_test/flutter_test.dart';
import 'package:vavel_app/walletconnect/wc_eip155_policy.dart';

void main() {
  group('SessionEip155MethodPolicy.evaluate', () {
    test('approves intersection and records removed unsupported', () {
      final p = SessionEip155MethodPolicy.evaluate([
        'eth_sendTransaction',
        'personal_sign',
        'eth_signTypedData_v4',
        'wallet_watchAsset',
        'eth_chainId',
      ]);
      expect(p.canApprove, isTrue);
      expect(Set<String>.from(p.approvedMethods), kAllowlistedWcEip155Methods);
      expect(p.removedUnsupported.toSet(), {'wallet_watchAsset', 'eth_chainId'});
      expect(p.rejectedDangerous, isEmpty);
    });

    test('rejects eth_sign entirely', () {
      final p = SessionEip155MethodPolicy.evaluate(['eth_sign', 'personal_sign']);
      expect(p.canApprove, isFalse);
      expect(p.rejectedDangerous, contains('eth_sign'));
    });

    test('rejects empty method list', () {
      final p = SessionEip155MethodPolicy.evaluate([]);
      expect(p.canApprove, isFalse);
      expect(p.blockReason, isNotNull);
    });

    test('rejects when nothing is supported', () {
      final p = SessionEip155MethodPolicy.evaluate(['eth_chainId']);
      expect(p.canApprove, isFalse);
      expect(p.approvedMethods, isEmpty);
    });
  });
}
