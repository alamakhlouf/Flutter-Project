import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/service_model.dart';

class ServicesService {
  ServicesService({required this.api});

  final ApiClient api;

  /// Fetches active services catalog supporting optional search query, category, max price, and location.
  Future<List<ServiceModel>> fetchCatalog({
    String? search,
    String? category,
    double? maxPrice,
    String? location,
  }) async {
    final queryParams = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (category != null && category.trim().isNotEmpty && category != 'All') {
      queryParams['category'] = category.trim();
    }
    if (maxPrice != null && maxPrice > 0) {
      queryParams['maxPrice'] = maxPrice.toString();
    }
    if (location != null && location.trim().isNotEmpty) {
      queryParams['location'] = location.trim();
    }

    final path = queryParams.isEmpty
        ? '/api/services'
        : '/api/services?${Uri(queryParameters: queryParams).query}';

    final response = await api.get(path, authenticated: true);
    return _parseList(response);
  }

  /// Fetches services owned by the current authenticated service provider.
  Future<List<ServiceModel>> fetchMyServices() async {
    final response = await api.get('/api/services/my', authenticated: true);
    return _parseList(response);
  }

  /// Fetches detailed information for a single service by ID.
  Future<ServiceModel> getServiceById(String id) async {
    final response = await api.get('/api/services/$id', authenticated: true);
    return ServiceModel.fromJson(response);
  }

  Future<ServiceModel> favoriteService(String id) async {
    final response = await api.post(
      '/api/services/$id/favorite',
      authenticated: true,
    );
    return ServiceModel.fromJson(response);
  }

  Future<void> unfavoriteService(String id) async {
    await api.delete('/api/services/$id/favorite', authenticated: true);
  }

  Future<List<ServiceModel>> fetchFavorites() async {
    final response = await api.getJson('/api/services/favorites', authenticated: true);
    if (response is List) {
      return response
          .whereType<Map>()
          .map((item) => ServiceModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    if (response is Map) {
      final rawList = response['content'] ?? response['items'] ?? response['data'];
      if (rawList is List) {
        return rawList
            .whereType<Map>()
            .map((item) => ServiceModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    }
    return <ServiceModel>[];
  }

  /// Creates a new service for the authenticated provider.
  Future<ServiceModel> createService({
    required String title,
    required String description,
    required String category,
    double? price,
    String? priceDescription,
    String? location,
    String? imageUrl,
    bool isActive = true,
  }) async {
    final body = <String, dynamic>{
      'title': title.trim(),
      'description': description.trim(),
      'category': category.trim(),
      if (price != null) 'price': price,
      if (priceDescription != null && priceDescription.trim().isNotEmpty)
        'priceDescription': priceDescription.trim(),
      if (location != null && location.trim().isNotEmpty)
        'location': location.trim(),
      if (imageUrl != null && imageUrl.trim().isNotEmpty)
        'imageUrl': imageUrl.trim(),
      'isActive': isActive,
    };

    final response = await api.post(
      '/api/services',
      body: body,
      authenticated: true,
    );
    return ServiceModel.fromJson(response);
  }

  /// Updates an existing service owned by the authenticated provider.
  Future<ServiceModel> updateService({
    required String id,
    required String title,
    required String description,
    required String category,
    double? price,
    String? priceDescription,
    String? location,
    String? imageUrl,
    required bool isActive,
  }) async {
    final body = <String, dynamic>{
      'id': id,
      'title': title.trim(),
      'description': description.trim(),
      'category': category.trim(),
      'price': price,
      'priceDescription': priceDescription?.trim(),
      'location': location?.trim(),
      'imageUrl': imageUrl?.trim(),
      'isActive': isActive,
    };

    final response = await api.put(
      '/api/services/$id',
      body: body,
      authenticated: true,
    );
    return ServiceModel.fromJson(response);
  }

  /// Toggles the active status of a service owned by the provider.
  Future<ServiceModel> toggleServiceActive({
    required String id,
    required bool isActive,
  }) async {
    final response = await api.patch(
      '/api/services/$id/status',
      body: {'isActive': isActive},
      authenticated: true,
    );
    return ServiceModel.fromJson(response);
  }

  /// Deletes a service owned by the provider.
  Future<void> deleteService(String id) async {
    await api.delete('/api/services/$id', authenticated: true);
  }

  List<ServiceModel> _parseList(Map<String, dynamic> response) {
    final rawList = response['content'] ??
        response['services'] ??
        response['items'] ??
        response['data'];

    if (rawList is List) {
      return rawList
          .map((item) {
            if (item is Map<String, dynamic>) {
              return ServiceModel.fromJson(item);
            }
            if (item is Map) {
              return ServiceModel.fromJson(Map<String, dynamic>.from(item));
            }
            return null;
          })
          .whereType<ServiceModel>()
          .toList();
    }

    // If root payload itself is a single object or empty
    if (response.containsKey('id')) {
      return [ServiceModel.fromJson(response)];
    }

    return <ServiceModel>[];
  }
}
