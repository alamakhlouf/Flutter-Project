import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../core/network/api_exception.dart';
import 'auth_scope.dart';
import 'models/auth_user.dart';
import 'screens/admin_blocked_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/session_error_screen.dart';
import 'screens/session_home_screen.dart';
import 'screens/session_loading_screen.dart';
import 'services/auth_service.dart';

enum _SessionGate { loading, signedOut, ready, adminBlocked, offline }

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, this.authService});

  final AuthService? authService;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthService _auth;
  late final bool _ownsAuth;
  var _gate = _SessionGate.loading;
  var _restoreInFlight = false;
  AuthUser? _user;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ownsAuth = widget.authService == null;
    _auth = widget.authService ?? AuthService();
    _auth.onSessionExpired = _onSessionExpired;
    _restore();
  }

  @override
  void dispose() {
    _auth.onSessionExpired = null;
    if (_ownsAuth) _auth.dispose();
    super.dispose();
  }

  Future<void> _restore({bool showLoading = false}) async {
    if (_restoreInFlight) return;
    _restoreInFlight = true;
    if (showLoading && mounted) {
      setState(() {
        _gate = _SessionGate.loading;
        _error = null;
      });
    }
    try {
      final user = await _auth.restore();
      if (!mounted) return;
      setState(() => _show(user));
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _gate = _SessionGate.offline;
        _error = error.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _gate = _SessionGate.offline;
        _error = 'Unable to restore your session. Check your connection and try again.';
      });
    } finally {
      _restoreInFlight = false;
    }
  }

  void _show(AuthUser? user) {
    _user = user;
    _error = null;
    if (user == null) {
      _gate = _SessionGate.signedOut;
    } else if (!user.role.canUseMobile) {
      _gate = _SessionGate.adminBlocked;
    } else {
      _gate = _SessionGate.ready;
    }
  }

  void _enter(AuthUser user) {
    setState(() => _show(user));
  }

  void _updateUser(AuthUser user) {
    _auth.currentUser = user;
    setState(() => _user = user);
  }

  void _onSessionExpired() {
    _signOut();
  }

  Future<void> _signOut() async {
    await _auth.logout();
    if (!mounted) return;
    setState(() => _show(null));
  }

  @override
  Widget build(BuildContext context) {
    return switch (_gate) {
      _SessionGate.loading => const SessionLoadingScreen(
        key: ValueKey(AppRoutes.sessionLoading),
      ),
      _SessionGate.offline => SessionErrorScreen(
        key: const ValueKey(AppRoutes.sessionError),
        message: _error ?? 'Unable to restore your session.',
        onRetry: () => _restore(showLoading: true),
        onLogout: _signOut,
      ),
      _SessionGate.adminBlocked => AdminBlockedScreen(
        key: const ValueKey(AppRoutes.adminBlocked),
        email: _user?.email ?? '',
        onLogout: _signOut,
      ),
      _SessionGate.ready => AuthScope(
        user: _user!,
        logout: _signOut,
        updateUser: _updateUser,
        api: _auth.api,
        child: const SessionHomeScreen(),
      ),
      _SessionGate.signedOut => _SignedOutFlow(
        authService: _auth,
        onAuthenticated: _enter,
      ),
    };
  }
}

class _SignedOutFlow extends StatelessWidget {
  const _SignedOutFlow({
    required this.authService,
    required this.onAuthenticated,
  });

  final AuthService authService;
  final ValueChanged<AuthUser> onAuthenticated;

  Route<void> _loginRoute() {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.login),
      builder: (context) => LoginScreen(
        authService: authService,
        onAuthenticated: onAuthenticated,
      ),
    );
  }

  Route<void> _registerRoute() {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.register),
      builder: (context) => RegisterScreen(
        authService: authService,
        onAuthenticated: onAuthenticated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: AppRoutes.login,
      onGenerateInitialRoutes: (navigator, initialRoute) => [_loginRoute()],
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.register) return _registerRoute();
        return _loginRoute();
      },
    );
  }
}
