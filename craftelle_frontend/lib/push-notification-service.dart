import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

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
    debugPrint('FCM init called for role: $userRole (initialized=$_initialized, currentRole=$_currentRole)');
    if (_initialized && _currentRole == userRole) return;

    try {
      // Unsubscribe from old topic if switching roles
      if (_currentRole.isNotEmpty && _currentRole != userRole) {
        await _fcm.unsubscribeFromTopic('role_$_currentRole');
        debugPrint('FCM unsubscribed from old topic: role_$_currentRole');
      }

      _currentRole = userRole;

      // Request Android POST_NOTIFICATIONS permission explicitly
      // (firebase_messaging's requestPermission doesn't always trigger the dialog on Android)
      final notifPermission = await Permission.notification.request();
      debugPrint('Android notification permission: $notifPermission');

      // Set up background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Get FCM token for debugging
      final token = await _fcm.getToken();
      debugPrint('FCM token: ${token?.substring(0, 20)}...');

      // Subscribe to role-based topic
      await _fcm.subscribeToTopic('role_$userRole');
      debugPrint('FCM subscribed to topic: role_$userRole');

      // Set up local notifications for foreground display
      await _setupLocalNotifications();
      debugPrint('FCM local notifications set up');

      // Set up foreground message listener
      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('FCM foreground message received: ${message.notification?.title}');
        _handleForegroundMessage(message);
      });

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
    } catch (e, stack) {
      debugPrint('FCM init ERROR: $e');
      debugPrint('FCM init stack: $stack');
    }
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
    debugPrint('Notification tapped — navigating to notifications');
  }
}
