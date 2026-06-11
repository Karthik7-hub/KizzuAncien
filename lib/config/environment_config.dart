import '../utils/constants.dart';

class EnvironmentConfig {
  static String get apiBaseUrl => AppConstants.apiBaseUrl;
  
  static bool get isDev => AppConstants.isDevMode;

  static String get environmentName => isDev ? 'Development' : 'Production';

  // Helper to get descriptive status
  static String get connectionStatus {
    return 'Connected to $environmentName environment';
  }
}
