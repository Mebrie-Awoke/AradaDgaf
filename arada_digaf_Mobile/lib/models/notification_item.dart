enum NotificationType {
  submitted,
  resolved,
  ratingRequest,
  assigned,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String ticketId;
  final DateTime timestamp;
  bool isRead;
  final NotificationType type;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.ticketId,
    required this.timestamp,
    this.isRead = false,
    required this.type,
  });

  String timeAgo() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      final mins = difference.inMinutes <= 0 ? 1 : difference.inMinutes;
      return '${mins}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

