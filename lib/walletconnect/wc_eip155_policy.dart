/// RPC methods this wallet implements for WalletConnect `eip155` sessions.
///
/// Any other requested method is **not** approved on the session (subset approval).
/// Methods in [blockedSessionMethods] cause the **entire** proposal to be rejected.
const Set<String> kAllowlistedWcEip155Methods = {
  'eth_sendTransaction',
  'personal_sign',
  'eth_signTypedData_v4',
};

/// Methods that must never be granted on a session (unsafe or not supported).
const Set<String> kBlockedWcEip155SessionMethods = {
  'eth_sign', // blind signing of raw 32-byte hash
  'eth_signTransaction',
};

/// Result of evaluating a dApp's requested `eip155` methods for session approval.
class SessionEip155MethodPolicy {
  SessionEip155MethodPolicy({
    required this.canApprove,
    required this.approvedMethods,
    required this.removedUnsupported,
    required this.rejectedDangerous,
    this.blockReason,
  });

  /// When `false`, the wallet must reject the session ([blockReason] explains why).
  final bool canApprove;

  /// Methods that will be sent to [approveSession] (always ⊆ requested, ⊆ allowlist).
  final List<String> approvedMethods;

  /// Requested methods that are not implemented and will be omitted from the session.
  final List<String> removedUnsupported;

  /// Blocked methods that were present in the proposal.
  final List<String> rejectedDangerous;

  /// User-facing reason when [canApprove] is `false`.
  final String? blockReason;

  static SessionEip155MethodPolicy evaluate(List<String> requestedRaw) {
    final requested = requestedRaw.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    if (requested.isEmpty) {
      return SessionEip155MethodPolicy(
        canApprove: false,
        approvedMethods: const [],
        removedUnsupported: const [],
        rejectedDangerous: const [],
        blockReason:
            'This dApp did not declare which Ethereum RPC methods it needs. '
            'For your safety, this wallet only connects when methods are explicitly listed.',
      );
    }

    final dangerous = requested.where(kBlockedWcEip155SessionMethods.contains).toList();
    if (dangerous.isNotEmpty) {
      return SessionEip155MethodPolicy(
        canApprove: false,
        approvedMethods: const [],
        removedUnsupported: const [],
        rejectedDangerous: dangerous,
        blockReason:
            'This dApp requests unsafe or unsupported methods (${dangerous.join(', ')}). '
            'Vavel Wallet does not grant those capabilities over WalletConnect.',
      );
    }

    final approved = requested.where(kAllowlistedWcEip155Methods.contains).toList();
    final removed = requested.where((m) => !kAllowlistedWcEip155Methods.contains(m)).toList();

    if (approved.isEmpty) {
      return SessionEip155MethodPolicy(
        canApprove: false,
        approvedMethods: const [],
        removedUnsupported: removed,
        rejectedDangerous: const [],
        blockReason:
            'None of the requested Ethereum RPC methods are supported by this wallet. '
            'Supported: ${kAllowlistedWcEip155Methods.join(', ')}.',
      );
    }

    return SessionEip155MethodPolicy(
      canApprove: true,
      approvedMethods: approved,
      removedUnsupported: removed,
      rejectedDangerous: const [],
      blockReason: null,
    );
  }
}
