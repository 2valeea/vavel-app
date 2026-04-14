/// High-level categories for WalletConnect activity history.
enum WcActivityKind {
  sessionApproved,
  sessionRejected,
  personalSign,
  typedData,
  sendTransaction,
  pairing,
}

enum WcActivityOutcome {
  success,
  rejected,
  error,
}

class WcActivityEntry {
  const WcActivityEntry({
    required this.id,
    required this.at,
    required this.kind,
    required this.outcome,
    required this.dappName,
    required this.title,
    this.detail,
  });

  final String id;
  final DateTime at;
  final WcActivityKind kind;
  final WcActivityOutcome outcome;
  final String dappName;
  final String title;
  final String? detail;

  Map<String, dynamic> toJson() => {
        'id': id,
        'at': at.toIso8601String(),
        'kind': kind.name,
        'outcome': outcome.name,
        'dappName': dappName,
        'title': title,
        'detail': detail,
      };

  static WcActivityEntry? tryFromJson(Map<String, dynamic> j) {
    try {
      return WcActivityEntry(
        id: j['id'] as String,
        at: DateTime.parse(j['at'] as String),
        kind: WcActivityKind.values.byName(j['kind'] as String),
        outcome: WcActivityOutcome.values.byName(j['outcome'] as String),
        dappName: j['dappName'] as String? ?? '—',
        title: j['title'] as String? ?? '—',
        detail: j['detail'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
