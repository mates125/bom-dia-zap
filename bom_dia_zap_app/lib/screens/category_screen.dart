import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/image_item.dart';
import '../services/api_service.dart';
import '../widgets/image_tile.dart';
import 'image_viewer_screen.dart';

class CategoryScreen extends StatefulWidget {
  final Category category;

  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
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
      final result = await _api.getImages(
        categorySlug: widget.category.slug,
        page: _page,
      );

      setState(() {
        _images.addAll(result.data);
        _hasMore = result.hasMore;
        _page++;
      });
    } catch (e) {
      setState(() => _error = 'Não foi possível carregar as imagens.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
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
                ),
    );
  }
}
