import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../services/notification_service.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  NotificationService? _service;
  int _unreadCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_service == null) {
      _service = NotificationService(api: AuthScope.of(context).api);
      _loadUnreadCount();
    }
  }

  Future<void> _loadUnreadCount() async {
    final count = await _service!.fetchUnreadCount();
    if (!mounted) return;
    setState(() => _unreadCount = count);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: 'Notifications',
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () async {
            await Navigator.of(context).pushNamed(AppRoutes.notifications);
            _loadUnreadCount();
          },
        ),
        if (_unreadCount > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _unreadCount > 9 ? '9+' : '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
