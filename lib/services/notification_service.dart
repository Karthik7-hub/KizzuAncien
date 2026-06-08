import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    // Create Notification Channel for FCM
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'kizzu_channel',
      'KizzuAncien',
      description: 'System and community updates',
      importance: Importance.max,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Initialize FCM listeners
    _initFcm();
  }

  static void _initFcm() {
    // 1. Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 FCM Foreground Message: ${message.notification?.title}');
      
      // If app is in foreground, we might NOT want to show a system notification
      // (User specified: If the app is open and visible, do not show a system notification.)
      // So we do nothing here, or update the in-app state.
    });

    // 2. Background/Terminated message handler handled in main.dart (onBackgroundMessage)
    
    // 3. App opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 App opened from notification: ${message.data}');
      // Handle navigation if needed
    });
  }

  static Future<void> setupFcmToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('🔑 FCM Token: $token');
        await _updateTokenOnServer(token);
      }

      // Listen to token refreshes
      _messaging.onTokenRefresh.listen((newToken) async {
        await _updateTokenOnServer(newToken);
      });
    } catch (e) {
      debugPrint('❌ Error setting up FCM Token: $e');
    }
  }

  static Future<void> _updateTokenOnServer(String token) async {
    try {
      final apiService = ApiService();
      await apiService.dio.put('/users/fcm-token', data: {'fcmToken': token});
      debugPrint('✅ FCM Token updated on server');
    } catch (e) {
      debugPrint('⚠️ Could not update FCM Token on server (likely not logged in)');
    }
  }

  static Future<void> requestPermissions() async {
    // Android 13+ permission
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // FCM Permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('🔔 Notification Status: ${settings.authorizationStatus}');
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
          icon: '@mipmap/ic_launcher',
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
