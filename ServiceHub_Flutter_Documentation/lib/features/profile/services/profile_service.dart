import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/models/auth_user.dart';

class ProfileService {
  ProfileService(this._api);

  final ApiClient _api;

  Future<AuthUser> load() async {
    return _user(await _api.get('/api/users/me'));
  }

  Future<AuthUser> update({
    required String fullName,
    required String phone,
    required String profileImageUrl,
  }) async {
    return _user(
      await _api.put(
        '/api/users/me',
        body: {
          'fullName': fullName.trim(),
          'phone': _blankToNull(phone),
          'profileImageUrl': _blankToNull(profileImageUrl),
        },
      ),
    );
  }

  String? _blankToNull(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  AuthUser _user(Map<String, dynamic> json) {
    try {
      return AuthUser.fromJson(json);
    } on FormatException {
      throw ApiException(
        message: 'The server returned an unexpected response.',
      );
    } on TypeError {
      throw ApiException(
        message: 'The server returned an unexpected response.',
      );
    }
  }
}
