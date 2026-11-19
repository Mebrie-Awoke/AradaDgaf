import '../models/ticket.dart';
import '../models/user.dart';
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

  // Authentication & Registration
  Future<User> login(String username, String password, UserRole role);
  Future<void> logout();
  Future<Map<String, dynamic>> register({
    required UserRole role,
    required String fullName,
    required String employeeId,
    required String username,
    required String password,
    required String confirmPassword,
    required String phone,
    String? email,
    required String department,
    String? workUnit,
    String? officeLocation,
    List<String>? specialties,
    String? qualificationNote,
  });
  Future<Map<String, dynamic>> checkRegistrationStatus({
    String? referenceNumber,
    String? username,
  });
}


