import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

import '../config.dart';
import 'walletconnect_errors.dart';
import 'walletconnect_sign_parsing.dart';
import 'wc_eip155_policy.dart';

/// Result of attempting to approve a WalletConnect session proposal.
enum WcSessionApproveResult {
  approved,
  rejectedNoEthereum,
  rejectedByPolicy,
}

class WcProposalPrompt {
  final SessionProposalEvent event;
  final String appName;
  final String appDescription;
  final String appUrl;
  final String? appIconUrl;
  final bool needsTrustWarning;
  final Validation verification;

  /// Declared `eip155` methods vs this wallet’s allowlist (subset on approve).
  final SessionEip155MethodPolicy methodPolicy;

  WcProposalPrompt({
    required this.event,
    required this.appName,
    required this.appDescription,
    required this.appUrl,
    required this.appIconUrl,
    required this.needsTrustWarning,
    required this.verification,
    required this.methodPolicy,
  });
}

/// Parsed WalletConnect session request for in-app confirmation.
sealed class WcSessionRequestPrompt {
  SessionRequestEvent get event;
  String get dappName;
}

class WcPersonalSignPrompt extends WcSessionRequestPrompt {
  @override
  final SessionRequestEvent event;
  @override
  final String dappName;
  final List<int> signingPayload;
  final String preview;
  final String? declaredAddress;

  WcPersonalSignPrompt({
    required this.event,
    required this.dappName,
    required this.signingPayload,
    required this.preview,
    required this.declaredAddress,
  });
}

class WcEthSendTxPrompt extends WcSessionRequestPrompt {
  @override
  final SessionRequestEvent event;
  @override
  final String dappName;
  final int chainId;
  final Map<String, dynamic> transaction;

  WcEthSendTxPrompt({
    required this.event,
    required this.dappName,
    required this.chainId,
    required this.transaction,
  });
}

/// Active WalletConnect session for UI (connected dApps list).
class WcActiveSessionSummary {
  const WcActiveSessionSummary({
    required this.topic,
    required this.peerName,
    required this.peerUrl,
  });

  final String topic;
  final String peerName;
  final String peerUrl;
}

class WcTypedDataV4Prompt extends WcSessionRequestPrompt {
  @override
  final SessionRequestEvent event;
  @override
  final String dappName;
  final String jsonForSigning;
  final Map<String, dynamic> typedDataRoot;

  WcTypedDataV4Prompt({
    required this.event,
    required this.dappName,
    required this.jsonForSigning,
    required this.typedDataRoot,
  });
}

