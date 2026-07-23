import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/image_item.dart';

class ImagesPage {
  final List<ImageItem> data;
  final int page;
  final int totalPages;

  ImagesPage({required this.data, required this.page, required this.totalPages});

  bool get hasMore => page < totalPages;
}

class ApiService {
  // Backend local. Em produção isso vira uma URL configurável (build flavor
  // ou variável de ambiente) apontando pro servidor na nuvem.
  static const String baseUrl = 'http://localhost:3000';

  Future<List<Category>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'));

    if (response.statusCode != 200) {
      throw Exception('Falha ao carregar categorias');
    }

    final List<dynamic> body = jsonDecode(response.body) as List<dynamic>;
    return body
        .map((json) => Category.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ImagesPage> getImages({
    required String categorySlug,
    int page = 1,
    int limit = 20,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/images?category=$categorySlug&page=$page&limit=$limit',
    );
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Falha ao carregar imagens');
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;

    final List<dynamic> data = body['data'] as List<dynamic>;
    final Map<String, dynamic> meta = body['meta'] as Map<String, dynamic>;

    return ImagesPage(
      data: data
          .map((json) => ImageItem.fromJson(json as Map<String, dynamic>))
          .toList(),
      page: meta['page'] as int,
      totalPages: meta['totalPages'] as int,
    );
  }
}
