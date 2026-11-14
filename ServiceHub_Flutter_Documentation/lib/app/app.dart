import 'package:flutter/material.dart';

import '../core/services/fcm_service.dart';
import '../design_system/app_theme.dart';
import '../features/auth/auth_gate.dart';
import '../features/auth/services/auth_service.dart';

class ServiceHubApp extends StatefulWidget {
  const ServiceHubApp({super.key, this.authService});

  final AuthService? authService;

  @override
  State<ServiceHubApp> createState() => _ServiceHubAppState();
}

class _ServiceHubAppState extends State<ServiceHubApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    FcmService.navigatorKey = _navigatorKey;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'ServiceHub',
      theme: AppTheme.light,
      home: AuthGate(authService: widget.authService),
    );
  }
}
