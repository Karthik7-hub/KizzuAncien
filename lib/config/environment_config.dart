import '../utils/constants.dart';

class EnvironmentConfig {
  static String get apiBaseUrl => AppConstants.apiBaseUrl;
  
  static bool get isDev => AppConstants.isDevMode;

  static String get environmentName => isDev ? 'Development' : 'Production';

  // Database configurations or other env-specific keys can be added here
}
