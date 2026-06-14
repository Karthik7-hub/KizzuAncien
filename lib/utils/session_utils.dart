import 'package:provider/provider.dart';
import '../providers/challenge_provider.dart';
import '../providers/friend_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/truth_dare_provider.dart';
import '../providers/navigation_provider.dart';
import '../main.dart';

class SessionUtils {
  static void clearAllData() {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    try {
      context.read<ChallengeProvider>().clear();
      context.read<FriendProvider>().clear();
      context.read<NotificationProvider>().clear();
      context.read<TruthDareProvider>().clear();
      context.read<NavigationProvider>().reset();
    } catch (e) {
      // Some providers might not be initialized yet
    }
  }
}
