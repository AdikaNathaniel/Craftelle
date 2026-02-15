import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

// Must be top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.notification?.title}');
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState>? navigatorKey;
  String _currentRole = '';
  bool _initialized = false;

  static const _channelId = 'craftelle_notifications';
  static const _channelName = 'Craftelle Notifications';
  static const _channelDescription = 'Notifications from Craftelle';

  Future<void> init(String userRole) async {
    if (_initialized && _currentRole == userRole) return;

    // Unsubscribe from old topic if switching roles
    if (_currentRole.isNotEmpty && _currentRole != userRole) {
      await _fcm.unsubscribeFromTopic('role_$_currentRole');
    }

    _currentRole = userRole;

    // Request permission
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Push notification permission denied');
      return;
    }

    // Set up local notifications for foreground display
    await _setupLocalNotifications();

    // Subscribe to role-based topic
    await _fcm.subscribeToTopic('role_$userRole');
    debugPrint('Subscribed to FCM topic: role_$userRole');

    // Set up background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground messages — show local notification banner
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Notification tap when app was terminated
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Set foreground notification presentation options (iOS)
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _initialized = true;
    debugPrint('Push notification service initialized for role: $userRole');
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        _navigateToNotifications();
      },
    );

    // Create the notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title ?? 'Craftelle',
      body: notification.body ?? '',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    _navigateToNotifications();
  }

  void _navigateToNotifications() {
    if (navigatorKey?.currentState == null) return;
    // Navigate to the notifications page
    // The app is already open, so we just need to ensure we're on the right page
    debugPrint('Notification tapped — navigating to notifications');
  }
}
