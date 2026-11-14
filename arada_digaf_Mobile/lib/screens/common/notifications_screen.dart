import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/notification_item.dart';
import '../../state/app_scope.dart';
import '../employee/ticket_details_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(s.get('notifications')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: state.notifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none, size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      s.get('no_notifications'),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                itemCount: state.notifications.length,
                separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final notif = state.notifications[index];

                  Color iconColor;
                  IconData iconData;
                  switch (notif.type) {
                    case NotificationType.submitted:
                      iconColor = Colors.amber.shade700;
                      iconData = Icons.notifications_active;
                      break;
                    case NotificationType.resolved:
                      iconColor = AppColors.statusResolved;
                      iconData = Icons.check_circle;
                      break;
                    case NotificationType.ratingRequest:
                      iconColor = Colors.blue.shade700;
                      iconData = Icons.star;
                      break;
                    case NotificationType.assigned:
                      iconColor = AppColors.primaryGreen;
                      iconData = Icons.engineering;
                      break;
                  }

                  return InkWell(
                    onTap: () {
                      state.markNotificationRead(notif.id);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TicketDetailsScreen(ticketId: notif.ticketId),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: notif.isRead ? Colors.white : AppColors.mintSurface.withAlpha(120),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: notif.isRead ? AppColors.border : AppColors.primaryGreen.withAlpha(100),
                          width: notif.isRead ? 1 : 1.5,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Leading Icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: iconColor.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(iconData, color: iconColor, size: 20),
                          ),
                          const SizedBox(width: 12),

                          // Text Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notif.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                          color: AppColors.textPrimary,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                    if (!notif.isRead) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primaryGreen,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notif.message,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  notif.timeAgo(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
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

