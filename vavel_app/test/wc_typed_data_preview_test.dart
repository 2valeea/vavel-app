import 'package:flutter_test/flutter_test.dart';
import 'package:vavel_app/walletconnect/wc_typed_data_preview.dart';

void main() {
  group('buildTypedDataHumanPreview', () {
    test('detects Permit2 PermitSingle', () {
      final root = {
        'types': {
          'EIP712Domain': [
            {'name': 'name', 'type': 'string'},
            {'name': 'chainId', 'type': 'uint256'},
            {'name': 'verifyingContract', 'type': 'address'},
          ],
          'PermitDetails': [
            {'name': 'token', 'type': 'address'},
            {'name': 'amount', 'type': 'uint160'},
            {'name': 'expiration', 'type': 'uint48'},
            {'name': 'nonce', 'type': 'uint48'},
          ],
          'PermitSingle': [
            {'name': 'details', 'type': 'PermitDetails'},
            {'name': 'spender', 'type': 'address'},
            {'name': 'sigDeadline', 'type': 'uint256'},
          ],
        },
        'primaryType': 'PermitSingle',
        'domain': {
          'name': 'Permit2',
          'chainId': 1,
          'verifyingContract': '0x000000000022D473030F116dDEE9F6B43aC78BA3',
        },
        'message': {
          'details': {
            'token': '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
            'amount': '1000',
            'expiration': '9999999999',
            'nonce': '0',
          },
          'spender': '0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45',
          'sigDeadline': '9999999999',
        },
      };
      final h = buildTypedDataHumanPreview(root);
      expect(h.kind, TypedDataPreviewKind.permit2);
      expect(h.headline, contains('Permit2'));
      expect(h.bullets.any((b) => b.contains('Spender')), isTrue);
    });

    test('detects SafeTx', () {
      final root = {
        'types': {
          'EIP712Domain': [
            {'name': 'chainId', 'type': 'uint256'},
            {'name': 'verifyingContract', 'type': 'address'},
          ],
          'SafeTx': [
            {'name': 'to', 'type': 'address'},
            {'name': 'value', 'type': 'uint256'},
            {'name': 'data', 'type': 'bytes'},
            {'name': 'operation', 'type': 'uint8'},
            {'name': 'safeTxGas', 'type': 'uint256'},
            {'name': 'baseGas', 'type': 'uint256'},
            {'name': 'gasPrice', 'type': 'uint256'},
            {'name': 'gasToken', 'type': 'address'},
            {'name': 'refundReceiver', 'type': 'address'},
            {'name': 'nonce', 'type': 'uint256'},
          ],
        },
        'primaryType': 'SafeTx',
        'domain': {'chainId': 1, 'verifyingContract': '0x1234567890123456789012345678901234567890'},
        'message': {
          'to': '0xabcdefabcdefabcdefabcdefabcdefabcdefabcd',
          'value': '0',
          'data': '0x',
          'operation': '0',
          'safeTxGas': '0',
          'baseGas': '0',
          'gasPrice': '0',
          'gasToken': '0x0000000000000000000000000000000000000000',
          'refundReceiver': '0x0000000000000000000000000000000000000000',
          'nonce': '5',
        },
      };
      final h = buildTypedDataHumanPreview(root);
      expect(h.kind, TypedDataPreviewKind.safeTx);
      expect(h.headline, contains('Safe'));
      expect(h.bullets.any((b) => b.contains('nonce')), isTrue);
    });

    test('detects EIP-2612 Permit', () {
      final root = {
        'types': {
          'EIP712Domain': [
            {'name': 'name', 'type': 'string'},
            {'name': 'version', 'type': 'string'},
            {'name': 'chainId', 'type': 'uint256'},
            {'name': 'verifyingContract', 'type': 'address'},
          ],
          'Permit': [
            {'name': 'owner', 'type': 'address'},
            {'name': 'spender', 'type': 'address'},
            {'name': 'value', 'type': 'uint256'},
            {'name': 'nonce', 'type': 'uint256'},
            {'name': 'deadline', 'type': 'uint256'},
          ],
        },
        'primaryType': 'Permit',
        'domain': {
          'name': 'Mock',
          'version': '1',
          'chainId': 1,
          'verifyingContract': '0x2222222222222222222222222222222222222222',
        },
        'message': {
          'owner': '0x3333333333333333333333333333333333333333',
          'spender': '0x4444444444444444444444444444444444444444',
          'value': '1000000000000000000',
          'nonce': '0',
          'deadline': '2000000000',
        },
      };
      final h = buildTypedDataHumanPreview(root);
      expect(h.kind, TypedDataPreviewKind.permitEip2612);
      expect(h.headline, contains('EIP-2612'));
    });

    test('PermitSingle amount uses token decimals when provided', () {
      final root = {
        'types': {
          'EIP712Domain': [
            {'name': 'name', 'type': 'string'},
            {'name': 'chainId', 'type': 'uint256'},
            {'name': 'verifyingContract', 'type': 'address'},
          ],
          'PermitDetails': [
            {'name': 'token', 'type': 'address'},
            {'name': 'amount', 'type': 'uint160'},
            {'name': 'expiration', 'type': 'uint48'},
            {'name': 'nonce', 'type': 'uint48'},
          ],
          'PermitSingle': [
            {'name': 'details', 'type': 'PermitDetails'},
            {'name': 'spender', 'type': 'address'},
            {'name': 'sigDeadline', 'type': 'uint256'},
          ],
        },
        'primaryType': 'PermitSingle',
        'domain': {
          'name': 'Permit2',
          'chainId': 1,
          'verifyingContract': '0x000000000022D473030F116dDEE9F6B43aC78BA3',
        },
        'message': {
          'details': {
            'token': '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
            'amount': '1000000',
            'expiration': '9999999999',
            'nonce': '0',
          },
          'spender': '0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45',
          'sigDeadline': '9999999999',
        },
      };
      final addrs = erc20AddressesForTypedDataPreview(root);
      expect(addrs, contains('0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'));
      final h = buildTypedDataHumanPreview(
        root,
        tokenDecimalsByLowerAddress: {
          '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48': 6,
        },
      );
      final amountLine = h.bullets.firstWhere((b) => b.startsWith('Amount:'));
      expect(amountLine, contains('1'));
      expect(amountLine, contains('smallest units'));
    });

    test('EIP-2612 allowance uses verifyingContract decimals', () {
      final root = {
        'types': {
          'EIP712Domain': [
            {'name': 'name', 'type': 'string'},
            {'name': 'version', 'type': 'string'},
            {'name': 'chainId', 'type': 'uint256'},
            {'name': 'verifyingContract', 'type': 'address'},
          ],
          'Permit': [
            {'name': 'owner', 'type': 'address'},
            {'name': 'spender', 'type': 'address'},
            {'name': 'value', 'type': 'uint256'},
            {'name': 'nonce', 'type': 'uint256'},
            {'name': 'deadline', 'type': 'uint256'},
          ],
        },
        'primaryType': 'Permit',
        'domain': {
          'name': 'Mock',
          'version': '1',
          'chainId': 1,
          'verifyingContract': '0x2222222222222222222222222222222222222222',
        },
        'message': {
          'owner': '0x3333333333333333333333333333333333333333',
          'spender': '0x4444444444444444444444444444444444444444',
          'value': '1000000000000000000',
          'nonce': '0',
          'deadline': '2000000000',
        },
      };
      final h = buildTypedDataHumanPreview(
        root,
        tokenDecimalsByLowerAddress: {
          '0x2222222222222222222222222222222222222222': 18,
        },
      );
      final line = h.bullets.firstWhere((b) => b.startsWith('Allowance:'));
      expect(line, contains('1'));
      expect(line, contains('tokens'));
    });
  });

  group('formatTokenAmountForPreview', () {
    test('formats with decimals', () {
      expect(
        formatTokenAmountForPreview('1000000', 6),
        contains('1'),
      );
      expect(formatTokenAmountForPreview('1000000', 6), contains('smallest units'));
    });

    test('falls back when decimals missing', () {
      expect(
        formatTokenAmountForPreview('99', null),
        contains('unavailable'),
      );
    });
  });
}
