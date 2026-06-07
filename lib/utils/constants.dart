import 'package:flutter/foundation.dart';

class AppConstants {
  static const String googleClientId = '810588370637-mskurpf4hcii6dtgn3oo1qrf7mh11mt0.apps.googleusercontent.com';
  
  // API URLs
  static const String webBaseUrl = 'http://127.0.0.1:5000/api';
  static const String androidBaseUrl = 'http://10.0.2.2:5000/api';
  static const String productionBaseUrl = 'https://api.kizzuancien.com/api'; // Replace with actual prod URL

  static String get apiBaseUrl {
    if (kReleaseMode) {
      return productionBaseUrl;
    }
    if (kIsWeb) {
      return webBaseUrl;
    }
    return androidBaseUrl;
  }
}
