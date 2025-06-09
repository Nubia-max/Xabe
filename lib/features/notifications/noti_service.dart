import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Replace this with your actual VAPID key from Firebase Console
const String vapidKey =
    'BLPIXv8hj_x-3TcTgfyghndxu2SiltbjnE7KZIC0vJ7qXNEThTITDWy6XYOiemlpb8yiVCmI5Ugv-ltzcyUBNHQ';

/// Top-level background handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotiService().init();

  NotiService().showNotification(
    id: message.hashCode,
    title: message.notification?.title,
    body: message.notification?.body,
  );
}

class NotiService {
  NotiService._privateConstructor();
  static final NotiService _instance = NotiService._privateConstructor();
  factory NotiService() => _instance;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // iOS and macOS permissions
    if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    }
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _flutterLocalNotificationsPlugin.initialize(initSettings);

    // Get FCM token
    await _logTokens();

    // Foreground handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showNotification(
          id: message.hashCode,
          title: message.notification!.title,
          body: message.notification!.body,
        );
      }
    });

    // Background handler (already registered in main)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _logTokens() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken(
        vapidKey: kIsWeb ? vapidKey : null,
      );
      debugPrint("🔑 FCM Token: $token");

      if (!kIsWeb && Platform.isIOS) {
        String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        debugPrint("📱 APNs Token: $apnsToken");
      }
    } catch (e) {
      debugPrint("❌ Error getting FCM/APNs token: $e");
    }
  }

  void showNotification({
    required int id,
    required String? title,
    required String? body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'General Notifications',
      channelDescription: 'Used for basic community notifications',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }
}
