import '../models/ticket.dart';
import '../models/user.dart';
import '../models/notification_item.dart';
import 'api_ticket_repository.dart';
import 'ticket_repository.dart';

class MockTicketRepository implements TicketRepository {
  final List<Ticket> _tickets = [];
  final List<NotificationItem> _notifications = [];
  final Map<String, Map<String, dynamic>> _registeredAccounts = {};
  User? _currentUser;
  int _counter = 100;

  MockTicketRepository() {
    _initDemoData();
  }

  void _initDemoData() {
    final now = DateTime.now();
    _tickets.addAll([
      Ticket(
        id: 'AD-2026-0001',
        category: ServiceCategory.maintenance,
        deviceType: DeviceType.network,
        problemDescription: 'Office network switch port is not giving IP address to workstation.',
        department: 'Finance Department',
        officeLocation: 'Building B, Room 204',
        phoneNumber: '+251911223344',
        createdAt: now.subtract(const Duration(hours: 3)),
        status: TicketStatus.submitted,
        requesterName: 'Selam Worku',
        timeline: [
          TimelineEvent(
            titleKey: 'request_submitted',
            subtitle: 'Request submitted',
            timestamp: now.subtract(const Duration(hours: 3)),
            isCompleted: true,
          ),
          TimelineEvent(
            titleKey: 'in_progress',
            subtitle: '(Waiting for technician)',
            timestamp: now.subtract(const Duration(hours: 3)),
            isCompleted: false,
          ),
          TimelineEvent(
            titleKey: 'outcome_pending',
            subtitle: 'Outcome pending',
            timestamp: now.subtract(const Duration(hours: 3)),
            isCompleted: false,
          ),
        ],
      ),
      Ticket(
        id: 'AD-2026-0002',
        category: ServiceCategory.maintenance,
        deviceType: DeviceType.computer,
        problemDescription: 'Desktop PC power supply unit failed and machine will not turn on.',
        department: 'HR Department',
        officeLocation: 'Building A, Room 105',
        phoneNumber: '+251922334455',
        createdAt: now.subtract(const Duration(hours: 2)),
        status: TicketStatus.inProgress,
        requesterName: 'Dawit Kebede',
        assignedTechnician: 'Chala Tadesse',
        timeline: [
          TimelineEvent(
            titleKey: 'request_submitted',
            subtitle: 'Request submitted',
            timestamp: now.subtract(const Duration(hours: 2)),
            isCompleted: true,
          ),
          TimelineEvent(
            titleKey: 'in_progress',
            subtitle: 'Assigned to Chala Tadesse',
            timestamp: now.subtract(const Duration(hours: 1)),
            isCompleted: true,
          ),
          TimelineEvent(
            titleKey: 'outcome_pending',
            subtitle: 'Outcome pending',
            timestamp: now.subtract(const Duration(hours: 1)),
            isCompleted: false,
          ),
        ],
      ),
    ]);

    _notifications.addAll([
      NotificationItem(
        id: 'notif-1',
        title: 'Ticket AD-2026-0001 submitted',
        message: 'Your service request has been queued.',
        ticketId: 'AD-2026-0001',
        timestamp: now.subtract(const Duration(hours: 3)),
        isRead: false,
        type: NotificationType.submitted,
      ),
    ]);
  }

