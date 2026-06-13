import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/app_header.dart';
import '../widgets/empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
      context.read<NotificationProvider>().markAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final notifications = notificationProvider.notifications;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: const AppHeader(
        title: 'Notifications',
        showBackButton: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => notificationProvider.fetchNotifications(),
        color: Theme.of(context).primaryColor,
        backgroundColor: Theme.of(context).cardTheme.color,
        child: notificationProvider.isLoading && notifications.isEmpty
            ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
            : notifications.isEmpty
                ? const EmptyState(
                    icon: LucideIcons.bellOff,
                    title: 'No notifications yet',
                    isScrollable: true,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      return TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: Duration(milliseconds: (200 + (index * 50)).clamp(200, 500)),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 1),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: n.read ? Colors.transparent : Theme.of(context).cardTheme.color,
                            border: Border(
                              bottom: BorderSide(
                                color: isDark ? AppTheme.zinc900 : AppTheme.zinc100, 
                                width: 0.5
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (n.sender != null)
                                AvatarWidget(user: n.sender!, size: 32, showBorder: false)
                              else
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle, 
                                    color: isDark ? AppTheme.zinc900 : AppTheme.zinc100
                                  ),
                                  child: Icon(LucideIcons.bell, size: 14, color: Theme.of(context).textTheme.labelSmall?.color),
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n.message,
                                      style: TextStyle(
                                        color: n.read ? Theme.of(context).textTheme.bodyMedium?.color : Theme.of(context).primaryColor,
                                        fontSize: 14,
                                        fontWeight: n.read ? FontWeight.normal : FontWeight.w500,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      timeago.format(n.createdAt),
                                      style: TextStyle(
                                        color: Theme.of(context).textTheme.labelSmall?.color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!n.read)
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(top: 6, left: 8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
