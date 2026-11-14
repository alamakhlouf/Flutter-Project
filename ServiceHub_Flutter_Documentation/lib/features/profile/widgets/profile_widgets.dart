import 'package:flutter/material.dart';

import '../../../core/widgets/image_renderer.dart';
import '../../../design_system/app_colors.dart';

class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({
    required this.name,
    this.imageUrl,
    this.size = 100,
    this.showBorder = true,
    super.key,
  });

  final String name;
  final String? imageUrl;
  final double size;
  final bool showBorder;

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
          Container(
            padding: EdgeInsets.all(widget.showBorder ? 4.0 : 0),
            decoration: widget.showBorder
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.18),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  )
                : null,
            child: url.isEmpty
                ? _initial(context)
                : ClipOval(
                    child: SizedBox(
                      width: widget.size,
                      height: widget.size,
                      child: ImageRenderer(
                        imageUrl: url,
                        placeholder: _initial(context),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
          ),
          if (_failed) ...[
            const SizedBox(height: 8),
            Text(
              'Profile image could not be loaded.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
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
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: AppColors.surface,
              fontWeight: FontWeight.bold,
              fontSize: widget.size * 0.4,
            ),
      ),
    );
  }

  Widget _circle({required Widget child}) {
    return Container(
      width: widget.size,
      height: widget.size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
