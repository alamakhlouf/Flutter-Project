import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../auth_keys.dart';
import '../models/auth_user.dart';
import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    required this.authService,
    required this.onAuthenticated,
    super.key,
  });

  final AuthService authService;
  final ValueChanged<AuthUser> onAuthenticated;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  var _role = UserRole.customer;
  var _autovalidate = AutovalidateMode.disabled;
  var _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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
      final user = await widget.authService.register(
        fullName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        role: _role,
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
      title: 'Create your account',
      subtitle: 'Join as a customer, service provider, or supplier.',
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
                key: AuthKeys.registerName,
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.next,
                validator: Validators.fullName,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: AuthKeys.registerEmail,
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
                fieldKey: AuthKeys.registerPassword,
                controller: _passwordController,
                label: 'Password',
                hintText: 'At least 8 characters',
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: Validators.password,
              ),
              const SizedBox(height: 12),
              PasswordField(
                fieldKey: AuthKeys.registerConfirm,
                controller: _confirmController,
                label: 'Confirm password',
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) =>
                    Validators.confirmPassword(value, _passwordController.text),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              Text('I am a', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              RoleSelector(
                value: _role,
                onChanged: (role) => setState(() => _role = role),
              ),
              const SizedBox(height: 20),
              AuthSubmitButton(
                key: AuthKeys.registerSubmit,
                label: 'Create account',
                loading: _submitting,
                onPressed: _submit,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _submitting
                    ? null
                    : () => Navigator.of(context).maybePop(),
                child: const Text('I already have an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
