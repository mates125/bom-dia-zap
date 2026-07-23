import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../models/image_item.dart';
import '../utils/save_image.dart';

class ImageViewerScreen extends StatefulWidget {
  final ImageItem image;

  const ImageViewerScreen({super.key, required this.image});

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  bool _isBusy = false;

  String get _filename => 'bom-dia-zap-${widget.image.id}.jpg';

  Future<Uint8List> _downloadBytes() async {
    final response = await http.get(Uri.parse(widget.image.imageUrl));

    if (response.statusCode != 200) {
      throw Exception('Falha ao baixar imagem');
    }

    return response.bodyBytes;
  }

  Future<void> _handleDownload() async {
    setState(() => _isBusy = true);

    try {
      final bytes = await _downloadBytes();
      await saveImageBytes(bytes, _filename);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagem salva!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar a imagem.')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _handleShare() async {
    setState(() => _isBusy = true);

    try {
      final bytes = await _downloadBytes();

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'image/jpeg',
              name: _filename,
            ),
          ],
          text: widget.image.title,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível compartilhar a imagem.')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: widget.image.imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isBusy ? null : _handleDownload,
                      icon: const Icon(Icons.download_rounded, color: Colors.white),
                      label: const Text('Baixar', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isBusy ? null : _handleShare,
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Compartilhar'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
