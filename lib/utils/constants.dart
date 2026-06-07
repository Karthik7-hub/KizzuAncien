import 'package:flutter/foundation.dart';

class AppConstants {
  // Use the WEB Client ID here for the serverClientId handshake
  static const String googleServerClientId = '916502954681-6rbq7esb6llrbnuratf00acg0s1vfaav.apps.googleusercontent.com';
  
  // API URLs
  static const String productionBaseUrl = 'https://kizzu-ancien.vercel.app/api';

  static String get apiBaseUrl {
    return productionBaseUrl;
  }
}
