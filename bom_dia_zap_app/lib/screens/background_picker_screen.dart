import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/image_item.dart';
import '../services/api_service.dart';
import 'custom_editor_screen.dart';

/// Tela 1 do editor premium: escolher um fundo sem legenda do banco de
/// imagens (usa `sourceUrl`, a foto original antes de qualquer frase ser
/// desenhada em cima).
class BackgroundPickerScreen extends StatefulWidget {
  const BackgroundPickerScreen({super.key});

  @override
  State<BackgroundPickerScreen> createState() =>
      _BackgroundPickerScreenState();
}

class _BackgroundPickerScreenState extends State<BackgroundPickerScreen> {
  final _api = ApiService();
  final _scrollController = ScrollController();

  final List<ImageItem> _images = [];
  int _page = 1;
  bool _hasMore = true;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNextPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final threshold = _scrollController.position.maxScrollExtent - 300;
    if (_scrollController.position.pixels >= threshold) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _api.getImages(page: _page);

      setState(() {
        _images.addAll(result.data);
        _hasMore = result.hasMore;
        _page++;
      });
    } catch (e) {
      setState(() => _error = 'Não foi possível carregar os fundos.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escolha um fundo')),
      body: _images.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _images.isEmpty && _error != null
              ? Center(child: Text(_error!))
              : GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _images.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _images.length) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final image = _images[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  CustomEditorScreen(background: image),
                            ),
                          );
                        },
                        child: CachedNetworkImage(
                          imageUrl: image.sourceUrl ?? image.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
