import 'dart:convert';
import 'package:http/http.dart' as http;

class PushNotificationDispatcher {
  static const String serverKey =
      'YOUR_FCM_SERVER_KEY'; // Replace with your real key

  static Future<void> sendNotification({
    required String title,
    required String body,
    required String fcmToken,
    required Map<String, dynamic> dataPayload,
  }) async {
    final message = {
      'to': fcmToken,
      'notification': {
        'title': title,
        'body': body,
      },
      'data': dataPayload,
    };

    final res = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body: jsonEncode(message),
    );

    print("🔔 FCM Response (${res.statusCode}): ${res.body}");
  }
}
