import 'dart:convert';
import 'package:http/http.dart' as http;
import 'nft_gallery_screen.dart';

class OpenSeaNFTService {
  static const String baseUrl = 'https://api.opensea.io/api/v2';
  final String? apiKey;

  OpenSeaNFTService({this.apiKey});

  Future<List<NFTItem>> fetchNFTs(String ownerAddress) async {
    final url = Uri.parse('$baseUrl/chain/ethereum/account/$ownerAddress/nfts');
    final headers = <String, String>{};
    if (apiKey != null) {
      headers['x-api-key'] = apiKey!;
    }
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List assets = data['nfts'] ?? [];
      return assets.map<NFTItem>((nft) {
        final metadata = nft['metadata'] ?? {};
        return NFTItem(
          name: metadata['name'] ?? nft['name'] ?? 'NFT',
          imageUrl: metadata['image'] ?? metadata['image_url'] ?? '',
          collection: nft['collection']?['name'] ?? 'Unknown',
          tokenId: nft['token_id'] ?? nft['identifier'] ?? '',
        );
      }).toList();
    } else {
      throw Exception('Failed to fetch NFTs: ${response.body}');
    }
  }
}
