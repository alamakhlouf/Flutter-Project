import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../design_system/app_colors.dart';
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

  Future<void> _googleSubmit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final googleAccount = await widget.authService.selectGoogleAccount();
      if (googleAccount == null) {
        if (mounted) setState(() => _submitting = false);
        return;
      }
      final googleAuthData = await googleAccount.authentication;
      final idToken = googleAuthData.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw ApiException(message: 'Failed to retrieve Google ID Token.');
      }

      AuthUser? user;
      try {
        user = await widget.authService.googleAuth(idToken: idToken);
      } on ApiException catch (e) {
        if (e.message == 'ROLE_REQUIRED_FOR_NEW_USER' && mounted) {
          final selectedRole = await showGoogleRoleSelectionDialog(context);
          if (selectedRole == null) {
            setState(() => _submitting = false);
            return;
          }
          user = await widget.authService.googleAuth(
            idToken: idToken,
            role: selectedRole,
          );
        } else {
          rethrow;
        }
      }

      if (!mounted || user == null) return;
      widget.onAuthenticated(user);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error.message;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Google Sign-In error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Welcome Back',
      subtitle: 'Sign in to access your services, orders & workshops.',
      child: Form(
        key: _formKey,
        autovalidateMode: _autovalidate,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                AuthErrorBanner(message: _error!),
                const SizedBox(height: 20),
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
                  labelText: 'Email Address',
                  hintText: 'you@example.com',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PasswordField(
                fieldKey: AuthKeys.loginPassword,
                controller: _passwordController,
                label: 'Password',
                autofillHints: const [AutofillHints.password],
                validator: Validators.password,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              AuthSubmitButton(
                key: AuthKeys.loginSubmit,
                label: 'Sign In',
                loading: _submitting,
                onPressed: _submit,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              const SizedBox(height: 16),
              GoogleSignInButton(
                label: 'Continue with Google',
                loading: _submitting,
                onPressed: _googleSubmit,
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  TextButton(
                    key: AuthKeys.createAccount,
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context)
                            .pushNamed(AppRoutes.register),
                    child: const Text(
                      'Create account',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
