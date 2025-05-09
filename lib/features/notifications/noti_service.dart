import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level background message handler
/// Must be a top-level function to handle messages when app is in background/terminated
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final notiService = NotiService._privateConstructor();
  await notiService._initPlugin();
  await notiService.showNotification(
    id: message.hashCode,
    title: message.notification?.title,
    body: message.notification?.body,
  );
}

class NotiService {
  // Singleton pattern
  NotiService._privateConstructor();
  static final NotiService _instance = NotiService._privateConstructor();
  factory NotiService() => _instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize notifications and FCM handlers
  Future<void> initNotification() async {
    if (_initialized) return;

    await _initPlugin();

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await showNotification(
        id: message.hashCode,
        title: message.notification?.title,
        body: message.notification?.body,
      );
    });

    // Notification tap (when app in background and opened via notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle navigation or other logic on tap
      // e.g. Navigator.of(navigatorKey.currentContext!).pushNamed('/moderationQueue', arguments: message.data);
    });

    // Optionally handle initial message if app was launched by tap
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      // Handle initial tap
      // e.g. Navigator.of(navigatorKey.currentContext!).pushNamed('/moderationQueue', arguments: initialMessage.data);
    }

    _initialized = true;
  }

  /// Internal plugin initialization
  Future<void> _initPlugin() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle local notification tap
        // e.g. Navigator.of(navigatorKey.currentContext!).pushNamed('/moderationQueue');
      },
    );
  }

  /// Build notification details (channel, importance, etc.)
  NotificationDetails _buildNotificationDetails() {
    const androidChannel = AndroidNotificationDetails(
      'mod_notifications',
      'Moderation Alerts',
      channelDescription: 'Notifications for flagged content',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosChannel = DarwinNotificationDetails();
    return const NotificationDetails(
      android: androidChannel,
      iOS: iosChannel,
    );
  }

  /// Show a local notification
  Future<void> showNotification({
    required int id,
    String? title,
    String? body,
  }) async {
    await _notificationsPlugin.show(
      id,
      title,
      body,
      _buildNotificationDetails(),
    );
  }
}
