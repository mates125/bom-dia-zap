import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/image_item.dart';
import '../services/api_service.dart';
import '../widgets/category_card.dart';
import 'category_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = ApiService();
  late Future<_HomeData> _homeDataFuture;

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _loadHomeData();
  }

  Future<_HomeData> _loadHomeData() async {
    final categories = await _api.getCategories();

    final previews = <String, ImageItem?>{};

    await Future.wait(
      categories.map((category) async {
        try {
          final page = await _api.getImages(
            categorySlug: category.slug,
            limit: 1,
          );
          previews[category.slug] =
              page.data.isNotEmpty ? page.data.first : null;
        } catch (_) {
          previews[category.slug] = null;
        }
      }),
    );

    return _HomeData(categories: categories, previews: previews);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bom Dia Zap'),
        centerTitle: false,
      ),
      body: FutureBuilder<_HomeData>(
        future: _homeDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Não foi possível carregar as categorias.\nVerifique se o backend está rodando.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final categories = snapshot.data?.categories ?? [];
          final previews = snapshot.data?.previews ?? {};

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.05,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return CategoryCard(
                category: category,
                previewImage: previews[category.slug],
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CategoryScreen(category: category),
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

class _HomeData {
  final List<Category> categories;
  final Map<String, ImageItem?> previews;

  _HomeData({required this.categories, required this.previews});
}
