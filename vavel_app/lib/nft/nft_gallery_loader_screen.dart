import 'package:flutter/material.dart';
import 'emerald_nft_gallery_theme.dart';
import 'nft_gallery_screen.dart';
import 'opensea_nft_service.dart';

class NFTGalleryLoaderScreen extends StatefulWidget {
  final String ownerAddress;
  final String? openseaApiKey;
  const NFTGalleryLoaderScreen(
      {super.key, required this.ownerAddress, this.openseaApiKey});

  @override
  State<NFTGalleryLoaderScreen> createState() => _NFTGalleryLoaderScreenState();
}

class _NFTGalleryLoaderScreenState extends State<NFTGalleryLoaderScreen> {
  late final OpenSeaNFTService nftService;
  late Future<List<NFTItem>> nftsFuture;

  @override
  void initState() {
    super.initState();
    nftService = OpenSeaNFTService(apiKey: widget.openseaApiKey);
    nftsFuture = nftService.fetchNFTs(widget.ownerAddress);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: EmeraldNFTGalleryTheme.theme,
      home: Scaffold(
        appBar: AppBar(title: const Text('NFT Галерея')),
        body: FutureBuilder<List<NFTItem>>(
          future: nftsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                  child: Text('Ошибка: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red)));
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              return NFTGalleryScreen(nfts: snapshot.data!);
            } else {
              return const Center(child: Text('NFT не найдены'));
            }
          },
        ),
      ),
    );
  }
}
