import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/image_item.dart';

class ImageTile extends StatelessWidget {
  final ImageItem image;
  final VoidCallback onTap;

  const ImageTile({super.key, required this.image, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        child: CachedNetworkImage(
          imageUrl: image.thumbnailUrl ?? image.imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          errorWidget: (context, url, error) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.broken_image_outlined),
          ),
        ),
      ),
    );
  }
}