class WalletConnectService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _trustedHostsKey = 'wc_trusted_hosts';

  ReownWalletKit? _kit;
  String? _walletAddress;
  int _ethereumChainId = 1;
  bool _initialized = false;

  final _proposalController = StreamController<WcProposalPrompt>.broadcast();
  Stream<WcProposalPrompt> get proposals => _proposalController.stream;

  final _requestController = StreamController<WcSessionRequestPrompt>.broadcast();
  Stream<WcSessionRequestPrompt> get sessionRequests => _requestController.stream;

  final _statusController = StreamController<String>.broadcast();
  Stream<String> get statusUpdates => _statusController.stream;

  Future<void> initialize({
    required String walletAddress,
    required int ethereumChainId,
  }) async {
    if (_initialized) return;
    _walletAddress = walletAddress;
    _ethereumChainId = ethereumChainId;
    if (!RpcConfig.isWalletConnectProjectIdConfigured) {
      throw const WalletConnectProjectIdMissing();
    }
    final projectId = RpcConfig.walletConnectProjectId.trim();

    final ReownWalletKit kit;
    try {
      kit = await ReownWalletKit.createInstance(
        projectId: projectId,
        metadata: const PairingMetadata(
          name: 'Vavel Wallet',
          description: 'Multi-chain wallet for Vavel ecosystem',
          url: 'https://vavel.app',
          icons: ['https://vavel.app/icon.png'],
        ),
        logLevel: LogLevel.error,
      );
    } catch (e, _) {
      throw WalletConnectInitializationFailed(e);
    }

    _kit = kit;
    kit.onSessionProposal.subscribe(_onSessionProposal);
    kit.onSessionRequest.subscribe(_onSessionRequest);
    kit.onSessionConnect.subscribe(
      (args) => _statusController.add('Connected to ${args.session.peer.metadata.name}'),
    );
    kit.onSessionDelete.subscribe((_) => _statusController.add('Session disconnected'));
    _initialized = true;
  }

  Future<void> pairUri(String rawUri) async {
    final kit = _requireKit();
    final uri = Uri.tryParse(rawUri.trim());
    if (uri == null || uri.scheme != 'wc') {
      throw const FormatException('Invalid WalletConnect URI');
    }
    await kit.pair(uri: uri);
    _statusController.add('Pairing request sent. Awaiting approval request...');
  }

  Future<WcSessionApproveResult> approve(WcProposalPrompt prompt) async {
    final kit = _requireKit();
    final address = _walletAddress;
    if (address == null || address.isEmpty) {
      throw StateError('Wallet address is unavailable');
    }

    final requested = prompt.event.params.requiredNamespaces['eip155'];
    if (requested == null) {
      await reject(prompt.event.id, reason: 'Only Ethereum sessions are supported.');
      return WcSessionApproveResult.rejectedNoEthereum;
    }

    final policy = prompt.methodPolicy;
    if (!policy.canApprove) {
      await reject(
        prompt.event.id,
        reason: policy.blockReason ?? 'Session rejected for security policy.',
      );
      return WcSessionApproveResult.rejectedByPolicy;
    }

    final nsChains = requested.chains;
    final chains = nsChains == null
        ? const <String>['eip155:1']
        : nsChains.where((c) => c.startsWith('eip155:')).toList();
    final accounts = chains.map((chain) => '$chain:$address').toList();

    await kit.approveSession(
      id: prompt.event.id,
      namespaces: {
        'eip155': Namespace(
          chains: chains,
          accounts: accounts,
          methods: policy.approvedMethods,
          events: requested.events,
        ),
      },
    );

    await _markHostTrusted(prompt.appUrl);
    _statusController.add('Approved session for ${prompt.appName}');
    return WcSessionApproveResult.approved;
  }

  Future<void> reject(int id, {String? reason}) async {
    final kit = _requireKit();
    await kit.rejectSession(
      id: id,
      reason: ReownSignError(
        code: Errors.getSdkError(Errors.USER_REJECTED).code,
        message: reason ?? 'User rejected connection',
      ),
    );
    _statusController.add('Session rejected');
  }

  Future<void> respondSuccess(SessionRequestEvent e, Object result) async {
    final kit = _requireKit();
    await kit.respondSessionRequest(
      topic: e.topic,
      response: JsonRpcResponse(
        id: e.id,
        jsonrpc: '2.0',
        result: result,
      ),
    );
  }

  Future<void> respondRpcError(
    SessionRequestEvent e,
    String sdkErrorKey, {
    String? messageOverride,
  }) async {
    final kit = _requireKit();
    final err = Errors.getSdkError(sdkErrorKey);
    await kit.respondSessionRequest(
      topic: e.topic,
      response: JsonRpcResponse(
        id: e.id,
        jsonrpc: '2.0',
        error: JsonRpcError(
          code: err.code,
          message: messageOverride ?? err.message,
        ),
      ),
    );
  }

  Future<void> disconnectAll() async {
    final kit = _kit;
    if (kit == null) return;
    final sessions = kit.getActiveSessions();
    for (final session in sessions.values) {
      await kit.disconnectSession(
        topic: session.topic,
        reason: ReownSignError(
          code: Errors.getSdkError(Errors.USER_DISCONNECTED).code,
          message: 'Disconnected because app was closed',
        ),
      );
    }
  }

  /// Connected dApp sessions (newest first by map iteration order).
  List<WcActiveSessionSummary> listActiveSessions() {
    final kit = _kit;
    if (kit == null) return const [];
    final map = kit.getActiveSessions();
    final out = <WcActiveSessionSummary>[];
    for (final s in map.values) {
      final meta = s.peer.metadata;
      out.add(
        WcActiveSessionSummary(
          topic: s.topic,
          peerName: meta.name,
          peerUrl: meta.url,
        ),
      );
    }
    return out;
  }

  Future<void> disconnectSessionByTopic(String topic) async {
    final kit = _requireKit();
    await kit.disconnectSession(
      topic: topic,
      reason: ReownSignError(
        code: Errors.getSdkError(Errors.USER_DISCONNECTED).code,
        message: 'Disconnected by you from Vavel Wallet',
      ),
    );
    _statusController.add('Session disconnected');
  }

  Future<void> dispose() async {
    final kit = _kit;
    if (kit != null) {
      kit.onSessionRequest.unsubscribe(_onSessionRequest);
    }
    await _proposalController.close();
    await _requestController.close();
    await _statusController.close();
  }

  void _onSessionProposal(SessionProposalEvent args) async {
    final metadata = args.params.proposer.metadata;
    final appUrl = metadata.url;
    final trusted = await _isHostTrusted(appUrl);
    final verification = args.verifyContext?.validation ?? Validation.UNKNOWN;
    final requestedNs = args.params.requiredNamespaces['eip155'];
    final methodPolicy = requestedNs == null
        ? SessionEip155MethodPolicy(
            canApprove: false,
            approvedMethods: const [],
            removedUnsupported: const [],
            rejectedDangerous: const [],
            blockReason:
                'This dApp did not request an Ethereum (eip155) connection. Vavel Wallet only supports Ethereum over WalletConnect.',
          )
        : SessionEip155MethodPolicy.evaluate(requestedNs.methods);
    _proposalController.add(
      WcProposalPrompt(
        event: args,
        appName: metadata.name,
        appDescription: metadata.description,
        appUrl: appUrl,
        appIconUrl: metadata.icons.isNotEmpty ? metadata.icons.first : null,
        needsTrustWarning: !trusted || verification == Validation.INVALID || verification == Validation.SCAM,
        verification: verification,
        methodPolicy: methodPolicy,
      ),
    );
  }

  void _onSessionRequest(SessionRequestEvent args) {
    final kit = _kit;
    if (kit == null) return;

    final wallet = _walletAddress;
    if (wallet == null || wallet.isEmpty) {
      unawaited(
        respondRpcError(
          args,
          Errors.UNSUPPORTED_ACCOUNTS,
          messageOverride: 'Wallet address is unavailable.',
        ),
      );
      return;
    }

    final dappName = kit.sessions.get(args.topic)?.peer.metadata.name ?? 'dApp';

    switch (args.method) {
      case 'personal_sign':
        try {
          final parsed = parseWalletConnectPersonalSign(args.params, wallet);
          _requestController.add(
            WcPersonalSignPrompt(
              event: args,
              dappName: dappName,
              signingPayload: parsed.payload,
              preview: parsed.preview,
              declaredAddress: parsed.declaredAddress,
            ),
          );
        } catch (e) {
          unawaited(
            respondRpcError(
              args,
              Errors.MALFORMED_REQUEST_PARAMS,
              messageOverride: e.toString(),
            ),
          );
        }
      case 'eth_sendTransaction':
        try {
          final map = _parseSendTransactionParams(args.params);
          final chain = parseEip155ChainId(args.chainId);
          if (chain != _ethereumChainId) {
            unawaited(
              respondRpcError(
                args,
                Errors.UNSUPPORTED_CHAINS,
                messageOverride:
                    'This wallet is on chain ID $_ethereumChainId; the dApp requested $chain.',
              ),
            );
            return;
          }
          _requestController.add(
            WcEthSendTxPrompt(
              event: args,
              dappName: dappName,
              chainId: chain,
              transaction: map,
            ),
          );
        } catch (e) {
          unawaited(
            respondRpcError(
              args,
              Errors.MALFORMED_REQUEST_PARAMS,
              messageOverride: e.toString(),
            ),
          );
        }
      case 'eth_signTypedData_v4':
        try {
          final chain = parseEip155ChainId(args.chainId);
          if (chain != _ethereumChainId) {
            unawaited(
              respondRpcError(
                args,
                Errors.UNSUPPORTED_CHAINS,
                messageOverride:
                    'This wallet is on chain ID $_ethereumChainId; the dApp requested $chain.',
              ),
            );
            return;
          }
          final parsed = parseWalletConnectEthSignTypedDataV4(
            args.params,
            wallet,
            _ethereumChainId,
          );
          _requestController.add(
            WcTypedDataV4Prompt(
              event: args,
              dappName: dappName,
              jsonForSigning: parsed.jsonForSigning,
              typedDataRoot: parsed.rootMap,
            ),
          );
        } catch (e) {
          unawaited(
            respondRpcError(
              args,
              Errors.MALFORMED_REQUEST_PARAMS,
              messageOverride: e.toString(),
            ),
          );
        }
      default:
        unawaited(
          respondRpcError(
            args,
            Errors.UNSUPPORTED_METHODS,
            messageOverride: 'Method ${args.method} is not supported.',
          ),
        );
    }
  }

  static int parseEip155ChainId(String chain) {
    final parts = chain.split(':');
    if (parts.length != 2 || parts[0] != 'eip155') {
      throw FormatException('Unsupported chain id: $chain');
    }
    return int.parse(parts[1]);
  }

  static Map<String, dynamic> _parseSendTransactionParams(dynamic params) {
    if (params is! List || params.isEmpty) {
      throw const FormatException('eth_sendTransaction params must be a non-empty list');
    }
    final first = params.first;
    if (first is! Map) {
      throw const FormatException('eth_sendTransaction first param must be an object');
    }
    return Map<String, dynamic>.from(first);
  }

  ReownWalletKit _requireKit() {
    final kit = _kit;
    if (kit == null) {
      throw StateError('WalletConnect is not initialized');
    }
    return kit;
  }

  Future<bool> _isHostTrusted(String url) async {
    final host = _hostFromUrl(url);
    if (host.isEmpty) return false;
    final trustedHosts = await _readTrustedHosts();
    return trustedHosts.contains(host);
  }

  Future<void> _markHostTrusted(String url) async {
    final host = _hostFromUrl(url);
    if (host.isEmpty) return;
    final trustedHosts = await _readTrustedHosts();
    trustedHosts.add(host);
    await _storage.write(
      key: _trustedHostsKey,
      value: jsonEncode(trustedHosts.toList()),
    );
  }

  Future<Set<String>> _readTrustedHosts() async {
    final raw = await _storage.read(key: _trustedHostsKey);
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>{};
      return decoded.whereType<String>().toSet();
    } catch (_) {
      return <String>{};
    }
  }

  String _hostFromUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    return uri?.host.toLowerCase() ?? '';
  }
}
