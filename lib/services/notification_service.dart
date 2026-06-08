import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Standard launcher icon fallback

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
  }) async {
    return _notificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'kizzu_channel',
          'KizzuAncien',
          channelDescription: 'System and community updates',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.status,
          icon: 'ic_notification',
          colorized: false,
          showWhen: true,
          enableVibration: true,
          styleInformation: BigTextStyleInformation(''),
          groupKey: 'com.example.kizzu_ancien.NOTIFICATIONS',
        ),
      ),
    );
  }
}
