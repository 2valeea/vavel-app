import 'package:flutter/material.dart';
import 'emerald_nft_gallery_theme.dart';

class NFTItem {
  final String name;
  final String imageUrl;
  final String collection;
  final String tokenId;

  NFTItem({
    required this.name,
    required this.imageUrl,
    required this.collection,
    required this.tokenId,
  });
}

class NFTGalleryScreen extends StatelessWidget {
  final List<NFTItem> nfts;

  const NFTGalleryScreen({super.key, required this.nfts});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: EmeraldNFTGalleryTheme.theme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('NFT Галерея'),
          centerTitle: true,
        ),
        body: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: nfts.length,
          itemBuilder: (context, index) {
            final nft = nfts[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => _NFTDetailDialog(nft: nft),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        child: Image.network(
                          nft.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Colors.white24),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nft.name,
                            style: Theme.of(context).textTheme.titleLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            nft.collection,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NFTDetailDialog extends StatelessWidget {
  final NFTItem nft;
  const _NFTDetailDialog({required this.nft});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                nft.imageUrl,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image,
                    size: 48, color: Colors.white24),
              ),
            ),
            const SizedBox(height: 16),
            Text(nft.name, style: Theme.of(context).textTheme.titleLarge),
            Text(nft.collection, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text('Token ID: ${nft.tokenId}',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),
            ),
          ],
        ),
      ),
    );
  }
}
