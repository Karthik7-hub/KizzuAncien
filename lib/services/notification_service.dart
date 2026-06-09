import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../main.dart';
import '../providers/challenge_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/friend_provider.dart';
import '../providers/navigation_provider.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          final context = navigatorKey.currentContext;
          if (context == null) return;
          
          // Basic routing logic based on payload
          // Usually payload would be a JSON string
          if (details.payload!.contains('challenge')) {
             context.read<NavigationProvider>().setIndex(1);
          } else if (details.payload!.contains('friend')) {
             context.read<NavigationProvider>().setIndex(2);
          }
        }
      },
    );

    // Create Notification Channel for high-priority updates
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'kizzu_channel',
      'KizzuAncien Notifications',
      description: 'Challenges, friends, and community updates',
      importance: Importance.max,
      playSound: true,
      showBadge: true,
      enableVibration: true,
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
      // Automatic Refresh Logic
      _triggerDataRefresh(message.data['type']);
      
      // The user specified: "If the app is open and visible, do not show a system notification."
      // So we do NOT call _notificationsPlugin.show() here.
    });

    // 2. App opened from notification (from background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _triggerDataRefresh(message.data['type']);
    });
  }

  static void _triggerDataRefresh(String? type) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    // Always refresh notifications
    context.read<NotificationProvider>().fetchNotifications();

    final List<String> challengeTypes = [
      'challenge_received',
      'challenge_update',
      'submission_received',
      'challenge_approved',
      'challenge_rejected'
    ];

    final List<String> friendTypes = [
      'friend_request',
      'friend_accept',
      'friend_request_accepted'
    ];

    if (type != null) {
      if (challengeTypes.contains(type)) {
        context.read<ChallengeProvider>().fetchChallenges();
      } else if (friendTypes.contains(type)) {
        context.read<FriendProvider>().fetchFriends();
      }
    }
  }

  static Future<void> setupFcmToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _updateTokenOnServer(token);
      }

      // Listen to token refreshes
      _messaging.onTokenRefresh.listen((newToken) async {
        await _updateTokenOnServer(newToken);
      });
    } catch (e) {
      // Silently fail token setup
    }
  }

  static Future<void> _updateTokenOnServer(String token) async {
    try {
      final apiService = ApiService();
      await apiService.dio.put('/users/fcm-token', data: {'fcmToken': token});
    } catch (e) {
      // Silently fail server update (likely not logged in)
    }
  }

  static Future<bool> requestPermissions() async {
    // Android 13+ permission for local notifications
    final bool? androidGranted = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // FCM Permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final bool granted = (androidGranted ?? false) || 
                         settings.authorizationStatus == AuthorizationStatus.authorized ||
                         settings.authorizationStatus == AuthorizationStatus.provisional;

    return granted;
  }

  static Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
  }) async {
    return _notificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'kizzu_channel',
          'KizzuAncien Notifications',
          channelDescription: 'Challenges, friends, and community updates',
          importance: Importance.max,
          priority: Priority.max,
          ticker: 'ticker',
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
            summaryText: 'KizzuAncien',
          ),
          color: const Color(0xFF000000),
          ledColor: const Color(0xFFFFFFFF),
          ledOnMs: 1000,
          ledOffMs: 500,
          enableLights: true,
          icon: 'ic_notification',
          visibility: NotificationVisibility.public,
          groupKey: 'com.example.kizzu_ancien.NOTIFICATIONS',
        ),
      ),
      payload: payload,
    );
  }
}
