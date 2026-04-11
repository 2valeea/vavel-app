import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:reown_walletkit/reown_walletkit.dart' show Errors, Validation;
import 'package:web3dart/web3dart.dart';

import '../navigation/premium_page_route.dart';
import '../providers/wc_activity_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/sensitive_screen_guard.dart';
import '../walletconnect/wc_activity_entry.dart';
import '../walletconnect/wc_feedback_snackbar.dart';
import '../walletconnect/walletconnect_errors.dart';
import '../walletconnect/walletconnect_service.dart';
import '../utils/sensitive_action_auth.dart';
import '../walletconnect/eth_tx_risk_analysis.dart';
import '../walletconnect/personal_message_risk.dart';
import '../walletconnect/tx_risk_widgets.dart';
import '../walletconnect/typed_data_risk.dart';
import '../walletconnect/wc_sheet_ui.dart';
import '../walletconnect/wc_typed_data_preview.dart';

class DappConnectScreen extends ConsumerStatefulWidget {
  const DappConnectScreen({super.key});

  @override
  ConsumerState<DappConnectScreen> createState() => _DappConnectScreenState();
}

class _DappConnectScreenState extends ConsumerState<DappConnectScreen>
    with WidgetsBindingObserver {
  final _service = WalletConnectService();
  final _uriController = TextEditingController();
  StreamSubscription<WcProposalPrompt>? _proposalSub;
  StreamSubscription<WcSessionRequestPrompt>? _sessionRequestSub;
  StreamSubscription<String>? _statusSub;
  Future<void> _sessionRequestChain = Future.value();

  bool _initializing = true;
  bool _connecting = false;
  String _status = 'Ready to connect dApp';

  /// When set, WalletConnect cannot run until the user fixes configuration.
  String? _wcBlockingTitle;
  String? _wcBlockingBody;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final addresses = await ref.read(walletAddressesProvider.future);
      final chainId = ref.read(walletServiceProvider).ethereumChainId;
      await _service.initialize(
        walletAddress: addresses.ethereum,
        ethereumChainId: chainId,
      );
      _proposalSub = _service.proposals.listen(_showProposalSheet);
      _sessionRequestSub = _service.sessionRequests.listen((p) {
        _sessionRequestChain =
            _sessionRequestChain.then((_) => _handleSessionRequest(p));
      });
      _statusSub = _service.statusUpdates.listen((msg) {
        if (mounted) setState(() => _status = msg);
      });
      if (mounted) setState(() => _initializing = false);
    } on WalletConnectProjectIdMissing {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _wcBlockingTitle = WalletConnectProjectIdMissing.dialogTitle;
        _wcBlockingBody = WalletConnectProjectIdMissing.dialogBody;
        _status =
            'WalletConnect needs a Reown Cloud project ID. Tap the orange banner for setup steps.';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showWalletConnectSetupDialog(
          WalletConnectProjectIdMissing.dialogTitle,
          WalletConnectProjectIdMissing.dialogBody,
        );
      });
    } on WalletConnectInitializationFailed catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _wcBlockingTitle = WalletConnectInitializationFailed.dialogTitle;
        _wcBlockingBody =
            WalletConnectInitializationFailed.dialogBodyFor(e.cause);
        _status =
            'WalletConnect could not start. Tap the orange banner for details.';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showWalletConnectSetupDialog(
          WalletConnectInitializationFailed.dialogTitle,
          WalletConnectInitializationFailed.dialogBodyFor(e.cause),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _status = 'WalletConnect init failed: $e';
      });
    }
  }

  void _showWalletConnectSetupDialog(String title, String body) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: SelectableText(body,
              style: const TextStyle(fontSize: 14, height: 1.35)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      unawaited(_service.disconnectAll());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _proposalSub?.cancel();
    _sessionRequestSub?.cancel();
    _statusSub?.cancel();
    _uriController.dispose();
    unawaited(_service.dispose());
    super.dispose();
  }

  Future<void> _connectWithUri(String uri) async {
    if (uri.trim().isEmpty) return;
    setState(() => _connecting = true);
    try {
      await _service.pairUri(uri);
      if (mounted) setState(() => _status = 'Pairing in progress...');
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Connection failed: $e');
      await _wcAppendLog(
        WcActivityEntry(
          id: _wcActivityId(),
          at: DateTime.now(),
          kind: WcActivityKind.pairing,
          outcome: WcActivityOutcome.error,
          dappName: '—',
          title: 'Pairing failed',
          detail: '$e',
        ),
      );
      if (!mounted) return;
      showWcErrorSnackBar(
        ScaffoldMessenger.of(context),
        title: 'Could not pair',
        subtitle: 'Check the WalletConnect URI and try again.',
      );
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _scanQr() async {
    final uri = await Navigator.of(context).push<String>(
      PremiumPageRoute<String>(child: const _QrScannerPage()),
    );
    if (uri == null || !mounted) return;
    _uriController.text = uri;
    await _connectWithUri(uri);
  }

  Future<void> _handleSessionRequest(WcSessionRequestPrompt prompt) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (prompt) {
      case WcPersonalSignPrompt p:
        await showModalBottomSheet<void>(
          context: context,
          isDismissible: false,
          enableDrag: false,
          isScrollControlled: true,
          backgroundColor: const Color(0xFF172434),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          builder: (ctx) => SensitiveScreenGuard(
                child: _PersonalSignSheet(
            prompt: p,
            onReject: () async {
              await _service.respondRpcError(
                  p.event, Errors.USER_REJECTED_SIGN);
              await _wcAppendLog(
                WcActivityEntry(
                  id: _wcActivityId(),
                  at: DateTime.now(),
                  kind: WcActivityKind.personalSign,
                  outcome: WcActivityOutcome.rejected,
                  dappName: p.dappName,
                  title: 'personal_sign declined',
                ),
              );
              if (!mounted) return;
              showWcInfoSnackBar(
                messenger,
                title: 'Sign request declined',
                subtitle: p.dappName,
              );
            },
            onApprove: () async {
              if (!mounted) return;
              final authed = await ensureSensitiveActionAuthenticated(
                context,
                biometricReason:
                    'Sign this message for ${p.dappName}',
              );
              if (!authed) return;
              final svc = ref.read(walletServiceProvider);
              try {
                final sig = await svc
                    .signWalletConnectPersonalMessage(p.signingPayload);
                await _service.respondSuccess(p.event, sig);
                await _wcAppendLog(
                  WcActivityEntry(
                    id: _wcActivityId(),
                    at: DateTime.now(),
                    kind: WcActivityKind.personalSign,
                    outcome: WcActivityOutcome.success,
                    dappName: p.dappName,
                    title: 'personal_sign',
                    detail: 'Signature sent to dApp',
                  ),
                );
                if (!mounted) return;
                showWcSuccessSnackBar(
                  messenger,
                  title: 'Message signed',
                  subtitle: p.dappName,
                );
              } catch (e) {
                await _service.respondRpcError(
                  p.event,
                  Errors.MALFORMED_REQUEST_PARAMS,
                  messageOverride: e.toString(),
                );
                await _wcAppendLog(
                  WcActivityEntry(
                    id: _wcActivityId(),
                    at: DateTime.now(),
                    kind: WcActivityKind.personalSign,
                    outcome: WcActivityOutcome.error,
                    dappName: p.dappName,
                    title: 'personal_sign failed',
                    detail: '$e',
                  ),
                );
                if (!mounted) return;
                showWcErrorSnackBar(
                  messenger,
                  title: 'Signing failed',
                  subtitle: '$e',
                );
              }
            },
          ),
              ),
        );
      case WcTypedDataV4Prompt p:
        await showModalBottomSheet<void>(
          context: context,
          isDismissible: false,
          enableDrag: false,
          isScrollControlled: true,
          backgroundColor: const Color(0xFF172434),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          builder: (ctx) => SensitiveScreenGuard(
                child: _TypedDataV4Sheet(
            prompt: p,
            onReject: () async {
              await _service.respondRpcError(
                  p.event, Errors.USER_REJECTED_SIGN);
              final primary =
                  p.typedDataRoot['primaryType']?.toString() ?? 'typed data';
              await _wcAppendLog(
                WcActivityEntry(
                  id: _wcActivityId(),
                  at: DateTime.now(),
                  kind: WcActivityKind.typedData,
                  outcome: WcActivityOutcome.rejected,
                  dappName: p.dappName,
                  title: 'eth_signTypedData_v4 declined ($primary)',
                ),
              );
              if (!mounted) return;
              showWcInfoSnackBar(
                messenger,
                title: 'Typed data signing declined',
                subtitle: p.dappName,
              );
            },
            onApprove: () async {
              if (!mounted) return;
              final authed = await ensureSensitiveActionAuthenticated(
                context,
                biometricReason:
                    'Sign typed data for ${p.dappName}',
              );
              if (!authed) return;
              final svc = ref.read(walletServiceProvider);
              final primary =
                  p.typedDataRoot['primaryType']?.toString() ?? 'typed data';
              try {
                final sig =
                    await svc.signWalletConnectTypedDataV4(p.jsonForSigning);
                await _service.respondSuccess(p.event, sig);
                await _wcAppendLog(
                  WcActivityEntry(
                    id: _wcActivityId(),
                    at: DateTime.now(),
                    kind: WcActivityKind.typedData,
                    outcome: WcActivityOutcome.success,
                    dappName: p.dappName,
                    title: 'eth_signTypedData_v4 ($primary)',
                    detail: 'Signature sent to dApp',
                  ),
                );
                if (!mounted) return;
                showWcSuccessSnackBar(
                  messenger,
                  title: 'Typed data signed',
                  subtitle: p.dappName,
                );
              } catch (e) {
                await _service.respondRpcError(
                  p.event,
                  Errors.MALFORMED_REQUEST_PARAMS,
                  messageOverride: e.toString(),
                );
                await _wcAppendLog(
                  WcActivityEntry(
                    id: _wcActivityId(),
                    at: DateTime.now(),
                    kind: WcActivityKind.typedData,
                    outcome: WcActivityOutcome.error,
                    dappName: p.dappName,
                    title: 'eth_signTypedData_v4 failed ($primary)',
                    detail: '$e',
                  ),
                );
                if (!mounted) return;
                showWcErrorSnackBar(
                  messenger,
                  title: 'Typed data signing failed',
                  subtitle: '$e',
                );
              }
            },
          ),
              ),
        );
      case WcEthSendTxPrompt p:
        await showModalBottomSheet<void>(
          context: context,
          isDismissible: false,
          enableDrag: false,
          isScrollControlled: true,
          backgroundColor: const Color(0xFF172434),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          builder: (ctx) => SensitiveScreenGuard(
                child: _EthSendTxSheet(
            prompt: p,
            onReject: () async {
              await _service.respondRpcError(
                  p.event, Errors.USER_REJECTED_SIGN);
              await _wcAppendLog(
                WcActivityEntry(
                  id: _wcActivityId(),
                  at: DateTime.now(),
                  kind: WcActivityKind.sendTransaction,
                  outcome: WcActivityOutcome.rejected,
                  dappName: p.dappName,
                  title: 'eth_sendTransaction declined',
                  detail: 'Chain ${p.chainId}',
                ),
              );
              if (!mounted) return;
              showWcInfoSnackBar(
                messenger,
                title: 'Transaction cancelled',
                subtitle: p.dappName,
              );
            },
            onApprove: () async {
              if (!mounted) return;
              final authed = await ensureSensitiveActionAuthenticated(
                context,
                biometricReason:
                    'Send transaction requested by ${p.dappName}',
              );
              if (!authed) return;
              final svc = ref.read(walletServiceProvider);
              try {
                final hash = await svc.sendWalletConnectEthereumTransaction(
                  chainId: p.chainId,
                  tx: p.transaction,
                );
                await _service.respondSuccess(p.event, hash);
                await _wcAppendLog(
                  WcActivityEntry(
                    id: _wcActivityId(),
                    at: DateTime.now(),
                    kind: WcActivityKind.sendTransaction,
                    outcome: WcActivityOutcome.success,
                    dappName: p.dappName,
                    title: 'eth_sendTransaction',
                    detail: _shortHexForUi(hash, head: 12, tail: 8),
                  ),
                );
                if (!mounted) return;
                showWcSuccessSnackBar(
                  messenger,
                  title: 'Transaction sent',
                  subtitle:
                      '${p.dappName} · ${_shortHexForUi(hash, head: 14, tail: 10)}',
                );
              } catch (e) {
                await _service.respondRpcError(
                  p.event,
                  Errors.MALFORMED_REQUEST_PARAMS,
                  messageOverride: e.toString(),
                );
                await _wcAppendLog(
                  WcActivityEntry(
                    id: _wcActivityId(),
                    at: DateTime.now(),
                    kind: WcActivityKind.sendTransaction,
                    outcome: WcActivityOutcome.error,
                    dappName: p.dappName,
                    title: 'eth_sendTransaction failed',
                    detail: '$e',
                  ),
                );
                if (!mounted) return;
                showWcErrorSnackBar(
                  messenger,
                  title: 'Transaction failed',
                  subtitle: '$e',
                );
              }
            },
          ),
              ),
        );
    }
  }

  String _wcActivityId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${identityHashCode(this)}';

  Future<void> _wcAppendLog(WcActivityEntry entry) async {
    try {
      await ref.read(wcActivityLogProvider.notifier).add(entry);
    } catch (_) {
      // Persistence must never block signing / RPC.
    }
  }

  /// Short hex for snackbars and log lines (not security-critical formatting).
  String _shortHexForUi(String h, {int head = 10, int tail = 8}) {
    final t = h.trim();
    if (t.isEmpty) return '—';
    if (t.length <= head + tail + 1) return t;
    return '${t.substring(0, head)}…${t.substring(t.length - tail)}';
  }

  Future<void> _disconnectWcSession(WcActiveSessionSummary session) async {
    if (!mounted) return;
    final authed = await ensureSensitiveActionAuthenticated(
      context,
      biometricReason: 'Disconnect ${session.peerName}',
    );
    if (!authed || !mounted) return;
    try {
      await _service.disconnectSessionByTopic(session.topic);
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      showWcErrorSnackBar(
        ScaffoldMessenger.of(context),
        title: 'Could not disconnect',
        subtitle: '$e',
      );
    }
  }

  Widget _wcConnectedSessionsSection() {
    final blocked = _wcBlockingTitle != null;
    final sessions = _service.listActiveSessions();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        Text(
          'Connected dApps',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        if (sessions.isEmpty)
          Text(
            'No active WalletConnect sessions. After you approve a connection, '
            'the dApp appears here so you can review or disconnect it.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 12.5,
              height: 1.4,
            ),
          )
        else
          Column(
            children: [
              for (final s in sessions)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: const Color(0xFF152535),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.peerName.isNotEmpty ? s.peerName : 'dApp',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              if (s.peerUrl.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  s.peerUrl,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: blocked ? null : () => _disconnectWcSession(s),
                          child: const Text('Disconnect'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _wcRecentActivitySection() {
    return Consumer(
      builder: (context, ref, _) {
        final asyncLog = ref.watch(wcActivityLogProvider);
        return asyncLog.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (items) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 22),
                Text(
                  'Recent activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                if (items.isEmpty)
                  Text(
                    'No WalletConnect actions yet. Session approvals, signatures, '
                    'and transactions you complete are saved here for a future History tab.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  )
                else
                  Column(
                    children: [
                      for (final e in items.take(6)) _wcActivityTile(context, e),
                    ],
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _wcActivityTile(BuildContext context, WcActivityEntry e) {
    final time = DateFormat('MMM d, HH:mm').format(e.at.toLocal());
    final icon = switch (e.outcome) {
      WcActivityOutcome.success => Icons.check_circle_outline,
      WcActivityOutcome.rejected => Icons.cancel_outlined,
      WcActivityOutcome.error => Icons.error_outline,
    };
    final color = switch (e.outcome) {
      WcActivityOutcome.success => Colors.greenAccent,
      WcActivityOutcome.rejected => Colors.orangeAccent,
      WcActivityOutcome.error => Colors.redAccent,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFF152535),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    e.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              e.dappName,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            if (e.detail != null && e.detail!.isNotEmpty) ...[
              const SizedBox(height: 4),
              SelectableText(
                e.detail!,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11.5,
                  fontFamily: 'monospace',
                  height: 1.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showProposalSheet(WcProposalPrompt prompt) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF172434),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return SensitiveScreenGuard(
          child: _SessionApprovalSheet(
          prompt: prompt,
          onReject: () async {
            try {
              await _service.reject(prompt.event.id);
              await _wcAppendLog(
                WcActivityEntry(
                  id: _wcActivityId(),
                  at: DateTime.now(),
                  kind: WcActivityKind.sessionRejected,
                  outcome: WcActivityOutcome.rejected,
                  dappName: prompt.appName,
                  title: 'Session request declined',
                  detail: prompt.appUrl,
                ),
              );
              if (!mounted) return;
              showWcInfoSnackBar(
                messenger,
                title: 'Connection declined',
                subtitle: prompt.appName,
              );
            } catch (e) {
              if (!mounted) return;
              showWcErrorSnackBar(
                messenger,
                title: 'Could not decline session',
                subtitle: '$e',
              );
            }
          },
          onApprove: () async {
            if (!mounted) return;
            final authed = await ensureSensitiveActionAuthenticated(
              context,
              biometricReason:
                  'Approve WalletConnect session with ${prompt.appName}',
            );
            if (!authed) return;
            try {
              final result = await _service.approve(prompt);
              switch (result) {
                case WcSessionApproveResult.approved:
                  await _wcAppendLog(
                    WcActivityEntry(
                      id: _wcActivityId(),
                      at: DateTime.now(),
                      kind: WcActivityKind.sessionApproved,
                      outcome: WcActivityOutcome.success,
                      dappName: prompt.appName,
                      title: 'Session connected',
                      detail: prompt.appUrl,
                    ),
                  );
                  if (!mounted) return;
                  setState(() {});
                  showWcSuccessSnackBar(
                    messenger,
                    title: 'Session connected',
                    subtitle: prompt.appName,
                  );
                case WcSessionApproveResult.rejectedNoEthereum:
                  await _wcAppendLog(
                    WcActivityEntry(
                      id: _wcActivityId(),
                      at: DateTime.now(),
                      kind: WcActivityKind.sessionRejected,
                      outcome: WcActivityOutcome.rejected,
                      dappName: prompt.appName,
                      title: 'No Ethereum (eip155) namespace',
                      detail: 'Session was not opened',
                    ),
                  );
                  if (!mounted) return;
                  showWcInfoSnackBar(
                    messenger,
                    title: 'Session not opened',
                    subtitle:
                        'This dApp did not request an Ethereum connection.',
                  );
                case WcSessionApproveResult.rejectedByPolicy:
                  await _wcAppendLog(
                    WcActivityEntry(
                      id: _wcActivityId(),
                      at: DateTime.now(),
                      kind: WcActivityKind.sessionRejected,
                      outcome: WcActivityOutcome.rejected,
                      dappName: prompt.appName,
                      title: 'Session blocked by wallet policy',
                      detail: prompt.methodPolicy.blockReason,
                    ),
                  );
                  if (!mounted) return;
                  showWcErrorSnackBar(
                    messenger,
                    title: 'Session not allowed',
                    subtitle: prompt.methodPolicy.blockReason ??
                        'This session cannot be approved.',
                  );
              }
            } catch (e) {
              await _wcAppendLog(
                WcActivityEntry(
                  id: _wcActivityId(),
                  at: DateTime.now(),
                  kind: WcActivityKind.sessionApproved,
                  outcome: WcActivityOutcome.error,
                  dappName: prompt.appName,
                  title: 'Session approval failed',
                  detail: '$e',
                ),
              );
              if (!mounted) return;
              showWcErrorSnackBar(
                messenger,
                title: 'Could not connect session',
                subtitle: '$e',
              );
            }
          },
        ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WalletConnect')),
      body: _initializing
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: 0,
                        maxWidth: kWcSheetMaxContentWidth,
                        minHeight: constraints.maxHeight - 44,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_wcBlockingTitle != null) ...[
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _wcBlockingBody == null
                                    ? null
                                    : () => _showWalletConnectSetupDialog(
                                          _wcBlockingTitle!,
                                          _wcBlockingBody!,
                                        ),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.deepOrange
                                        .withValues(alpha: 0.2),
                                    border: Border.all(
                                      color: Colors.deepOrange
                                          .withValues(alpha: 0.55),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: Colors.deepOrangeAccent),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _wcBlockingTitle!,
                                              style: const TextStyle(
                                                color: Colors.deepOrangeAccent,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            const Text(
                                              'Tap for setup instructions and technical details.',
                                              style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right,
                                          color: Colors.white54),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.4)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Only connect to dApps you trust. Never approve unknown signatures.',
                              style: TextStyle(
                                  color: Colors.orangeAccent, fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _uriController,
                            decoration: InputDecoration(
                              labelText: 'WalletConnect URI',
                              hintText: 'wc:...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          LayoutBuilder(
                            builder: (context, btnConstraints) {
                              final stackActions =
                                  btnConstraints.maxWidth < 400;
                              final connect = ElevatedButton.icon(
                                onPressed: (_connecting ||
                                        _wcBlockingTitle != null)
                                    ? null
                                    : () =>
                                        _connectWithUri(_uriController.text),
                                icon: const Icon(Icons.link),
                                label: Text(
                                    _connecting ? 'Connecting...' : 'Connect'),
                              );
                              final scan = OutlinedButton.icon(
                                onPressed:
                                    (_connecting || _wcBlockingTitle != null)
                                        ? null
                                        : _scanQr,
                                icon: const Icon(Icons.qr_code_scanner),
                                label: const Text('Scan QR'),
                              );
                              if (stackActions) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    connect,
                                    const SizedBox(height: 10),
                                    scan,
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  Expanded(child: connect),
                                  const SizedBox(width: 10),
                                  Expanded(child: scan),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A2A3E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _status,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          _wcConnectedSessionsSection(),
                          _wcRecentActivitySection(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _TypedDataV4Sheet extends ConsumerStatefulWidget {
  final WcTypedDataV4Prompt prompt;
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;

  const _TypedDataV4Sheet({
    required this.prompt,
    required this.onApprove,
    required this.onReject,
  });

  @override
  ConsumerState<_TypedDataV4Sheet> createState() => _TypedDataV4SheetState();
}

class _TypedDataV4SheetState extends ConsumerState<_TypedDataV4Sheet> {
  Future<Map<String, int>>? _decimalsFuture;

  Future<Map<String, int>> _ensureDecimalsFuture() {
    return _decimalsFuture ??= _loadTokenDecimals();
  }

  Future<Map<String, int>> _loadTokenDecimals() async {
    final addrs =
        erc20AddressesForTypedDataPreview(widget.prompt.typedDataRoot);
    if (addrs.isEmpty) return const {};
    final svc = ref.read(walletServiceProvider);
    final out = <String, int>{};
    for (final a in addrs) {
      if (!mounted) break;
      try {
        final d = await svc.getErc20Decimals(a);
        if (d != null && mounted) out[a] = d;
      } catch (_) {
        // Omit on RPC failure; preview falls back to raw units.
      }
    }
    return out;
  }

  static String _prettyJson(Object? value) {
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }

  static List<Widget> _domainRows(Map<String, dynamic> root) {
    final domain = root['domain'];
    if (domain is! Map) {
      return [
        const Text(
          'No domain in typed data',
          style: TextStyle(color: Colors.white54),
        ),
      ];
    }
    final m = Map<String, dynamic>.from(domain);
    final out = <Widget>[];
    final sortedKeys = m.keys.toList()..sort();
    for (final k in sortedKeys) {
      final v = m[k];
      out.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  k,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              Expanded(
                child: SelectableText(
                  v?.toString() ?? '—',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final root = widget.prompt.typedDataRoot;
    final primary = root['primaryType']?.toString() ?? '—';
    final message = root['message'];
    final mq = MediaQuery.of(context);
    final sheetHeight = mq.orientation == Orientation.landscape
        ? (mq.size.height * 0.92).clamp(260.0, mq.size.height - 16)
        : (mq.size.height * 0.88).clamp(340.0, 760.0);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + mq.viewInsets.bottom,
        ),
        child: WcSheetMaxWidth(
          child: SizedBox(
            height: sheetHeight,
            child: FutureBuilder<Map<String, int>>(
              future: _ensureDecimalsFuture(),
              builder: (context, snap) {
                final decMap = snap.data ?? const <String, int>{};
                final human = buildTypedDataHumanPreview(
                  root,
                  tokenDecimalsByLowerAddress: decMap,
                );
                final loading = snap.connectionState == ConnectionState.waiting;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (loading)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: const LinearProgressIndicator(minHeight: 3),
                        ),
                      ),
                    Row(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.tealAccent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.fact_check_outlined,
                                color: Colors.tealAccent, size: 22),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Sign typed data (EIP-712)',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.prompt.dappName,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: wcTypedDataKindPill(human.kind),
                            ),
                            const SizedBox(height: 10),
                            TxRiskSignalList(
                                signals: analyzeTypedDataRisks(root)),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: wcPreviewCardDecoration(
                                borderAccent: wcPreviewKindAccent(human.kind),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    human.headline,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...human.bullets.map(wcPreviewBulletLine),
                                  if (human.securityNote != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.amber
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: Colors.amber
                                                .withValues(alpha: 0.28)),
                                      ),
                                      child: Text(
                                        human.securityNote!,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          height: 1.4,
                                          color: Colors.amber.shade50,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            wcSecurityCallout(
                              text:
                                  'Typed signatures can move tokens or control smart accounts. When in doubt, reject.',
                              accent: Colors.amberAccent,
                              icon: Icons.gavel_outlined,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Primary type: $primary',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            ExpansionTile(
                              initiallyExpanded: false,
                              tilePadding: EdgeInsets.zero,
                              collapsedShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              title: const Text(
                                'Technical details (raw JSON)',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A2A3E),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const Text('Domain',
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 11)),
                                      const SizedBox(height: 4),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: _domainRows(root),
                                      ),
                                      const SizedBox(height: 10),
                                      const Text('Message',
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 11)),
                                      const SizedBox(height: 4),
                                      SelectableText(
                                        _prettyJson(message),
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 10,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    WcConfirmActionsRow(
                      rejectLabel: 'Reject',
                      confirmLabel: 'Sign typed data',
                      onReject: widget.onReject,
                      onApprove: widget.onApprove,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonalSignSheet extends StatelessWidget {
  final WcPersonalSignPrompt prompt;
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;

  const _PersonalSignSheet({
    required this.prompt,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        child: WcSheetMaxWidth(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.edit_note_outlined,
                            color: Colors.lightBlueAccent, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sign message',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  prompt.dappName,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 14),
                wcSecurityCallout(
                  text:
                      'Only sign if you trust this site. Signatures can authorize actions or prove ownership.',
                  accent: Colors.amberAccent,
                  icon: Icons.warning_amber_rounded,
                ),
                const SizedBox(height: 12),
                TxRiskSignalList(
                    signals: analyzePersonalMessageRisks(prompt.preview)),
                const SizedBox(height: 12),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.38,
                  ),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2A3E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      prompt.preview,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        height: 1.4,
                        color: Color(0xFFECEFF1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                WcConfirmActionsRow(
                  rejectLabel: 'Reject',
                  confirmLabel: 'Sign',
                  onReject: onReject,
                  onApprove: onApprove,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EthSendTxSheet extends StatelessWidget {
  final WcEthSendTxPrompt prompt;
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;

  const _EthSendTxSheet({
    required this.prompt,
    required this.onApprove,
    required this.onReject,
  });

  String _shortHex(String? h, {int head = 10, int tail = 8}) {
    if (h == null || h.isEmpty) return '—';
    if (h.length <= head + tail + 3) return h;
    return '${h.substring(0, head)}…${h.substring(h.length - tail)}';
  }

  String _formatValueWei(dynamic v) {
    if (v == null) return '0 ETH';
    try {
      final s = v.toString();
      if (s.isEmpty || s == '0x') return '0 ETH';
      final wei = BigInt.parse(strip0x(s), radix: 16);
      final eth = wei / BigInt.from(10).pow(18);
      return '$eth ETH';
    } catch (_) {
      return v.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = prompt.transaction;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final analyzed = analyzeEthereumTxRisks(transaction: tx);
    final decode = analyzed.decode;
    final risks = analyzed.risks;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        child: WcSheetMaxWidth(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.outbound,
                            color: Colors.orangeAccent, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Send transaction',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  prompt.dappName,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 14),
                TxRiskSignalList(signals: risks),
                if (decode != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: wcPreviewCardDecoration(
                        borderAccent: const Color(0xFF4FC3F7)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Decoded call (best effort)',
                          style: TextStyle(
                            color: Colors.lightBlue.shade100,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          decode.functionLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...decode.detailLines.map(
                          (line) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: SelectableText(
                              line,
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.35,
                                fontFamily: 'monospace',
                                color: Color(0xFFECEFF1),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: wcPreviewCardDecoration(
                      borderAccent: Colors.deepOrangeAccent),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Raw transaction fields',
                        style: TextStyle(
                          color: Colors.orange.shade100,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _kv('Network', 'Chain ID ${prompt.chainId}'),
                      _kv('To', _shortHex(tx['to'] as String?)),
                      _kv('From', _shortHex(tx['from'] as String?)),
                      _kv('Value', _formatValueWei(tx['value'])),
                      _kv(
                        'Data',
                        () {
                          final d = tx['data'];
                          if (d == null) return 'Empty';
                          final s = d.toString();
                          if (s.length <= 2 || s == '0x') return 'Empty';
                          final hex = strip0x(s);
                          return '${hex.length ~/ 2} bytes';
                        }(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                wcSecurityCallout(
                  text:
                      'This submits an on-chain transaction from your wallet. Verify the recipient and amount carefully.',
                  accent: Colors.redAccent,
                  icon: Icons.account_balance_wallet_outlined,
                ),
                const SizedBox(height: 18),
                WcConfirmActionsRow(
                  rejectLabel: 'Reject',
                  confirmLabel: 'Confirm & send',
                  onReject: onReject,
                  onApprove: onApprove,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(
              k,
              style: const TextStyle(
                color: Color(0xFFB0BEC5),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              v,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                height: 1.35,
                color: Color(0xFFECEFF1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionApprovalSheet extends StatelessWidget {
  final WcProposalPrompt prompt;
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;

  const _SessionApprovalSheet({
    required this.prompt,
    required this.onApprove,
    required this.onReject,
  });

  String _verificationLabel(Validation validation) {
    return switch (validation) {
      Validation.VALID => 'Verified domain',
      Validation.UNKNOWN => 'Domain not verified',
      Validation.INVALID => 'Domain verification failed',
      Validation.SCAM => 'Potentially malicious domain',
    };
  }

  Color _verificationColor(Validation validation) {
    return switch (validation) {
      Validation.VALID => Colors.greenAccent,
      Validation.UNKNOWN => Colors.orangeAccent,
      Validation.INVALID => Colors.redAccent,
      Validation.SCAM => Colors.red,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _verificationColor(prompt.verification);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        child: WcSheetMaxWidth(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  prompt.appName,
                  style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  prompt.appUrl,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  prompt.appDescription,
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 13, height: 1.35),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.55)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified_user_outlined,
                          color: color, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _verificationLabel(prompt.verification),
                          style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                if (prompt.needsTrustWarning) ...[
                  const SizedBox(height: 10),
                  wcSecurityCallout(
                    text:
                        'This site is new or unverified. Only continue if you trust it.',
                    accent: Colors.redAccent,
                    icon: Icons.report_problem_outlined,
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Ethereum methods',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFFECEFF1)),
                ),
                const SizedBox(height: 8),
                if (!prompt.methodPolicy.canApprove)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.red.withValues(alpha: 0.45)),
                    ),
                    child: Text(
                      prompt.methodPolicy.blockReason ??
                          'This session cannot be approved.',
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12.5, height: 1.4),
                    ),
                  )
                else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.withValues(alpha: 0.1),
                          const Color(0xFF1A2A3E),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.38)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'This wallet will grant only:',
                          style: TextStyle(
                              color: Colors.lightGreenAccent,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        ...prompt.methodPolicy.approvedMethods.map(
                          (m) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: SelectableText(
                              m,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontFamily: 'monospace',
                                height: 1.35,
                                color: Color(0xFFE8F5E9),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (prompt.methodPolicy.removedUnsupported.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Not granted (unsupported by this wallet):',
                            style: TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            prompt.methodPolicy.removedUnsupported.join(', '),
                            style: const TextStyle(
                                fontSize: 11.5,
                                fontFamily: 'monospace',
                                color: Colors.white70,
                                height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 20),
                WcConfirmActionsRow(
                  rejectLabel: 'Reject',
                  confirmLabel: 'Approve',
                  onReject: onReject,
                  onApprove: onApprove,
                  confirmEnabled: prompt.methodPolicy.canApprove,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QrScannerPage extends StatefulWidget {
  const _QrScannerPage();

  @override
  State<_QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<_QrScannerPage> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan WalletConnect QR')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_handled) return;
          final code = capture.barcodes.isNotEmpty
              ? capture.barcodes.first.rawValue
              : null;
          if (code == null || !code.startsWith('wc:')) return;
          _handled = true;
          HapticFeedback.selectionClick();
          Navigator.of(context).pop(code);
        },
      ),
    );
  }
}
