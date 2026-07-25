import 'package:flutter/material.dart';
import '../models/collection.dart';
import '../models/image_item.dart';
import '../services/api_service.dart';
import '../widgets/image_tile.dart';
import 'image_viewer_screen.dart';

class CollectionDetailScreen extends StatefulWidget {
  final Collection collection;

  const CollectionDetailScreen({super.key, required this.collection});

  @override
  State<CollectionDetailScreen> createState() =>
      _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  final _api = ApiService();
  late Future<List<ImageItem>> _imagesFuture;

  @override
  void initState() {
    super.initState();
    _imagesFuture = _load();
  }

  Future<List<ImageItem>> _load() async {
    final page = await _api.getCollectionImages(widget.collection.id);
    return page.data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.collection.name)),
      body: FutureBuilder<List<ImageItem>>(
        future: _imagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Não foi possível carregar: ${snapshot.error}'),
            );
          }

          final images = snapshot.data ?? [];

          if (images.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nenhuma imagem por aqui ainda.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              final image = images[index];
              return ImageTile(
                image: image,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ImageViewerScreen(image: image),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
