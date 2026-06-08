import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_widget.dart';

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

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => notificationProvider.fetchNotifications(),
        color: AppTheme.white,
        backgroundColor: AppTheme.zinc900,
        child: notificationProvider.isLoading && notifications.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppTheme.white))
            : notifications.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.bellOff, size: 48, color: AppTheme.zinc800),
                        SizedBox(height: 16),
                        Text('No notifications yet', style: TextStyle(color: AppTheme.zinc500)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      return TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: Duration(milliseconds: 200 + (index * 50)),
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
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: n.read ? Colors.transparent : AppTheme.zinc950,
                            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                            border: Border.all(
                              color: n.read ? AppTheme.zinc900.withValues(alpha: 0.5) : AppTheme.zinc900,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (n.sender != null)
                                AvatarWidget(user: n.sender!, size: 36)
                              else
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.zinc900),
                                  child: const Icon(LucideIcons.bell, size: 16, color: AppTheme.zinc500),
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n.message,
                                      style: TextStyle(
                                        color: AppTheme.white,
                                        fontSize: 14,
                                        fontWeight: n.read ? FontWeight.normal : FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      timeago.format(n.createdAt),
                                      style: const TextStyle(color: AppTheme.zinc600, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              if (!n.read)
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(top: 4, left: 8),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
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
