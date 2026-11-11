import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../auth_keys.dart';
import '../models/auth_user.dart';
import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    required this.authService,
    required this.onAuthenticated,
    super.key,
  });

  final AuthService authService;
  final ValueChanged<AuthUser> onAuthenticated;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _autovalidate = AutovalidateMode.disabled;
  var _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final user = await widget.authService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      widget.onAuthenticated(user);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Something went wrong. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in with your email and password.',
      child: Form(
        key: _formKey,
        autovalidateMode: _autovalidate,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                AuthErrorBanner(message: _error!),
                const SizedBox(height: 16),
              ],
              TextFormField(
                key: AuthKeys.loginEmail,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                autocorrect: false,
                validator: Validators.email,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'you@example.com',
                ),
              ),
              const SizedBox(height: 12),
              PasswordField(
                fieldKey: AuthKeys.loginPassword,
                controller: _passwordController,
                label: 'Password',
                autofillHints: const [AutofillHints.password],
                validator: Validators.password,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              AuthSubmitButton(
                key: AuthKeys.loginSubmit,
                label: 'Sign in',
                loading: _submitting,
                onPressed: _submit,
              ),
              const SizedBox(height: 8),
              TextButton(
                key: AuthKeys.createAccount,
                onPressed: _submitting
                    ? null
                    : () => Navigator.of(context).pushNamed(AppRoutes.register),
                child: const Text('Create an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
