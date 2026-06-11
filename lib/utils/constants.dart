class AppConstants {
  // Update this with the Web Client ID from Firebase Console > Authentication > Google > Web SDK configuration
  static const String googleServerClientId = '890432799040-034h4cv0mk0qu605hiibu7t14tnphacr.apps.googleusercontent.com';
  
  // API URLs
  static const String productionBaseUrl = 'https://kizzu-ancien.vercel.app/api';
  static const String developmentBaseUrl = String.fromEnvironment(
    'DEV_API_URL',
    defaultValue: 'http://localhost:5000/api',
  );

  static String get apiBaseUrl {
    const isDev = bool.fromEnvironment('IS_DEV', defaultValue: false);
    return isDev ? developmentBaseUrl : productionBaseUrl;
  }

  // Environment Flags
  static bool get isDevMode => bool.fromEnvironment('IS_DEV', defaultValue: false);
}
