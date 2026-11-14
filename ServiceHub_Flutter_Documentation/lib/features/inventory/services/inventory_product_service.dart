import '../../../core/network/api_client.dart';
import '../models/inventory_product_model.dart';

class InventoryProductService {
  InventoryProductService({required this.api});

  final ApiClient api;

  Future<List<InventoryProduct>> fetchAvailable({String? search}) async {
    final query = search?.trim();
    final path = query == null || query.isEmpty
        ? '/api/products'
        : '/api/products?${Uri(queryParameters: {'search': query}).query}';
    return _parseList(await api.get(path, authenticated: true));
  }

  Future<List<InventoryProduct>> fetchMyProducts() async {
    return _parseList(await api.get('/api/products/my'));
  }

  Future<InventoryProduct> fetchProduct(String id) async {
    final response = await api.get('/api/products/$id', authenticated: true);
    return InventoryProduct.fromJson(response);
  }

  Future<InventoryProduct> saveProduct({
    String? id,
    required String name,
    required String category,
    required double price,
    String? imageUrl,
    required String description,
    required int? quantityAvailable,
    required bool available,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
      'category': category.trim(),
      'price': price,
      'imageUrl': imageUrl?.trim().isEmpty == true ? null : imageUrl?.trim(),
      'description': description.trim(),
      'quantityAvailable': quantityAvailable,
      'available': available,
    };
    final response = id == null
        ? await api.post('/api/products', body: body, authenticated: true)
        : await api.put('/api/products/$id', body: body, authenticated: true);
    return InventoryProduct.fromJson(response);
  }

  Future<InventoryProduct> setAvailability(String id, bool available) async {
    final response = await api.patch(
      '/api/products/$id/availability',
      body: {'available': available},
      authenticated: true,
    );
    return InventoryProduct.fromJson(response);
  }

  Future<void> deleteProduct(String id) async {
    await api.delete('/api/products/$id', authenticated: true);
  }

  Future<void> buyProduct(String productId, int quantity) async {
    await api.post(
      '/api/orders',
      body: {
        'items': [
          {'productId': productId, 'quantity': quantity},
        ],
      },
      authenticated: true,
    );
  }

  Future<InventoryProduct> favoriteProduct(String id) async {
    final response = await api.post(
      '/api/products/$id/favorite',
      authenticated: true,
    );
    return InventoryProduct.fromJson(response);
  }

  Future<void> unfavoriteProduct(String id) async {
    await api.delete('/api/products/$id/favorite', authenticated: true);
  }

  Future<List<InventoryProduct>> fetchFavorites() async {
    final response = await api.getJson('/api/products/favorites', authenticated: true);
    if (response is List) {
      return response
          .whereType<Map>()
          .map((item) => InventoryProduct.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    if (response is Map) {
      final rawList = response['content'] ?? response['items'] ?? response['data'];
      if (rawList is List) {
        return rawList
            .whereType<Map>()
            .map((item) => InventoryProduct.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    }
    return <InventoryProduct>[];
  }

  List<InventoryProduct> _parseList(Map<String, dynamic> response) {
    final rawList =
        response['content'] ?? response['items'] ?? response['data'];
    if (rawList is! List) return <InventoryProduct>[];
    return rawList
        .where((item) => item is Map)
        .map(
          (item) => InventoryProduct.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }
}
