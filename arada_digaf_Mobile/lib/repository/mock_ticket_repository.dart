import '../models/ticket.dart';
import '../models/notification_item.dart';
import 'ticket_repository.dart';

class MockTicketRepository implements TicketRepository {
  int _nextTicketNumber = 424;

  late final List<Ticket> _tickets;
  late final List<NotificationItem> _notifications;

  MockTicketRepository() {
    final now = DateTime.now();

    _tickets = [
      Ticket(
        id: 'AD-2026-0423',
        category: ServiceCategory.maintenance,
        deviceType: DeviceType.computer,
        problemDescription: 'Computer not connecting to network and monitor flickering occasionally.',
        department: 'IT Office',
        officeLocation: 'Building B, 2nd Floor, Room 204',
        phoneNumber: '+251 91 123 4567',
        createdAt: now,
        status: TicketStatus.submitted,
        requesterName: 'Selam Tesfaye',
        timeline: [
          TimelineEvent(
            titleKey: 'request_submitted',
            subtitle: 'Request submitted',
            timestamp: now,
            isCompleted: true,
          ),
          TimelineEvent(
            titleKey: 'in_progress',
            subtitle: '(Waiting for technician)',
            timestamp: now,
            isCompleted: false,
          ),
          TimelineEvent(
            titleKey: 'outcome_pending',
            subtitle: 'Outcome pending',
            timestamp: now,
            isCompleted: false,
          ),
        ],
      ),
      Ticket(
        id: 'AD-2026-0419',
        category: ServiceCategory.software,
        problemDescription: 'Software issue: Cannot open ERP client software after system patch.',
        department: 'IT Office',
        officeLocation: 'Building B, 2nd Floor, Room 204',
        phoneNumber: '+251 91 123 4567',
        createdAt: now.subtract(const Duration(days: 5)),
        status: TicketStatus.inProgress,
        requesterName: 'Selam Tesfaye',
        assignedTechnician: 'Abel Mekonnen',
        timeline: [
          TimelineEvent(
            titleKey: 'request_submitted',
            subtitle: 'Request submitted',
            timestamp: now.subtract(const Duration(days: 5)),
            isCompleted: true,
          ),
          TimelineEvent(
            titleKey: 'in_progress',
            subtitle: 'Assigned to Abel Mekonnen - diagnosing client logs',
            timestamp: now.subtract(const Duration(days: 4, hours: 20)),
            isCompleted: true,
          ),
          TimelineEvent(
            titleKey: 'outcome_pending',
            subtitle: 'Outcome pending',
            timestamp: now,
            isCompleted: false,
          ),
        ],
      ),
      Ticket(
        id: 'AD-2026-0415',
        category: ServiceCategory.maintenance,
        deviceType: DeviceType.printer,
        problemDescription: 'Printer setup and toner replacement for HP LaserJet.',
        department: 'IT Office',
        officeLocation: 'Building B, 2nd Floor, Room 204',
        phoneNumber: '+251 91 123 4567',
        createdAt: now.subtract(const Duration(days: 8)),
        status: TicketStatus.resolved,
        requesterName: 'Selam Tesfaye',
        assignedTechnician: 'Abel Mekonnen',
        workRecord: WorkRecord(
          deviceType: 'Printer',
          model: 'HP LaserJet Pro 400',
          serialNumber: 'SN98421',
          problemDescription: 'Replaced empty toner cartridge and calibrated print alignment.',
          toolsMaterials: 'HP 05A Black Toner',
          outcome: WorkOutcome.solutionGiven,
          solutionDateTime: now.subtract(const Duration(days: 8, hours: -3)),
        ),
        timeline: [
          TimelineEvent(
            titleKey: 'request_submitted',
            subtitle: 'Request submitted',
            timestamp: now.subtract(const Duration(days: 8)),
            isCompleted: true,
          ),
          TimelineEvent(
            titleKey: 'in_progress',
            subtitle: 'Assigned to Abel Mekonnen',
            timestamp: now.subtract(const Duration(days: 8, hours: -1)),
            isCompleted: true,
          ),
          TimelineEvent(
            titleKey: 'outcome',
            subtitle: 'Solution given: Toner replaced and network printer reconnected',
            timestamp: now.subtract(const Duration(days: 8, hours: -3)),
            isCompleted: true,
          ),
        ],
      ),
    ];

    _notifications = [
      NotificationItem(
        id: 'n1',
        title: 'Your request AD-2026-0423 has been submitted.',
        message: 'Your ticket is in the queue waiting for technician assignment.',
        ticketId: 'AD-2026-0423',
        timestamp: now.subtract(const Duration(minutes: 2)),
        isRead: false,
        type: NotificationType.submitted,
      ),
      NotificationItem(
        id: 'n2',
        title: 'Ticket AD-2026-0419 is in progress.',
        message: 'Technician Abel Mekonnen has started working on your request.',
        ticketId: 'AD-2026-0419',
        timestamp: now.subtract(const Duration(days: 1)),
        isRead: false,
        type: NotificationType.assigned,
      ),
      NotificationItem(
        id: 'n3',
        title: 'Please rate your service.',
        message: 'Ticket AD-2026-0415 was resolved. Please rate the quality and speed.',
        ticketId: 'AD-2026-0415',
        timestamp: now.subtract(const Duration(days: 2)),
        isRead: true,
        type: NotificationType.ratingRequest,
      ),
    ];
  }

