import '../models/ticket.dart';
import '../models/notification_item.dart';

abstract class TicketRepository {
  Future<List<Ticket>> getTickets();
  Future<Ticket?> getTicketById(String id);
  Future<Ticket> createTicket({
    required ServiceCategory category,
    DeviceType? deviceType,
    required String problemDescription,
    required String department,
    required String officeLocation,
    required String phoneNumber,
    required String requesterName,
    DateTime? customDate,
  });
  Future<void> startWork(String ticketId, String technicianName);
  Future<void> recordWork(String ticketId, WorkRecord workRecord);
  Future<void> rateService(String ticketId, ServiceRating rating);
  Future<List<NotificationItem>> getNotifications();
  Future<void> markNotificationAsRead(String notificationId);
}

