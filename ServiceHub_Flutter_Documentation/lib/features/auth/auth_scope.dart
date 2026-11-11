import 'package:flutter/widgets.dart';

import '../../core/network/api_client.dart';
import 'models/auth_user.dart';

/// Makes the signed-in user and logout action available to mobile screens.
class AuthScope extends InheritedWidget {
  const AuthScope({
    required this.user,
    required this.logout,
    required this.updateUser,
    required this.api,
    required super.child,
    super.key,
  });

  final AuthUser user;
  final Future<void> Function() logout;
  final void Function(AuthUser user) updateUser;
  final ApiClient api;

  static AuthScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope is missing above this widget');
    return scope!;
  }

  @override
  bool updateShouldNotify(AuthScope oldWidget) => oldWidget.user != user;
}
