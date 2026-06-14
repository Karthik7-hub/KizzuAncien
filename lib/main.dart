import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:kizzu_ancien/providers/auth_provider.dart';
import 'package:kizzu_ancien/providers/challenge_provider.dart';
import 'package:kizzu_ancien/providers/friend_provider.dart';
import 'package:kizzu_ancien/providers/truth_dare_provider.dart';
import 'package:kizzu_ancien/providers/notification_provider.dart';
import 'package:kizzu_ancien/providers/navigation_provider.dart';
import 'package:kizzu_ancien/screens/splash_screen.dart';
import 'package:kizzu_ancien/theme/app_theme.dart';
import 'package:kizzu_ancien/services/notification_service.dart';
import 'package:kizzu_ancien/utils/logger.dart';
import 'firebase_options.dart';

import 'package:kizzu_ancien/providers/theme_provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    // Already initialized
  }
  AppLogger.info("Background Message Received: ${message.messageId}");
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  // Ensure the binding is initialized for the first frame
  WidgetsFlutterBinding.ensureInitialized();
  
  // We run the app IMMEDIATELY to show the splash screen.
  // Async initializations are moved to the app lifecycle or splash screen.
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChallengeProvider()),
        ChangeNotifierProvider(create: (_) => FriendProvider()),
        ChangeNotifierProvider(create: (_) => TruthDareProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: const KizzuAncienApp(),
    ),
  );
}

class KizzuAncienApp extends StatefulWidget {
  const KizzuAncienApp({super.key});

  @override
  State<KizzuAncienApp> createState() => _KizzuAncienAppState();
}

class _KizzuAncienAppState extends State<KizzuAncienApp> {
  @override
  void initState() {
    super.initState();
    // Initialize services in the background without blocking the first frame
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      await NotificationService.init();
    } catch (e) {
      AppLogger.error('Startup initialization failed', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    
    return MaterialApp(
      title: 'KizzuAncien',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
    );
  }
}
