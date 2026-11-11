import 'package:flutter/material.dart';

import '../../../design_system/app_colors.dart';

class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({
    required this.name,
    this.imageUrl,
    this.size = 96,
    super.key,
  });

  final String name;
  final String? imageUrl;
  final double size;

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  var _failed = false;

  @override
  void didUpdateWidget(ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) _failed = false;
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.imageUrl?.trim() ?? '';
    return Semantics(
      label: 'Profile image',
      child: Column(
        children: [
          if (url.isEmpty)
            _initial(context)
          else
            ClipOval(
              child: Image.network(
                url,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Semantics(
                    label: 'Loading image',
                    child: _circle(
                      child: const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.surface,
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  if (!_failed) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _failed = true);
                    });
                  }
                  return _initial(context);
                },
              ),
            ),
          if (_failed) ...[
            const SizedBox(height: 8),
            Text(
              'Profile image could not be loaded.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _initial(BuildContext context) {
    final trimmed = widget.name.trim();
    final letter = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
    return _circle(
      child: Text(
        letter,
        style: Theme.of(context).textTheme.headlineLarge
            ?.copyWith(color: AppColors.surface),
      ),
    );
  }

  Widget _circle({required Widget child}) {
    return Container(
      width: widget.size,
      height: widget.size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: child,
    );
  }
}

class ProfileNotice extends StatelessWidget {
  const ProfileNotice({
    required this.message,
    required this.color,
    required this.icon,
    super.key,
  });

  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
