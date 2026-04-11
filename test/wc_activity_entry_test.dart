import 'package:flutter_test/flutter_test.dart';
import 'package:vavel_wallet/walletconnect/wc_activity_entry.dart';

void main() {
  test('WcActivityEntry round-trips through JSON', () {
    final original = WcActivityEntry(
      id: 'test-1',
      at: DateTime.utc(2026, 4, 10, 12, 30),
      kind: WcActivityKind.sendTransaction,
      outcome: WcActivityOutcome.success,
      dappName: 'Example dApp',
      title: 'eth_sendTransaction',
      detail: '0xabc…def',
    );
    final json = original.toJson();
    final copy = WcActivityEntry.tryFromJson(json);
    expect(copy, isNotNull);
    expect(copy!.id, original.id);
    expect(copy.kind, original.kind);
    expect(copy.outcome, original.outcome);
    expect(copy.dappName, original.dappName);
    expect(copy.title, original.title);
    expect(copy.detail, original.detail);
    expect(copy.at.toUtc(), original.at.toUtc());
  });

  test('tryFromJson returns null for unknown kind', () {
    final bad = WcActivityEntry(
      id: 'x',
      at: DateTime.now(),
      kind: WcActivityKind.pairing,
      outcome: WcActivityOutcome.error,
      dappName: 'd',
      title: 't',
    ).toJson();
    bad['kind'] = 'not_a_real_kind';
    expect(WcActivityEntry.tryFromJson(bad), isNull);
  });
}
