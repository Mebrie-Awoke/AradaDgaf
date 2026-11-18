import 'package:flutter/material.dart';
import '../core/strings.dart';
import '../models/ticket.dart';
import '../models/user.dart';
import '../models/notification_item.dart';
import '../repository/api_ticket_repository.dart';

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
    this.department = '',
    this.officeLocation = '',
    this.phoneNumber = '',
    DateTime? date,
  }) : date = date ?? DateTime.now();

  TicketDraft copy() => TicketDraft(
    category: category, deviceType: deviceType, problemDescription: problemDescription,
    department: department, officeLocation: officeLocation, phoneNumber: phoneNumber, date: date,
  );
}

class AppState extends ChangeNotifier {
  final ApiTicketRepository repository = ApiTicketRepository();

  AppLanguage _language = AppLanguage.amharic;
  User? _currentUser;
  TicketDraft? _pendingDraft;
  List<Ticket> _tickets = [];
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  String? _lastError;

  AppLanguage get language => _language;
  S get s => S(_language);
  User? get currentUser => _currentUser;
  bool get isOfflineSimulated => false;
  TicketDraft? get pendingDraft => _pendingDraft;
  List<Ticket> get tickets => List.unmodifiable(_tickets);
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  int get unreadNotificationsCount => _notifications.where((n) => !n.isRead).length;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<bool> login(String username, String password, UserRole role) async {
    _setLoading(true);
    _lastError = null;
    try {
      _currentUser = await repository.login(username, password, role);
      await _loadInitialData();
      return true;
    } on ApiException catch (error) {
      _lastError = error.message;
      _currentUser = null;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadInitialData() async {
    final results = await Future.wait([
      repository.getTickets(),
      repository.getNotifications(),
    ]);
    _tickets = results[0] as List<Ticket>;
    _notifications = results[1] as List<NotificationItem>;
    notifyListeners();
  }

  Future<void> refreshTickets() async {
    if (_currentUser == null) return;
    _setLoading(true);
    _lastError = null;
    try {
      await _loadInitialData();
    } on ApiException catch (error) {
      _lastError = error.message;
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void setLanguage(AppLanguage lang) { _language = lang; notifyListeners(); }
  void toggleLanguage() {
    _language = _language == AppLanguage.amharic ? AppLanguage.english : AppLanguage.amharic;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await repository.logout();
    } finally {
      _currentUser = null;
      _tickets = [];
      _notifications = [];
      _pendingDraft = null;
      notifyListeners();
    }
  }

  void savePendingDraft(TicketDraft draft) { _pendingDraft = draft; notifyListeners(); }
  void clearPendingDraft() { _pendingDraft = null; notifyListeners(); }

  Future<Ticket?> submitTicket(TicketDraft draft) async {
    if (_currentUser == null) throw const ApiException('Please sign in before submitting a request.');
    final ticket = await repository.createTicket(
      category: draft.category, deviceType: draft.deviceType,
      problemDescription: draft.problemDescription, department: draft.department,
      officeLocation: draft.officeLocation, phoneNumber: draft.phoneNumber,
      requesterName: _currentUser!.fullName, customDate: draft.date,
    );
    _pendingDraft = null;
    await refreshTickets();
    return ticket;
  }

  Future<void> startWork(String ticketId) async {
    await repository.startWork(ticketId, _currentUser?.fullName ?? '');
    await refreshTickets();
  }

  Future<void> recordWork(String ticketId, WorkRecord workRecord) async {
    await repository.recordWork(ticketId, workRecord);
    await refreshTickets();
  }

  Future<void> rateTicket(String ticketId, ServiceRating rating) async {
    await repository.rateService(ticketId, rating);
    await refreshTickets();
  }

  Future<void> markNotificationRead(String id) async {
    await repository.markNotificationAsRead(id);
    _notifications = await repository.getNotifications();
    notifyListeners();
  }
}
