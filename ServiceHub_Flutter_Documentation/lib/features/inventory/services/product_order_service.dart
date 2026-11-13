import '../../../core/network/api_client.dart';
import '../models/product_order_model.dart';

class ProductOrderService {
  ProductOrderService({required this.api});

  final ApiClient api;

  Future<List<ProductOrderModel>> fetchMyOrders() async {
    final response = await api.getJson('/api/orders/my', authenticated: true);
    final raw = response is List
        ? response
        : response is Map
        ? response['content'] ?? response['items']
        : null;
    if (raw is! List) {
      throw const FormatException('Unexpected orders response');
    }
    return raw
        .map(
          (item) => ProductOrderModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<ProductOrderModel> fetchOrder(String id) async {
    return ProductOrderModel.fromJson(
      await api.get('/api/orders/$id', authenticated: true),
    );
  }

  Future<ProductOrderModel> updateStatus(
    String id,
    ProductOrderStatus status,
  ) async {
    return ProductOrderModel.fromJson(
      await api.patch(
        '/api/orders/$id/status',
        body: {'status': status.label},
        authenticated: true,
      ),
    );
  }

  Future<ProductOrderModel> cancel(String id) async {
    return ProductOrderModel.fromJson(
      await api.patch('/api/orders/$id/cancel', authenticated: true),
    );
  }
}
