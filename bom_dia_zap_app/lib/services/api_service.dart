import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/collection.dart';
import '../models/image_item.dart';
import 'auth_service.dart';

class ImagesPage {
  final List<ImageItem> data;
  final int page;
  final int totalPages;

  ImagesPage({required this.data, required this.page, required this.totalPages});

  bool get hasMore => page < totalPages;
}

class CollectionLimitException implements Exception {
  final String message;

  CollectionLimitException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  // Backend rodando no Railway. Quando existirem builds de verdade (dev/
  // staging/prod), isso vira configurável por --dart-define em vez de
  // fixo aqui.
  static const String baseUrl = 'https://bom-dia-zap-production.up.railway.app';

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
    String? categorySlug,
    int page = 1,
    int limit = 20,
    bool withSourceUrl = false,
  }) async {
    final categoryParam = categorySlug != null ? '&category=$categorySlug' : '';
    final sourceUrlParam = withSourceUrl ? '&withSourceUrl=true' : '';
    final uri = Uri.parse(
      '$baseUrl/images?page=$page&limit=$limit$categoryParam$sourceUrlParam',
    );
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Falha ao carregar imagens');
    }

    return _parseImagesPage(response.body);
  }

  Future<bool> getLikeStatus(int imageId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/images/$imageId/like'),
      headers: authService.authHeaders,
    );

    if (response.statusCode != 200) {
      return false;
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['isLiked'] as bool? ?? false;
  }

  Future<void> likeImage(int imageId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/images/$imageId/like'),
      headers: authService.authHeaders,
    );

    if (response.statusCode >= 400) {
      throw Exception('Falha ao curtir a imagem');
    }
  }

  Future<void> unlikeImage(int imageId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/images/$imageId/like'),
      headers: authService.authHeaders,
    );

    if (response.statusCode >= 400) {
      throw Exception('Falha ao descurtir a imagem');
    }
  }

  /// TEMPORÁRIO: liga/desliga premium na conta logada, só pra testar o editor
  /// antes do Google Play Billing existir. Remover junto com o endpoint.
  Future<void> toggleDevPremium() async {
    final response = await http.patch(
      Uri.parse('$baseUrl/auth/dev-toggle-premium'),
      headers: authService.authHeaders,
    );

    if (response.statusCode >= 400) {
      throw Exception('Falha ao alternar premium (teste)');
    }
  }

  Future<List<Collection>> getCollections() async {
    final response = await http.get(
      Uri.parse('$baseUrl/collections'),
      headers: authService.authHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao carregar coleções');
    }

    final List<dynamic> body = jsonDecode(response.body) as List<dynamic>;
    return body
        .map((json) => Collection.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> addImageToCollection(int collectionId, int imageId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/collections/$collectionId/images'),
      headers: {
        ...authService.authHeaders,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'imageId': imageId}),
    );

    if (response.statusCode >= 400) {
      throw Exception('Falha ao adicionar à coleção');
    }
  }

  Future<void> createCollection(String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/collections'),
      headers: {
        ...authService.authHeaders,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode == 403) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw CollectionLimitException(
        body['message']?.toString() ?? 'Limite de coleções atingido.',
      );
    }

    if (response.statusCode >= 400) {
      throw Exception('Falha ao criar a coleção');
    }
  }

  Future<ImagesPage> getCollectionImages(
    int collectionId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/collections/$collectionId/images?page=$page&limit=$limit'),
      headers: authService.authHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao carregar imagens da coleção');
    }

    return _parseImagesPage(response.body);
  }

  ImagesPage _parseImagesPage(String responseBody) {
    final Map<String, dynamic> body =
        jsonDecode(responseBody) as Map<String, dynamic>;

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