  @override
  Future<List<Ticket>> getTickets() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.unmodifiable(_tickets);
  }

  @override
  Future<Ticket?> getTicketById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _tickets.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Ticket> createTicket({
    required ServiceCategory category,
    DeviceType? deviceType,
    required String problemDescription,
    required String department,
    required String officeLocation,
    required String phoneNumber,
    required String requesterName,
    DateTime? customDate,
  }) async {
    _counter++;
    final created = customDate ?? DateTime.now();
    final newId = 'AD-2026-0$_counter';
    final ticket = Ticket(
      id: newId,
      category: category,
      deviceType: deviceType,
      problemDescription: problemDescription,
      department: department,
      officeLocation: officeLocation,
      phoneNumber: phoneNumber,
      createdAt: created,
      status: TicketStatus.submitted,
      requesterName: requesterName,
      timeline: [
        TimelineEvent(
          titleKey: 'request_submitted',
          subtitle: 'Request submitted',
          timestamp: created,
          isCompleted: true,
        ),
        TimelineEvent(
          titleKey: 'in_progress',
          subtitle: '(Waiting for technician)',
          timestamp: created,
          isCompleted: false,
        ),
        TimelineEvent(
          titleKey: 'outcome_pending',
          subtitle: 'Outcome pending',
          timestamp: created,
          isCompleted: false,
        ),
      ],
    );
    _tickets.insert(0, ticket);
    return ticket;
  }

  @override
  Future<void> startWork(String ticketId, String technicianName) async {
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx != -1) {
      final t = _tickets[idx];
      _tickets[idx] = Ticket(
        id: t.id,
        category: t.category,
        deviceType: t.deviceType,
        problemDescription: t.problemDescription,
        department: t.department,
        officeLocation: t.officeLocation,
        phoneNumber: t.phoneNumber,
        createdAt: t.createdAt,
        status: TicketStatus.inProgress,
        requesterName: t.requesterName,
        assignedTechnician: technicianName,
        timeline: t.timeline,
      );
    }
  }

  @override
  Future<void> recordWork(String ticketId, WorkRecord workRecord) async {
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx != -1) {
      final t = _tickets[idx];
      final status = workRecord.outcome == WorkOutcome.solutionGiven
          ? TicketStatus.resolved
          : workRecord.outcome == WorkOutcome.solutionNotGiven
              ? TicketStatus.notResolved
              : TicketStatus.referred;
      _tickets[idx] = Ticket(
        id: t.id,
        category: t.category,
        deviceType: t.deviceType,
        problemDescription: t.problemDescription,
        department: t.department,
        officeLocation: t.officeLocation,
        phoneNumber: t.phoneNumber,
        createdAt: t.createdAt,
        status: status,
        requesterName: t.requesterName,
        assignedTechnician: t.assignedTechnician,
        timeline: t.timeline,
        workRecord: workRecord,
      );
    }
  }

  @override
  Future<void> rateService(String ticketId, ServiceRating rating) async {
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx != -1) {
      final t = _tickets[idx];
      _tickets[idx] = Ticket(
        id: t.id,
        category: t.category,
        deviceType: t.deviceType,
        problemDescription: t.problemDescription,
        department: t.department,
        officeLocation: t.officeLocation,
        phoneNumber: t.phoneNumber,
        createdAt: t.createdAt,
        status: t.status,
        requesterName: t.requesterName,
        assignedTechnician: t.assignedTechnician,
        timeline: t.timeline,
        workRecord: t.workRecord,
        rating: rating,
      );
    }
  }

  @override
  Future<List<NotificationItem>> getNotifications() async {
    return List.unmodifiable(_notifications);
  }

  @override
  Future<void> markNotificationAsRead(String notificationId) async {
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      final n = _notifications[idx];
      _notifications[idx] = NotificationItem(
        id: n.id,
        title: n.title,
        message: n.message,
        ticketId: n.ticketId,
        timestamp: n.timestamp,
        isRead: true,
        type: n.type,
      );
    }
  }

  @override
  Future<User> login(String username, String password, UserRole role) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final uname = username.trim().toLowerCase();
    final reg = _registeredAccounts[uname];
    if (reg != null) {
      final status = reg['status'];
      if (status == 'pending') {
        throw ApiException(
          'Your account registration is pending administrator approval.',
          statusCode: 403,
          code: 'account_pending',
          data: reg,
        );
      }
      if (status == 'rejected') {
        throw ApiException(
          'Your registration was rejected: ${reg['rejectionReason'] ?? ''}',
          statusCode: 403,
          code: 'account_rejected',
          data: reg,
        );
      }
      if (status == 'suspended') {
        throw const ApiException(
          'This account has been suspended.',
          statusCode: 403,
          code: 'account_suspended',
        );
      }
    }

    _currentUser = User(
      username: username,
      fullName: role == UserRole.employee ? 'Demo Employee' : 'Demo Technician',
      role: role,
      department: 'Finance Department',
      officeLocation: 'Building A, Room 101',
      phoneNumber: '+251911223344',
    );
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
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
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final uname = username.trim().toLowerCase();
    if (_registeredAccounts.containsKey(uname)) {
      throw const ApiException(
        'An account with this username or employee ID already exists.',
        statusCode: 400,
        code: 'validation_error',
      );
    }
    _counter++;
    final ref = 'REG-2026-0${_counter.toString().padLeft(3, '0')}';
    final rec = <String, dynamic>{
      'reference_number': ref,
      'referenceNumber': ref,
      'username': uname,
      'fullName': fullName,
      'role': role == UserRole.employee ? 'employee' : 'technician',
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
      'department': department,
      'phone': phone,
      'specialties': specialties ?? [],
      'qualificationNote': qualificationNote ?? '',
      'user': {
        'username': uname,
        'fullName': fullName,
        'role': role == UserRole.employee ? 'employee' : 'technician',
        'department': department,
        'status': 'pending',
        'registration_reference': ref,
      },
    };
    _registeredAccounts[uname] = rec;
    _registeredAccounts[ref] = rec;
    return rec;
  }

  @override
  Future<Map<String, dynamic>> checkRegistrationStatus({
    String? referenceNumber,
    String? username,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final key = (referenceNumber ?? username ?? '').trim();
    final existing = _registeredAccounts[key] ?? _registeredAccounts[key.toLowerCase()];
    if (existing != null) {
      return existing;
    }
    return {
      'reference_number': referenceNumber ?? 'REG-2026-0001',
      'referenceNumber': referenceNumber ?? 'REG-2026-0001',
      'username': username ?? 'demo',
      'fullName': 'Demo Registrant',
      'role': 'employee',
      'status': 'pending',
      'rejectionReason': '',
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}
