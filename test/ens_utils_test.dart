import 'package:convert/convert.dart' as convert;
import 'package:flutter_test/flutter_test.dart';
import 'package:vavel_wallet/utils/ens_utils.dart';

void main() {
  test('ensNamehash(eth) matches canonical ENS namehash', () {
    const expectedHex =
        '93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae';
    final h = ensNamehash('eth');
    expect(convert.hex.encode(h), expectedHex);
  });

  test('looksLikeEnsName', () {
    expect(looksLikeEnsName('vitalik.eth'), true);
    expect(looksLikeEnsName('sub.vitalik.eth'), true);
    expect(looksLikeEnsName('0x1234'), false);
    expect(looksLikeEnsName('eth'), false);
    expect(looksLikeEnsName('.eth'), false);
  });
}
