import '../crypto/ethereum_keypair.dart';

class WalletConnectService {
  final EthereumKeyPair keyPair;
  final WalletConnectConnectorStub connector = WalletConnectConnectorStub();

  WalletConnectService({required this.keyPair});

  Future<void> connect() async {
    connector.emitDisplayUri('wc:vavel-demo@2?relay-protocol=irn&symKey=demo');
  }

  void listen() {
    // No-op stub for demo mode.
  }

  Future<void> approveRequest(int id, dynamic result) async {
    connector.approveRequest(id: id, result: result);
  }

  Future<void> rejectRequest(int id, {String? message}) async {
    // No-op stub for demo mode.
  }
}

class WalletConnectConnectorStub {
  void Function(dynamic)? _displayUriListener;

  void on(String event, void Function(dynamic) callback) {
    if (event == 'display_uri') {
      _displayUriListener = callback;
    }
  }

  void emitDisplayUri(String uri) {
    _displayUriListener?.call(uri);
  }

  void approveRequest({required int id, required dynamic result}) {}

  void rejectRequest({required int id, required String error}) {}
}
