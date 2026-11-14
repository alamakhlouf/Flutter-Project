import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/image_picker_helper.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/image_renderer.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/models/auth_user.dart';
import '../../auth/widgets/auth_widgets.dart';
import '../profile_keys.dart';
import '../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    required this.user,
    required this.profileService,
    super.key,
  });

  final AuthUser user;
  final ProfileService profileService;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _imageController;
  var _autovalidate = AutovalidateMode.disabled;
  var _saving = false;
  String? _error;

  bool get _isSupplier => widget.user.role == UserRole.supplier;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _imageController = TextEditingController(
      text: widget.user.profileImageUrl ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  String _sectionTitle(UserRole role) {
    return switch (role) {
      UserRole.customer => 'Personal details',
      UserRole.provider => 'Professional details',
      UserRole.supplier => 'Business details',
      UserRole.admin => 'Account details',
    };
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _isSupplier
          ? 'Enter your business name.'
          : 'Enter your full name.';
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await widget.profileService.update(
        fullName: _nameController.text,
        phone: _phoneController.text,
        profileImageUrl: _imageController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Something went wrong. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = widget.user.role;
    return Scaffold(
      key: const ValueKey(AppRoutes.editProfile),
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                autovalidateMode: _autovalidate,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _sectionTitle(widget.user.role),
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Email and role stay the same.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_error != null) ...[
                      AuthErrorBanner(message: _error!),
                      const SizedBox(height: 16),
                    ],
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              key: ProfileKeys.name,
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              validator: _validateName,
                              decoration: InputDecoration(
                                labelText: _isSupplier
                                    ? 'Business name'
                                    : 'Full name',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              key: ProfileKeys.phone,
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              validator: Validators.phone,
                              decoration: const InputDecoration(
                                labelText: 'Phone',
                                hintText: 'Optional',
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _saving
                                  ? null
                                  : () async {
                                      final base64Image =
                                          await ImagePickerHelper.pickAndConvertToBase64(
                                        context,
                                      );
                                      if (base64Image != null && mounted) {
                                        setState(() {
                                          _imageController.text = base64Image;
                                        });
                                      }
                                    },
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Pick Image from Device'),
                            ),
                            const SizedBox(height: 12),
                            _ImagePreview(url: _imageController.text),
                            if (_imageController.text.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  key: ProfileKeys.removeImage,
                                  onPressed: _saving
                                      ? null
                                      : () {
                                          _imageController.clear();
                                          setState(() {});
                                        },
                                  child: const Text('Remove image'),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text('Email', style: theme.textTheme.labelMedium),
                            const SizedBox(height: 4),
                            Text(
                              widget.user.email,
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Email cannot be changed.',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 16),
                            Text('Role', style: theme.textTheme.labelMedium),
                            const SizedBox(height: 4),
                            Text(role.label, style: theme.textTheme.titleLarge),
                            const SizedBox(height: 4),
                            Text(
                              'Role cannot be changed.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AuthSubmitButton(
                      key: ProfileKeys.save,
                      label: 'Save changes',
                      loading: _saving,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final text = url.trim();
    if (text.isEmpty) {
      return const _ImageFrame(
        child: _ImageMessage(
          icon: Icons.image_outlined,
          message: 'No profile image',
        ),
      );
    }
    return _ImageFrame(
      child: ImageRenderer(
        imageUrl: text,
        placeholder: const _ImageMessage(
          icon: Icons.broken_image_outlined,
          message: 'Image could not be loaded.',
        ),
        fit: BoxFit.cover,
      ),
    );
  }
}

class _ImageFrame extends StatelessWidget {
  const _ImageFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0x14163B60)),
        child: SizedBox(height: 160, width: double.infinity, child: child),
      ),
    );
  }
}

class _ImageMessage extends StatelessWidget {
  const _ImageMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
