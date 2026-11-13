import '../../../core/network/api_client.dart';
import '../models/report_model.dart';

class ReportService {
  ReportService({required this.api});

  final ApiClient api;

  Future<void> submit({
    required String targetType,
    required String targetId,
    required String reason,
    required String description,
  }) async {
    await api.post(
      '/api/reports',
      authenticated: true,
      body: {
        'targetType': targetType,
        'targetId': targetId,
        'reason': reason,
        'description': description.trim(),
      },
    );
  }

  Future<List<ReportModel>> myReports() async {
    final response = await api.getJson('/api/reports/my', authenticated: true);
    final raw = response is List
        ? response
        : response is Map
            ? response['content'] ?? response['items'] ?? response['data']
            : null;
    if (raw is! List) {
      throw const FormatException('Unexpected reports response');
    }
    return raw
        .map(
          (item) =>
              ReportModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<List<ReportModel>> fetchAdminReports({String? status}) async {
    final query = status != null && status.isNotEmpty && status != 'ALL'
        ? '?status=$status'
        : '';
    final response =
        await api.getJson('/api/admin/reports$query', authenticated: true);
    final raw = response is List
        ? response
        : response is Map
            ? response['content'] ?? response['items'] ?? response['data']
            : null;
    if (raw is! List) {
      throw const FormatException('Unexpected admin reports response');
    }
    return raw
        .map(
          (item) =>
              ReportModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<void> updateReportStatus(String reportId, String status) async {
    await api.patch(
      '/api/admin/reports/$reportId/status',
      authenticated: true,
      body: {'status': status},
    );
  }

  Future<void> blockUser(String userId) async {
    await api.patch(
      '/api/admin/users/$userId/block',
      authenticated: true,
      body: {'status': 'BLOCKED'},
    );
  }

  Future<void> deleteAdminService(String serviceId) async {
    await api.delete(
      '/api/admin/services/$serviceId',
      authenticated: true,
    );
  }
}
