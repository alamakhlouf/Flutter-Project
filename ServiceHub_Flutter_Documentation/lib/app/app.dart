import 'package:flutter/material.dart';

import '../design_system/app_theme.dart';
import '../features/auth/auth_gate.dart';
import '../features/auth/services/auth_service.dart';

class ServiceHubApp extends StatelessWidget {
  const ServiceHubApp({super.key, this.authService});

  final AuthService? authService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ServiceHub',
      theme: AppTheme.light,
      home: AuthGate(authService: authService),
    );
  }
}
