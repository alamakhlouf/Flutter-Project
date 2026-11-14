import '../../../core/network/api_client.dart';
import '../models/workshop_model.dart';

class WorkshopService {
  WorkshopService({required this.api});
  final ApiClient api;

  Future<List<WorkshopModel>> fetchWorkshops({
    String search = '',
    String category = '',
    bool availability = false,
  }) async {
    final params = <String>[
      if (search.trim().isNotEmpty) 'search=${Uri.encodeQueryComponent(search.trim())}',
      if (category.trim().isNotEmpty) 'category=${Uri.encodeQueryComponent(category.trim())}',
      if (availability) 'availability=true',
    ];
    final response = await api.getJson(
      '/api/workshops${params.isEmpty ? '' : '?${params.join('&')}'}',
      authenticated: true,
    );
    return _workshops(response);
  }

  Future<WorkshopModel> getWorkshop(String id) async =>
      WorkshopModel.fromJson(await api.get('/api/workshops/$id', authenticated: true));

  Future<List<WorkshopModel>> fetchOrganized() async =>
      _workshops(await api.getJson('/api/workshops/my/organized', authenticated: true));

  Future<List<WorkshopRegistration>> fetchMyRegistrations() async {
    final response = await api.getJson('/api/workshops/my/registrations', authenticated: true);
    final list = response is List ? response : (response as Map)['content'];
    if (list is! List) throw const FormatException('Unexpected registrations response');
    return list.map((item) => WorkshopRegistration.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  }

  Future<WorkshopRegistration> register(String id) async =>
      WorkshopRegistration.fromJson(await api.post('/api/workshops/$id/registrations', authenticated: true));

  Future<List<Map<String, dynamic>>> fetchParticipants(String id) async {
    final response = await api.getJson('/api/workshops/$id/participants', authenticated: true);
    if (response is! List) throw const FormatException('Unexpected participants response');
    return response.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> cancelRegistration(String id) =>
      api.delete('/api/workshops/$id/registrations/me', authenticated: true);

  Future<Map<String, dynamic>> checkGoogleStatus() async {
    final res = await api.getJson('/api/integrations/google/status', authenticated: true);
    return res is Map ? Map<String, dynamic>.from(res) : {};
  }

  Future<Map<String, dynamic>> connectGoogleToken({
    required String accessToken,
    String? email,
  }) async {
    final res = await api.post(
      '/api/integrations/google/token',
      authenticated: true,
      body: {
        'accessToken': accessToken,
        if (email != null && email.isNotEmpty) 'email': email,
      },
    );
    return Map<String, dynamic>.from(res);
  }

  Future<String> getGoogleConnectUrl() async {
    final res = await api.getJson('/api/integrations/google/connect', authenticated: true);
    if (res is Map && res['authUrl'] != null) {
      return res['authUrl'].toString();
    }
    throw const FormatException('Failed to get Google connect authorization URL');
  }

  Future<WorkshopModel> generateMeeting(String id) async {
    final res = await api.post('/api/workshops/$id/generate-meeting', authenticated: true);
    return WorkshopModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<WorkshopModel> create({
    required String title,
    required String description,
    required String category,
    required String location,
    required int capacity,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required DateTime registrationDeadline,
    String? coverImageUrl,
    String workshopType = 'IN_PERSON',
  }) async {
    final response = await api.post('/api/workshops', authenticated: true, body: _body(
      title: title, description: description, category: category, location: location,
      capacity: capacity, startDateTime: startDateTime, endDateTime: endDateTime,
      registrationDeadline: registrationDeadline, coverImageUrl: coverImageUrl,
      workshopType: workshopType,
    ));
    return WorkshopModel.fromJson(response);
  }

  Future<WorkshopModel> update(String id, {
    required String title,
    required String description,
    required String category,
    required String location,
    required int capacity,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required DateTime registrationDeadline,
    String? coverImageUrl,
    String workshopType = 'IN_PERSON',
  }) async {
    final response = await api.put('/api/workshops/$id', authenticated: true, body: _body(
      title: title, description: description, category: category, location: location,
      capacity: capacity, startDateTime: startDateTime, endDateTime: endDateTime,
      registrationDeadline: registrationDeadline, coverImageUrl: coverImageUrl,
      workshopType: workshopType,
    ));
    return WorkshopModel.fromJson(response);
  }

  Future<WorkshopModel> publish(String id) async =>
      WorkshopModel.fromJson(await api.patch('/api/workshops/$id/publish', authenticated: true));

  Future<WorkshopModel> cancel(String id) async =>
      WorkshopModel.fromJson(await api.patch('/api/workshops/$id/cancel', authenticated: true));

  List<WorkshopModel> _workshops(Object? response) {
    final list = response is List ? response : response is Map ? response['content'] : null;
    if (list is! List) throw const FormatException('Unexpected workshops response');
    return list.map((item) => WorkshopModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  }

  Map<String, dynamic> _body({
    required String title, required String description, required String category,
    required String location, required int capacity, required DateTime startDateTime,
    required DateTime endDateTime, required DateTime registrationDeadline, String? coverImageUrl,
    required String workshopType,
  }) => {
    'title': title.trim(), 'description': description.trim(), 'category': category.trim(),
    'location': location.trim(), 'capacity': capacity,
    'startDateTime': startDateTime.toUtc().toIso8601String(),
    'endDateTime': endDateTime.toUtc().toIso8601String(),
    'registrationDeadline': registrationDeadline.toUtc().toIso8601String(),
    'workshopType': workshopType.toUpperCase(),
    if (coverImageUrl != null && coverImageUrl.trim().isNotEmpty) 'coverImageUrl': coverImageUrl.trim(),
  };
}
