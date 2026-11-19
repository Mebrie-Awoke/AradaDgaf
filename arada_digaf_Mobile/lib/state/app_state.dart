import 'dart:async';
import 'package:flutter/material.dart';
import '../core/strings.dart';
import '../models/ticket.dart';
import '../models/user.dart';
import '../models/notification_item.dart';
import '../repository/api_ticket_repository.dart';
import '../repository/mock_ticket_repository.dart';
import '../repository/ticket_repository.dart';

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

}

class AppState extends ChangeNotifier {
  static const bool useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);

  final TicketRepository repository;

  AppState({TicketRepository? repository})
      : repository = repository ?? (useMock ? MockTicketRepository() : ApiTicketRepository());

  AppLanguage _language = AppLanguage.amharic;
  User? _currentUser;
  List<Ticket> _tickets = [];
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  String? _lastError;
<<<<<<< HEAD
  Timer? _updatesTimer;
  bool _pollingUpdates = false;
=======
  ApiException? _lastAuthException;
>>>>>>> feature/e2e-registration-approval

  AppLanguage get language => _language;
  S get s => S(_language);
  User? get currentUser => _currentUser;
  List<Ticket> get tickets => List.unmodifiable(_tickets);
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  ApiException? get lastAuthException => _lastAuthException;
  int get unreadNotificationsCount => _notifications.where((n) => !n.isRead).length;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<bool> login(String username, String password, UserRole role) async {
    _setLoading(true);
    _lastError = null;
    _lastAuthException = null;
    try {
      try {
        _currentUser = await repository.login(username, password, role);
      } on ApiException catch (error) {
        _lastError = error.message;
        _lastAuthException = error;
        _currentUser = null;
        return false;
      }
      try {
        await _loadInitialData();
      } on ApiException catch (error) {
        // Authentication succeeded; let the user enter and retry data loading.
        _lastError = error.message;
      }
      _startUpdatesPolling();
      return true;
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

  void _startUpdatesPolling() {
    _updatesTimer?.cancel();
    _updatesTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      _pollLatestUpdates();
    });
  }

  Future<void> _pollLatestUpdates() async {
    if (_currentUser == null || _pollingUpdates) return;
    _pollingUpdates = true;
    try {
      await _loadInitialData();
    } on ApiException catch (error) {
      _lastError = error.message;
    } finally {
      _pollingUpdates = false;
    }
  }

  @override
  void dispose() {
    _updatesTimer?.cancel();
    super.dispose();
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

  Future<void> _refreshAfterMutation() async {
    try {
      _tickets = await repository.getTickets();
    } on ApiException catch (error) {
      _lastError = error.message;
    }
    try {
      _notifications = await repository.getNotifications();
    } on ApiException catch (error) {
      _lastError = error.message;
    }
    notifyListeners();
  }

  void setLanguage(AppLanguage lang) { _language = lang; notifyListeners(); }
  void toggleLanguage() {
    _language = _language == AppLanguage.amharic ? AppLanguage.english : AppLanguage.amharic;
    notifyListeners();
  }

  Future<void> logout() async {
    _updatesTimer?.cancel();
    _updatesTimer = null;
    try {
      await repository.logout();
    } finally {
      _currentUser = null;
      _tickets = [];
      _notifications = [];
      notifyListeners();
    }
  }

  Future<Ticket?> submitTicket(TicketDraft draft) async {
    if (_currentUser == null) throw const ApiException('Please sign in before submitting a request.');
    final ticket = await repository.createTicket(
      category: draft.category, deviceType: draft.deviceType,
      problemDescription: draft.problemDescription, department: draft.department,
      officeLocation: draft.officeLocation, phoneNumber: draft.phoneNumber,
      requesterName: _currentUser!.fullName, customDate: draft.date,
    );
    _tickets = [ticket, ..._tickets.where((item) => item.id != ticket.id)];
    await _refreshAfterMutation();
    return ticket;
  }

  Future<void> startWork(String ticketId) async {
    await repository.startWork(ticketId, _currentUser?.fullName ?? '');
    await _refreshAfterMutation();
  }

  Future<void> recordWork(String ticketId, WorkRecord workRecord) async {
    await repository.recordWork(ticketId, workRecord);
    await _refreshAfterMutation();
  }

  Future<void> rateTicket(String ticketId, ServiceRating rating) async {
    await repository.rateService(ticketId, rating);
    await _refreshAfterMutation();
  }

  Future<void> markNotificationRead(String id) async {
    await repository.markNotificationAsRead(id);
    for (final notification in _notifications) {
      if (notification.id == id) notification.isRead = true;
    }
    try {
      _notifications = await repository.getNotifications();
    } on ApiException catch (error) {
      _lastError = error.message;
    }
    notifyListeners();
  }

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
    _setLoading(true);
    _lastError = null;
    try {
      return await repository.register(
        role: role,
        fullName: fullName,
        employeeId: employeeId,
        username: username,
        password: password,
        confirmPassword: confirmPassword,
        phone: phone,
        email: email,
        department: department,
        workUnit: workUnit,
        officeLocation: officeLocation,
        specialties: specialties,
        qualificationNote: qualificationNote,
      );
    } on ApiException catch (error) {
      _lastError = error.message;
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> checkRegistrationStatus({
    String? referenceNumber,
    String? username,
  }) async {
    return await repository.checkRegistrationStatus(
      referenceNumber: referenceNumber,
      username: username,
    );
  }
}
