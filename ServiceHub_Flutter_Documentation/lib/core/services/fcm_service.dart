import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../design_system/app_colors.dart';
import '../network/api_client.dart';

class FcmService {
  const FcmService._();

  static GlobalKey<NavigatorState>? navigatorKey;
  static final GlobalKey<NavigatorState> sessionNavigatorKey =
      GlobalKey<NavigatorState>();
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static RemoteMessage? _pendingNavigationMessage;
  static bool _messageListenersRegistered = false;

  static Future<void> initialize(ApiClient api) async {
    _registerMessageListeners();

    final messaging = FirebaseMessaging.instance;
    try {
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageNavigation(initialMessage);
      }
    } catch (e) {
      debugPrint('[FCM] Failed to read initial message: $e');
    }

    NotificationSettings settings;
    try {
      settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('[FCM] Permission request failed: $e');
      return;
    }

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      _tokenRefreshSubscription ??= messaging.onTokenRefresh.listen((newToken) {
        _registerToken(api, newToken).ignore();
      });

      try {
        final token = await messaging.getToken();
        if (token != null && token.isNotEmpty) {
          await _registerToken(api, token);
        }
      } catch (e) {
        debugPrint('[FCM] Failed to retrieve registration token: $e');
      }
    }
  }

  static void _registerMessageListeners() {
    if (_messageListenersRegistered) return;
    _messageListenersRegistered = true;
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageNavigation);
  }

  static void flushPendingNavigation() {
    final message = _pendingNavigationMessage;
    if (message == null || sessionNavigatorKey.currentState == null) return;
    _pendingNavigationMessage = null;
    _handleMessageNavigation(message);
  }

  static Future<void> unregister(ApiClient api) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await api.delete(
          '/api/notifications/device-token',
          body: {'token': token},
        );
      }
    } catch (e) {
      debugPrint('[FCM] Unregister token error: $e');
    }
  }

  static Future<void> _registerToken(ApiClient api, String token) async {
    try {
      await api.post(
        '/api/notifications/device-token',
        body: {'token': token},
        authenticated: true,
      );
    } catch (e) {
      debugPrint('[FCM] Failed to register token on backend: $e');
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final context = navigatorKey?.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          backgroundColor: AppColors.primary,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.title ?? 'Notification',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (notification.body != null) Text(notification.body!),
            ],
          ),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () => _handleMessageNavigation(message),
          ),
        ),
      );
    }
  }

  static void _handleMessageNavigation(RemoteMessage message) {
    final data = message.data;
    final entityType = data['relatedEntityType']?.toString().toUpperCase();
    final entityId = data['relatedEntityId']?.toString();

    final navState = sessionNavigatorKey.currentState;
    if (navState == null) {
      _pendingNavigationMessage = message;
      return;
    }

    if (entityId != null && entityId.isNotEmpty) {
      if (entityType == 'BOOKING') {
        navState.pushNamed(AppRoutes.bookingDetails, arguments: entityId);
      } else if (entityType == 'ORDER') {
        navState.pushNamed(AppRoutes.productOrderDetails, arguments: entityId);
      } else if (entityType == 'WORKSHOP') {
        navState.pushNamed(AppRoutes.workshopDetails, arguments: entityId);
      } else {
        navState.pushNamed(AppRoutes.notifications);
      }
    } else {
      navState.pushNamed(AppRoutes.notifications);
    }
  }
}
