import 'package:flutter/widgets.dart';

class AuthKeys {
  const AuthKeys._();

  static const loginEmail = Key('login_email');
  static const loginPassword = Key('login_password');
  static const loginSubmit = Key('login_submit');
  static const createAccount = Key('create_account');
  static const registerName = Key('register_name');
  static const registerEmail = Key('register_email');
  static const registerPassword = Key('register_password');
  static const registerConfirm = Key('register_confirm');
  static const registerSubmit = Key('register_submit');
  static const logout = Key('logout');
  static const retrySession = Key('retry_session');
}
