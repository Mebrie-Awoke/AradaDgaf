import 'package:flutter/material.dart';
import '../core/strings.dart';
import '../models/ticket.dart';
import '../models/user.dart';
import '../models/notification_item.dart';
import '../repository/ticket_repository.dart';
import '../repository/mock_ticket_repository.dart';

class TicketDraft {
  ServiceCategory category;
  DeviceType? deviceType;
  String problemDescription;
  String department;
  String officeLocation;
  String phoneNumber;
  DateTime date;

  TicketDraft({
    this.category = ServiceCategory.maintenance,
    this.deviceType = DeviceType.computer,
    this.problemDescription = '',
    this.department = 'IT Office',
    this.officeLocation = 'Building B, 2nd Floor, Room 204',
    this.phoneNumber = '+251 91 123 4567',
    DateTime? date,
  }) : date = date ?? DateTime.now();

  TicketDraft copy() {
    return TicketDraft(
      category: category,
      deviceType: deviceType,
      problemDescription: problemDescription,
      department: department,
      officeLocation: officeLocation,
      phoneNumber: phoneNumber,
      date: date,
    );
  }
}

class AppState extends ChangeNotifier {
  final TicketRepository repository = MockTicketRepository();

  AppLanguage _language = AppLanguage.amharic;
  User? _currentUser;
  bool _isOfflineSimulated = false;
  TicketDraft? _pendingDraft;
  List<Ticket> _tickets = [];
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;

  // Predefined demo users
  static const User demoEmployee = User(
    username: 'selam',
    fullName: 'Selam Tesfaye',
    role: UserRole.employee,
    department: 'IT Office',
    officeLocation: 'Building B, 2nd Floor, Room 204',
    phoneNumber: '+251 91 123 4567',
  );

  static const User demoTechnician = User(
    username: 'abel',
    fullName: 'Abel Mekonnen',
    role: UserRole.technician,
    department: 'IT Support Department',
    officeLocation: 'HQ, Ground Floor, Room 012',
    phoneNumber: '+251 92 987 6543',
  );

  AppState() {
    _loadInitialData();
  }

  AppLanguage get language => _language;
  S get s => S(_language);
  User? get currentUser => _currentUser;
  bool get isOfflineSimulated => _isOfflineSimulated;
  TicketDraft? get pendingDraft => _pendingDraft;
  List<Ticket> get tickets => _tickets;
  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _isLoading;

  int get unreadNotificationsCount =>
      _notifications.where((n) => !n.isRead).length;

  Future<void> _loadInitialData() async {
    _isLoading = true;
    notifyListeners();
    _tickets = await repository.getTickets();
    _notifications = await repository.getNotifications();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshTickets() async {
    _isLoading = true;
    notifyListeners();
    // Simulate slight network delay for pull to refresh
    await Future.delayed(const Duration(milliseconds: 600));
    _tickets = await repository.getTickets();
    _notifications = await repository.getNotifications();
    _isLoading = false;
    notifyListeners();
  }

  void setLanguage(AppLanguage lang) {
    _language = lang;
    notifyListeners();
  }

  void toggleLanguage() {
    _language = _language == AppLanguage.amharic
        ? AppLanguage.english
        : AppLanguage.amharic;
    notifyListeners();
  }

  bool login(String username, String password, UserRole role) {
    final cleanUser = username.trim().toLowerCase();
    final cleanPass = password.trim();

    if (role == UserRole.employee) {
      if (cleanUser == 'selam' && cleanPass == '1234') {
        _currentUser = demoEmployee;
        notifyListeners();
        return true;
      }
    } else {
      if (cleanUser == 'abel' && cleanPass == '1234') {
        _currentUser = demoTechnician;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void setSimulateOffline(bool value) {
    _isOfflineSimulated = value;
    notifyListeners();
  }

  void savePendingDraft(TicketDraft draft) {
    _pendingDraft = draft;
    notifyListeners();
  }

  void clearPendingDraft() {
    _pendingDraft = null;
    notifyListeners();
  }

  Future<Ticket?> submitTicket(TicketDraft draft) async {
    if (_isOfflineSimulated) {
      _pendingDraft = draft;
      notifyListeners();
      return null;
    }

    final ticket = await repository.createTicket(
      category: draft.category,
      deviceType: draft.deviceType,
      problemDescription: draft.problemDescription,
      department: draft.department,
      officeLocation: draft.officeLocation,
      phoneNumber: draft.phoneNumber,
      requesterName: _currentUser?.fullName ?? 'Employee',
      customDate: draft.date,
    );

    _pendingDraft = null;
    _tickets = await repository.getTickets();
    _notifications = await repository.getNotifications();
    notifyListeners();
    return ticket;
  }

  Future<void> startWork(String ticketId) async {
    final techName = _currentUser?.fullName ?? 'Technician';
    await repository.startWork(ticketId, techName);
    _tickets = await repository.getTickets();
    _notifications = await repository.getNotifications();
    notifyListeners();
  }

  Future<void> recordWork(String ticketId, WorkRecord workRecord) async {
    await repository.recordWork(ticketId, workRecord);
    _tickets = await repository.getTickets();
    _notifications = await repository.getNotifications();
    notifyListeners();
  }

  Future<void> rateTicket(String ticketId, ServiceRating rating) async {
    await repository.rateService(ticketId, rating);
    _tickets = await repository.getTickets();
    notifyListeners();
  }

  Future<void> markNotificationRead(String id) async {
    await repository.markNotificationAsRead(id);
    _notifications = await repository.getNotifications();
    notifyListeners();
  }
}

