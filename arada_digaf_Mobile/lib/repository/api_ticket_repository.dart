import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/ticket.dart';
import '../models/user.dart';
import '../models/notification_item.dart';
import 'ticket_repository.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ApiTicketRepository implements TicketRepository {
  ApiTicketRepository({http.Client? client, FlutterSecureStorage? storage})
      : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  static const String _baseUrlValue = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );
  final http.Client _client;
  final FlutterSecureStorage _storage;
  String? _token;
  String get _baseUrl => _baseUrlValue.replaceAll(RegExp(r'/+$'), '');
  Future<String?> get _accessToken async => _token ??= await _storage.read(key: 'arada_access_token');

  Future<Map<String, dynamic>> _request(String method, String path, {Map<String, dynamic>? body, bool authenticated = true}) async {
    final uri = Uri.parse('$_baseUrl/mobile/$path');
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (authenticated) {
      final token = await _accessToken;
      if (token == null || token.isEmpty) throw const ApiException('Your session has expired. Please sign in again.');
      headers['Authorization'] = 'Bearer $token';
    }
    late http.Response response;
    try {
      switch (method) {
        case 'GET': response = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 25)); break;
        case 'POST': response = await _client.post(uri, headers: headers, body: jsonEncode(body ?? {})).timeout(const Duration(seconds: 25)); break;
        case 'PATCH': response = await _client.patch(uri, headers: headers, body: jsonEncode(body ?? {})).timeout(const Duration(seconds: 25)); break;
        default: throw const ApiException('Unsupported request method.');
      }
    } on ApiException { rethrow; } catch (_) {
      throw const ApiException('Could not connect to the server. Check your internet connection and try again.');
    }
    Map<String, dynamic> decoded;
    try { decoded = jsonDecode(response.body) as Map<String, dynamic>; }
    catch (_) { throw ApiException('The server returned an invalid response (${response.statusCode}).', statusCode: response.statusCode); }
    if (response.statusCode < 200 || response.statusCode >= 300 || decoded['success'] != true) {
      throw ApiException(_readableError(decoded['message'] ?? decoded['detail'] ?? decoded['errors']) ?? 'Request failed (${response.statusCode}).', statusCode: response.statusCode);
    }
    final data = decoded['data'];
    if (data is Map<String, dynamic>) return data;
    return {'items': data};
  }

  String? _readableError(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is List) return value.join(', ');
    if (value is Map) {
      for (final entry in value.entries) { final message = _readableError(entry.value); if (message != null) return message; }
    }
    return value.toString();
  }

  Future<User> login(String username, String password, UserRole role) async {
    final result = await _request('POST', 'auth/login/', authenticated: false, body: {
      'username': username.trim(), 'password': password,
      'role': role == UserRole.employee ? 'employee' : 'technician',
    });
    final token = result['access_token']?.toString();
    final userData = result['user'];
    if (token == null || token.isEmpty || userData is! Map) throw const ApiException('The server did not return a valid login session.');
    _token = token;
    await _storage.write(key: 'arada_access_token', value: token);
    return User(
      username: '${userData['username'] ?? ''}',
      fullName: '${userData['fullName'] ?? ''}',
      role: userData['role'] == 'employee' ? UserRole.employee : UserRole.technician,
      department: '${userData['department'] ?? ''}',
      officeLocation: '${userData['officeLocation'] ?? ''}',
      phoneNumber: '${userData['phoneNumber'] ?? ''}',
    );
  }

  Future<void> logout() async {
    try { await _request('POST', 'auth/logout/'); }
    finally { _token = null; await _storage.delete(key: 'arada_access_token'); }
  }

  DateTime _date(dynamic value) => DateTime.tryParse('${value ?? ''}')?.toLocal() ?? DateTime.now();
  T _enumByName<T extends Enum>(List<T> values, dynamic value, T fallback) {
    for (final item in values) {
      if (item.name == value) return item;
    }
    return fallback;
  }

  Ticket _ticketFromJson(Map<String, dynamic> json) {
    final w = json['workRecord'] is Map ? Map<String, dynamic>.from(json['workRecord']) : null;
    final r = json['rating'] is Map ? Map<String, dynamic>.from(json['rating']) : null;
    final events = json['timeline'] is List ? json['timeline'] as List : const [];
    return Ticket(
      id: '${json['id'] ?? ''}',
      category: _enumByName(ServiceCategory.values, json['category'], ServiceCategory.other),
      deviceType: json['deviceType'] == null ? null : _enumByName(DeviceType.values, json['deviceType'], DeviceType.other),
      problemDescription: '${json['problemDescription'] ?? ''}',
      department: '${json['department'] ?? ''}', officeLocation: '${json['officeLocation'] ?? ''}',
      phoneNumber: '${json['phoneNumber'] ?? ''}', createdAt: _date(json['createdAt']),
      status: _enumByName(TicketStatus.values, json['status'], TicketStatus.submitted),
      requesterName: '${json['requesterName'] ?? ''}', assignedTechnician: json['assignedTechnician']?.toString(),
      timeline: events.whereType<Map>().map((e) => TimelineEvent(
        titleKey: '${e['titleKey'] ?? ''}', subtitle: '${e['subtitle'] ?? ''}',
        timestamp: _date(e['timestamp']), isCompleted: e['isCompleted'] == true,
      )).toList(),
      workRecord: w == null ? null : WorkRecord(
        deviceType: '${w['deviceType'] ?? ''}', model: w['model']?.toString(), serialNumber: w['serialNumber']?.toString(),
        problemDescription: '${w['problemDescription'] ?? ''}', toolsMaterials: w['toolsMaterials']?.toString(),
        outcome: _enumByName(WorkOutcome.values, w['outcome'], WorkOutcome.solutionGiven),
        solutionDateTime: _date(w['solutionDateTime']),
      ),
      rating: r == null ? null : ServiceRating(
        quality: _enumByName(RatingLevel.values, r['quality'], RatingLevel.medium),
        speed: _enumByName(RatingLevel.values, r['speed'], RatingLevel.medium), ratedAt: _date(r['ratedAt']),
      ),
    );
  }

  NotificationItem _notificationFromJson(Map<String, dynamic> j) => NotificationItem(
    id: '${j['id'] ?? ''}', title: '${j['title'] ?? ''}', message: '${j['message'] ?? ''}',
    ticketId: '${j['ticketId'] ?? ''}', timestamp: _date(j['timestamp']), isRead: j['isRead'] == true,
    type: _enumByName(NotificationType.values, j['type'], NotificationType.submitted),
  );

  @override
  Future<List<Ticket>> getTickets() async {
    final items = (await _request('GET', 'tickets/'))['items'];
    return items is List ? items.whereType<Map>().map((e) => _ticketFromJson(Map<String, dynamic>.from(e))).toList() : [];
  }
  @override
  Future<Ticket?> getTicketById(String id) async => _ticketFromJson(await _request('GET', 'tickets/${Uri.encodeComponent(id)}/'));
  @override
  Future<Ticket> createTicket({required ServiceCategory category, DeviceType? deviceType, required String problemDescription, required String department, required String officeLocation, required String phoneNumber, required String requesterName, DateTime? customDate}) async {
    return _ticketFromJson(await _request('POST', 'tickets/', body: {
      'category': category.name, 'deviceType': deviceType?.name, 'problemDescription': problemDescription,
      'department': department, 'officeLocation': officeLocation, 'phoneNumber': phoneNumber,
      'createdAt': (customDate ?? DateTime.now()).toIso8601String(),
    }));
  }
  @override
  Future<void> startWork(String id, String technicianName) async { await _request('POST', 'tickets/${Uri.encodeComponent(id)}/start-work/'); }
  @override
  Future<void> recordWork(String id, WorkRecord w) async {
    await _request('POST', 'tickets/${Uri.encodeComponent(id)}/work-record/', body: {
      'deviceType': w.deviceType, 'model': w.model, 'serialNumber': w.serialNumber,
      'problemDescription': w.problemDescription, 'toolsMaterials': w.toolsMaterials,
      'outcome': w.outcome.name, 'solutionDateTime': w.solutionDateTime.toIso8601String(),
    });
  }
  @override
  Future<void> rateService(String id, ServiceRating r) async {
    await _request('POST', 'tickets/${Uri.encodeComponent(id)}/rating/', body: {
      'quality': r.quality.name, 'speed': r.speed.name, 'ratedAt': r.ratedAt.toIso8601String(),
    });
  }
  @override
  Future<List<NotificationItem>> getNotifications() async {
    final items = (await _request('GET', 'notifications/'))['items'];
    return items is List ? items.whereType<Map>().map((e) => _notificationFromJson(Map<String, dynamic>.from(e))).toList() : [];
  }
  @override
  Future<void> markNotificationAsRead(String id) async { await _request('PATCH', 'notifications/${Uri.encodeComponent(id)}/', body: {'read': true}); }
}
