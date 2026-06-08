import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBG0waBYiL5ttrBPy_7IXWzfouVJiG8LQ8',
    appId: '1:890432799040:web:6f8348ca1e69fb5cd4faa5',
    messagingSenderId: '890432799040',
    projectId: 'kizzuancien-159ee',
    authDomain: 'kizzuancien-159ee.firebaseapp.com',
    storageBucket: 'kizzuancien-159ee.firebasestorage.app',
    measurementId: 'G-BH597TCRZ1',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDWEmWBN_Cwmw_f9jw80nEj8_fX3zdOia4',
    appId: '1:890432799040:android:1666d3937dc2d635d4faa5',
    messagingSenderId: '890432799040',
    projectId: 'kizzuancien-159ee',
    storageBucket: 'kizzuancien-159ee.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDWEmWBN_Cwmw_f9jw80nEj8_fX3zdOia4',
    appId: '1:890432799040:ios:808a0d786d79fb5cd4faa5', // Guessed ID, ideally from plist
    messagingSenderId: '890432799040',
    projectId: 'kizzuancien-159ee',
    storageBucket: 'kizzuancien-159ee.firebasestorage.app',
    iosBundleId: 'com.example.kizzuAncien',
  );
}
