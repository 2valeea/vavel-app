import 'dart:convert';

import 'package:eth_sig_util_plus/eth_sig_util_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vavel_app/walletconnect/walletconnect_sign_parsing.dart';

void main() {
  group('parseWalletConnectPersonalSign', () {
    const wallet = '0x14791697260E4a9e1C3C51Aae992909b385dfb00';

    test('standard order [message, address] with hex message', () {
      final r = parseWalletConnectPersonalSign(
        [
          '0x${'ab' * 32}', // 32 bytes (64 hex digits)
          wallet,
        ],
        wallet,
      );
      expect(r.payload.length, 32);
      expect(r.declaredAddress, wallet);
    });

    test('reversed order [address, message]', () {
      final r = parseWalletConnectPersonalSign(
        [
          wallet,
          'Hello VAVEL',
        ],
        wallet,
      );
      expect(utf8.decode(r.payload), 'Hello VAVEL');
    });

    test('rejects signer mismatch', () {
      expect(
        () => parseWalletConnectPersonalSign(
          ['hello', '0x0000000000000000000000000000000000000001'],
          wallet,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('parseWalletConnectEthSignTypedDataV4', () {
    const wallet = '0x0000000000000000000000000000000000000001';
    const chainId = 1;

    test('parses [address, typedData map] and encodes JSON for signing', () {
      final typed = {
        'types': {
          'EIP712Domain': [
            {'name': 'name', 'type': 'string'},
            {'name': 'version', 'type': 'string'},
            {'name': 'chainId', 'type': 'uint256'},
            {'name': 'verifyingContract', 'type': 'address'},
          ],
          'Mail': [
            {'name': 'contents', 'type': 'string'},
          ],
        },
        'primaryType': 'Mail',
        'domain': {
          'name': 'Ether Mail',
          'version': '1',
          'chainId': 1,
          'verifyingContract': '0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC',
        },
        'message': {'contents': 'Hello'},
      };
      final r = parseWalletConnectEthSignTypedDataV4(
        [wallet, typed],
        wallet,
        chainId,
      );
      expect(r.rootMap['primaryType'], 'Mail');
      expect(jsonDecode(r.jsonForSigning)['primaryType'], 'Mail');
    });

    test('parses [address, typedData json string]', () {
      final typed = {
        'types': {
          'EIP712Domain': [
            {'name': 'name', 'type': 'string'},
            {'name': 'version', 'type': 'string'},
            {'name': 'chainId', 'type': 'uint256'},
            {'name': 'verifyingContract', 'type': 'address'},
          ],
          'Mail': [
            {'name': 'contents', 'type': 'string'},
          ],
        },
        'primaryType': 'Mail',
        'domain': {
          'name': 'Ether Mail',
          'version': '1',
          'chainId': 1,
          'verifyingContract': '0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC',
        },
        'message': {'contents': 'Hello'},
      };
      final jsonStr = jsonEncode(typed);
      final r = parseWalletConnectEthSignTypedDataV4(
        [wallet, jsonStr],
        wallet,
        chainId,
      );
      expect(r.jsonForSigning.trim(), jsonStr);
    });

    test('rejects domain chainId mismatch', () {
      final typed = {
        'types': {
          'EIP712Domain': [
            {'name': 'name', 'type': 'string'},
            {'name': 'version', 'type': 'string'},
            {'name': 'chainId', 'type': 'uint256'},
            {'name': 'verifyingContract', 'type': 'address'},
          ],
          'Mail': [
            {'name': 'contents', 'type': 'string'},
          ],
        },
        'primaryType': 'Mail',
        'domain': {
          'name': 'Ether Mail',
          'version': '1',
          'chainId': 137,
          'verifyingContract': '0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC',
        },
        'message': {'contents': 'Hello'},
      };
      expect(
        () => parseWalletConnectEthSignTypedDataV4(
          [wallet, typed],
          wallet,
          chainId,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('accepts hex string domain chainId matching wallet chain', () {
      final typed = {
        'types': {
          'EIP712Domain': [
            {'name': 'name', 'type': 'string'},
            {'name': 'version', 'type': 'string'},
            {'name': 'chainId', 'type': 'uint256'},
            {'name': 'verifyingContract', 'type': 'address'},
          ],
          'Mail': [
            {'name': 'contents', 'type': 'string'},
          ],
        },
        'primaryType': 'Mail',
        'domain': {
          'name': 'Ether Mail',
          'version': '1',
          'chainId': '0x1',
          'verifyingContract': '0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC',
        },
        'message': {'contents': 'Hello'},
      };
      final r = parseWalletConnectEthSignTypedDataV4(
        [wallet, typed],
        wallet,
        1,
      );
      expect(readEip712DomainChainId(r.rootMap), 1);
    });
  });

  group('EIP-712 V4 signature (eth_sig_util_plus)', () {
    test('matches package reference vector for Mint721 typed data', () {
      const privateKey =
          '4af1bceebf7f3634ec3cff8a2c38e51178d5d4ce585c52d6043e5e2cc3418bb0';
      const json =
          r'''{"types":{"EIP712Domain":[{"type":"string","name":"name"},{"type":"string","name":"version"},{"type":"uint256","name":"chainId"},{"type":"address","name":"verifyingContract"}],"Part":[{"name":"account","type":"address"},{"name":"value","type":"uint96"}],"Mint721":[{"name":"tokenId","type":"uint256"},{"name":"tokenURI","type":"string"},{"name":"creators","type":"Part[]"},{"name":"royalties","type":"Part[]"}]},"domain":{"name":"Mint721","version":"1","chainId":4,"verifyingContract":"0x2547760120aed692eb19d22a5d9ccfe0f7872fce"},"primaryType":"Mint721","message":{"@type":"ERC721","contract":"0x2547760120aed692eb19d22a5d9ccfe0f7872fce","tokenId":"1","uri":"ipfs://ipfs/hash","creators":[{"account":"0xc5eac3488524d577a1495492599e8013b1f91efa","value":10000}],"royalties":[],"tokenURI":"ipfs://ipfs/hash"}}''';

      final signature = EthSigUtil.signTypedData(
        privateKey: privateKey,
        jsonData: json,
        version: TypedDataVersion.V4,
      );
      expect(
        signature,
        '0x2ce14898e255b8d1e5f296a293548607720951e507a5416a0515baef0420984f2e28df8824206db9dbab0e7f5b14eeb834d48ada4444e5f15e7bfd777d2069481c',
      );
    });
  });
}