  @override
  Future<List<Ticket>> getTickets() async {
    return List.from(_tickets);
  }

  @override
  Future<Ticket?> getTicketById(String id) async {
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
    final ticketId = 'AD-2026-0$_nextTicketNumber';
    _nextTicketNumber++;

    final created = customDate ?? DateTime.now();

    final newTicket = Ticket(
      id: ticketId,
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

    _tickets.insert(0, newTicket);

    // Create notification
    _notifications.insert(
      0,
      NotificationItem(
        id: 'n_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Your request $ticketId has been submitted.',
        message: 'Your ticket is logged successfully.',
        ticketId: ticketId,
        timestamp: DateTime.now(),
        isRead: false,
        type: NotificationType.submitted,
      ),
    );

    return newTicket;
  }

  @override
  Future<void> startWork(String ticketId, String technicianName) async {
    final ticket = await getTicketById(ticketId);
    if (ticket == null) return;

    ticket.status = TicketStatus.inProgress;
    ticket.assignedTechnician = technicianName;

    // Update timeline
    final existingIdx = ticket.timeline.indexWhere((e) => e.titleKey == 'in_progress');
    if (existingIdx != -1) {
      ticket.timeline[existingIdx] = TimelineEvent(
        titleKey: 'in_progress',
        subtitle: 'Technician $technicianName started work',
        timestamp: DateTime.now(),
        isCompleted: true,
      );
    }

    _notifications.insert(
      0,
      NotificationItem(
        id: 'n_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Ticket $ticketId is in progress.',
        message: 'Technician $technicianName has begun diagnosing.',
        ticketId: ticketId,
        timestamp: DateTime.now(),
        isRead: false,
        type: NotificationType.assigned,
      ),
    );
  }

  @override
  Future<void> recordWork(String ticketId, WorkRecord workRecord) async {
    final ticket = await getTicketById(ticketId);
    if (ticket == null) return;

    ticket.workRecord = workRecord;
    switch (workRecord.outcome) {
      case WorkOutcome.solutionGiven:
        ticket.status = TicketStatus.resolved;
        break;
      case WorkOutcome.solutionNotGiven:
        ticket.status = TicketStatus.notResolved;
        break;
      case WorkOutcome.referredExternally:
        ticket.status = TicketStatus.referred;
        break;
    }

    // Update outcome timeline event
    final existingOutcomeIdx = ticket.timeline.indexWhere((e) => e.titleKey.startsWith('outcome'));
    final outcomeDesc = '${workRecord.outcome.labelEn}: ${workRecord.problemDescription}';
    final event = TimelineEvent(
      titleKey: 'outcome',
      subtitle: outcomeDesc,
      timestamp: workRecord.solutionDateTime,
      isCompleted: true,
    );

    if (existingOutcomeIdx != -1) {
      ticket.timeline[existingOutcomeIdx] = event;
    } else {
      ticket.timeline.add(event);
    }

    // Create notification for employee
    _notifications.insert(
      0,
      NotificationItem(
        id: 'n_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Ticket $ticketId: ${workRecord.outcome.labelEn}',
        message: 'Work recorded by ${ticket.assignedTechnician ?? "Technician"}. Please rate your service.',
        ticketId: ticketId,
        timestamp: DateTime.now(),
        isRead: false,
        type: NotificationType.resolved,
      ),
    );
  }

  @override
  Future<void> rateService(String ticketId, ServiceRating rating) async {
    final ticket = await getTicketById(ticketId);
    if (ticket == null) return;
    ticket.rating = rating;
  }

  @override
  Future<List<NotificationItem>> getNotifications() async {
    return List.from(_notifications);
  }

  @override
  Future<void> markNotificationAsRead(String notificationId) async {
    final notif = _notifications.firstWhere(
      (n) => n.id == notificationId,
      orElse: () => _notifications.first,
    );
    notif.isRead = true;
  }
}

