import '../../../core/network/api_client.dart';
import '../models/inventory_item_model.dart';

class InventoryService {
  InventoryService({required this.api});

  final ApiClient api;

  Future<List<InventoryItemModel>> fetchMyInventory() async {
    final response = await api.get('/api/inventory', authenticated: true);
    return _parseList(response);
  }

  Future<InventoryItemModel> createInventoryItem({
    required String name,
    required String description,
    required int quantity,
    required String unit,
    int? lowStockThreshold,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
      'description': description.trim(),
      'quantity': quantity,
      'unit': unit.trim(),
      'lowStockThreshold': lowStockThreshold,
    };

    final response = await api.post(
      '/api/inventory',
      body: body,
      authenticated: true,
    );
    return InventoryItemModel.fromJson(response);
  }

  Future<InventoryItemModel> updateInventoryItem({
    required String id,
    required String name,
    required String description,
    required int quantity,
    required String unit,
    int? lowStockThreshold,
  }) async {
    final body = <String, dynamic>{
      'id': id,
      'name': name.trim(),
      'description': description.trim(),
      'quantity': quantity,
      'unit': unit.trim(),
      'lowStockThreshold': lowStockThreshold,
    };

    final response = await api.put(
      '/api/inventory/$id',
      body: body,
      authenticated: true,
    );
    return InventoryItemModel.fromJson(response);
  }

  Future<InventoryItemModel> updateQuantity({
    required String id,
    required int quantity,
  }) async {
    final response = await api.patch(
      '/api/inventory/$id/quantity',
      body: {'quantity': quantity},
      authenticated: true,
    );
    return InventoryItemModel.fromJson(response);
  }

  Future<void> deleteInventoryItem(String id) async {
    await api.delete('/api/inventory/$id', authenticated: true);
  }

  List<InventoryItemModel> _parseList(Map<String, dynamic> response) {
    final rawList = response['content'] ??
        response['inventory'] ??
        response['items'] ??
        response['data'];

    if (rawList is List) {
      return rawList
          .map((item) {
            if (item is Map<String, dynamic>) {
              return InventoryItemModel.fromJson(item);
            }
            if (item is Map) {
              return InventoryItemModel.fromJson(Map<String, dynamic>.from(item));
            }
            return null;
          })
          .whereType<InventoryItemModel>()
          .toList();
    }

    if (response.containsKey('id')) {
      return [InventoryItemModel.fromJson(response)];
    }

    return <InventoryItemModel>[];
  }
}
