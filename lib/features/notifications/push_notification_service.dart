import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// 🔔 Initialize local notification + FCM listener
  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Show push when message is received while app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showNotification(
          title: message.notification!.title,
          body: message.notification!.body,
        );
      }
    });
  }

  /// 🟡 Show local notification while app is open
  static Future<void> sendNotification({
    required String title,
    required String body,
  }) async {
    _showNotification(title: title, body: body);
  }

  static Future<void> _showNotification({
    required String? title,
    required String? body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'default_channel',
      'General Notifications',
      channelDescription: 'This channel is used for general notifications.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    FirebaseMessaging.instance.getAPNSToken().then((apnsToken) {
      print("📱 APNs Token: $apnsToken");
    });

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'default',
    );
  }

  /// ✅ Send true remote FCM push via Firebase HTTP API
  static Future<void> sendRealFCMPush({
    required String title,
    required String body,
    required String topicOrToken, // "/topics/uid" or specific device token
  }) async {
    const String serverKey = 'YOUR_FCM_SERVER_KEY_HERE'; // 🔐 Replace this

    final response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body: jsonEncode({
        "to": topicOrToken,
        "notification": {
          "title": title,
          "body": body,
        },
        "priority": "high",
      }),
    );

    print("🔔 FCM push response: ${response.statusCode} - ${response.body}");
  }
}
