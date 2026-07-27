import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../models/collection.dart';
import '../models/image_item.dart';
import '../services/ad_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/save_image.dart';
import 'login_screen.dart';

class ImageViewerScreen extends StatefulWidget {
  final ImageItem image;

  const ImageViewerScreen({super.key, required this.image});

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  final _api = ApiService();
  bool _isBusy = false;
  bool _isLiked = false;

  String get _filename => 'bom-dia-zap-${widget.image.id}.jpg';

  @override
  void initState() {
    super.initState();
    _loadLikeStatus();
  }

  Future<void> _loadLikeStatus() async {
    if (!authService.isLoggedIn) return;

    try {
      final isLiked = await _api.getLikeStatus(widget.image.id);
      if (mounted) setState(() => _isLiked = isLiked);
    } catch (_) {
      // mantém o estado padrão (não curtido) se a checagem falhar
    }
  }

  Future<void> _toggleLike() async {
    if (!authService.isLoggedIn) {
      final loggedIn = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (loggedIn != true || !mounted) return;
    }

    final wasLiked = _isLiked;
    setState(() => _isLiked = !wasLiked);

    try {
      if (wasLiked) {
        await _api.unlikeImage(widget.image.id);
      } else {
        await _api.likeImage(widget.image.id);
        AdService.instance.registerActionAndMaybeShow();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLiked = wasLiked);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível atualizar a curtida.')),
      );
    }
  }

  Future<void> _openAddToCollection() async {
    if (!authService.isLoggedIn) {
      final loggedIn = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (loggedIn != true || !mounted) return;
    }

    List<Collection> collections;
    try {
      collections = await _api.getCollections();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível carregar suas coleções.')),
      );
      return;
    }

    if (!mounted) return;

    final result = await showModalBottomSheet<Object>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Adicionar a uma coleção',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            for (final collection in collections)
              ListTile(
                leading: Icon(
                  collection.isDefault
                      ? Icons.favorite_rounded
                      : Icons.folder_rounded,
                ),
                title: Text(collection.name),
                onTap: () => Navigator.of(sheetContext).pop(collection),
              ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Nova coleção'),
              onTap: () => Navigator.of(sheetContext).pop('new'),
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;

    Collection? target;
    if (result is Collection) {
      target = result;
    } else if (result == 'new') {
      target = await _createCollectionAndReturn();
    }

    if (target == null || !mounted) return;

    try {
      await _api.addImageToCollection(target.id, widget.image.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Adicionada a "${target.name}"')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível adicionar à coleção.')),
      );
    }
  }

  Future<Collection?> _createCollectionAndReturn() async {
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Nova coleção'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Nome da coleção'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );

    if (name == null || name.isEmpty || !mounted) return null;

    try {
      await _api.createCollection(name);
      final collections = await _api.getCollections();
      return collections.firstWhere((c) => c.name == name);
    } on CollectionLimitException catch (e) {
      if (!mounted) return null;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Recurso premium'),
          content: Text(e.message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Entendi'),
            ),
          ],
        ),
      );
      return null;
    } catch (_) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível criar a coleção.')),
      );
      return null;
    }
  }

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
      AdService.instance.registerActionAndMaybeShow();

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
        ),
      );
      AdService.instance.registerActionAndMaybeShow();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add_rounded),
            tooltip: 'Adicionar a uma coleção',
            onPressed: _openAddToCollection,
          ),
          IconButton(
            icon: Icon(
              _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isLiked ? Colors.redAccent : Colors.white,
            ),
            onPressed: _toggleLike,
          ),
        ],
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
