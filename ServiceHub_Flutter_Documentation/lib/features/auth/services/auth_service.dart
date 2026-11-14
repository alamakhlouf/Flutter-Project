import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../models/auth_user.dart';

/// Session access for the signed-in user. The JWT stays in [TokenStorage].
class AuthService {
  AuthService({
    TokenStorage? tokenStorage,
    http.Client? httpClient,
    String? baseUrl,
    GoogleSignIn? googleSignIn,
  })  : _ownsClient = httpClient == null,
        _storage = tokenStorage ?? SecureTokenStorage(),
        _client = httpClient ?? http.Client(),
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: ['email', 'profile'],
              serverClientId: const String.fromEnvironment(
                'GOOGLE_SERVER_CLIENT_ID',
                defaultValue:
                    '721746615689-31o7qo4p1rsu2s6ku9ako4galdjs064p.apps.googleusercontent.com',
              ),
            ) {
    _api = ApiClient(
      baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
      client: _client,
      readToken: _storage.read,
      onUnauthorized: () => onSessionExpired?.call(),
    );
  }

  final bool _ownsClient;
  final TokenStorage _storage;
  final http.Client _client;
  final GoogleSignIn _googleSignIn;
  late final ApiClient _api;

  ApiClient get api => _api;

  /// Called when an authenticated request is rejected. Login failures do not
  /// call this.
  void Function()? onSessionExpired;

  AuthUser? currentUser;

  Future<AuthUser?> restore() async {
    final token = await _storage.read();
    if (token == null || token.isEmpty) {
      currentUser = null;
      return null;
    }
    try {
      final body = await _api.get('/api/auth/me');
      final user = _parseUser(body);
      currentUser = user;
      return user;
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        currentUser = null;
        await _storage.clear();
        return null;
      }
      rethrow;
    }
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final body = await _api.post(
      '/api/auth/login',
      body: {'email': email.trim(), 'password': password},
    );
    return _persist(body);
  }

  Future<AuthUser> register({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    if (!role.canUseMobile) {
      throw ApiException(
        statusCode: 403,
        message: 'Administrator accounts cannot be created in the app.',
      );
    }
    final body = await _api.post(
      '/api/auth/register',
      body: {
        'fullName': fullName.trim(),
        'email': email.trim(),
        'password': password,
        'role': role.apiValue,
      },
    );
    return _persist(body);
  }

  /// Triggers Google Account selection flow and returns Google ID token + account.
  Future<GoogleSignInAccount?> selectGoogleAccount() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      throw ApiException(message: 'Google Sign-In failed: $e');
    }
  }

  Future<AuthUser> googleAuth({
    required String idToken,
    UserRole? role,
  }) async {
    final body = await _api.post(
      '/api/auth/google',
      body: {
        'idToken': idToken,
        if (role != null) 'role': role.apiValue,
      },
    );
    return _persist(body);
  }

  Future<void> logout() async {
    currentUser = null;
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _storage.clear();
  }

  void dispose() {
    onSessionExpired = null;
    if (_ownsClient) _client.close();
  }

  Future<AuthUser> _persist(Map<String, dynamic> body) async {
    final token = body['token'];
    final userJson = body['user'];
    if (token is! String || token.isEmpty || userJson is! Map) {
      throw ApiException(
        message: 'The server returned an unexpected response.',
      );
    }
    final user = _parseUser(Map<String, dynamic>.from(userJson));
    await _storage.write(token);
    currentUser = user;
    return user;
  }

  AuthUser _parseUser(Map<String, dynamic> json) {
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
