import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arada_digaf/models/user.dart';
import 'package:arada_digaf/repository/api_ticket_repository.dart';
import 'package:arada_digaf/repository/mock_ticket_repository.dart';
import 'package:arada_digaf/screens/registration_screen.dart';
import 'package:arada_digaf/state/app_scope.dart';
import 'package:arada_digaf/state/app_state.dart';

void main() {
  group('Registration and Repository Tests', () {
    late MockTicketRepository mockRepo;

    setUp(() {
      mockRepo = MockTicketRepository();
    });

    test('MockTicketRepository register employee returns pending status and reference number', () async {
      final res = await mockRepo.register(
        role: UserRole.employee,
        fullName: 'Abebe Bikila',
        employeeId: 'EMP-9901',
        username: 'abebe',
        password: 'Password123',
        confirmPassword: 'Password123',
        phone: '0911223344',
        department: 'Finance Department',
      );

      expect(res['status'], 'pending');
      expect(res['reference_number'], startsWith('REG-2026-'));
      expect(res['user']['username'], 'abebe');
      expect(res['user']['role'], 'employee');
    });

    test('MockTicketRepository checkRegistrationStatus returns registration info', () async {
      final res = await mockRepo.register(
        role: UserRole.technician,
        fullName: 'Kidus Tech',
        employeeId: 'TECH-8801',
        username: 'kidus_tech',
        password: 'Password123',
        confirmPassword: 'Password123',
        phone: '+251912345678',
        department: 'IT Office',
        specialties: ['hardware', 'network'],
      );

      final ref = res['reference_number'] as String;
      final statusRes = await mockRepo.checkRegistrationStatus(referenceNumber: ref);

      expect(statusRes['reference_number'], ref);
      expect(statusRes['username'], 'kidus_tech');
      expect(statusRes['status'], 'pending');
    });

    test('MockTicketRepository rejects login for pending account with code account_pending', () async {
      await mockRepo.register(
        role: UserRole.employee,
        fullName: 'Pending User',
        employeeId: 'EMP-7701',
        username: 'pending_user',
        password: 'Password123',
        confirmPassword: 'Password123',
        phone: '0922334455',
        department: 'HR Department',
      );

      try {
        await mockRepo.login('pending_user', 'Password123', UserRole.employee);
        fail('Should have thrown ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 403);
        expect(e.code, 'account_pending');
      }
    });

    test('MockTicketRepository prevents duplicate registration', () async {
      await mockRepo.register(
        role: UserRole.employee,
        fullName: 'First Register',
        employeeId: 'EMP-1111',
        username: 'unique_user',
        password: 'Password123',
        confirmPassword: 'Password123',
        phone: '0933445566',
        department: 'Legal Affairs',
      );

      expect(
        mockRepo.register(
          role: UserRole.employee,
          fullName: 'Second Register',
          employeeId: 'EMP-1111',
          username: 'unique_user',
          password: 'Password123',
          confirmPassword: 'Password123',
          phone: '0933445566',
          department: 'Legal Affairs',
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('AppState Registration Integration', () {
    test('AppState register and checkStatus works with repository', () async {
      final mockRepo = MockTicketRepository();
      final appState = AppState(repository: mockRepo);

      final res = await appState.register(
        role: UserRole.employee,
        fullName: 'Hana Girma',
        employeeId: 'EMP-5501',
        username: 'hana_g',
        password: 'Password123',
        confirmPassword: 'Password123',
        phone: '0944556677',
        department: 'Planning Department',
      );

      expect(res['reference_number'], startsWith('REG-2026-'));

      final check = await appState.checkRegistrationStatus(
        referenceNumber: res['reference_number'] as String,
      );
      expect(check['status'], 'pending');
      expect(check['username'], 'hana_g');
    });
  });

  group('RegistrationScreen Widget Tests', () {
    testWidgets('renders registration screen with role toggle and step 1 fields', (tester) async {
      final mockRepo = MockTicketRepository();
      final appState = AppState(repository: mockRepo);
      // Toggle to English for predictable string matching
      appState.toggleLanguage();

      await tester.pumpWidget(
        MaterialApp(
          home: AppScope(
            state: appState,
            child: const RegistrationScreen(),
          ),
        ),
      );

      // Verify title is rendered
      expect(find.text('Create Account'), findsOneWidget);
      // Verify role options are rendered
      expect(find.text('Employee'), findsOneWidget);
      expect(find.text('Technician'), findsOneWidget);

      // Verify step 1 text fields exist (fullName, employeeId, username, password, confirmPassword)
      expect(find.byType(TextField), findsNWidgets(5));
      expect(find.text('Next ->'), findsOneWidget);
    });

    testWidgets('step 1 validation blocks progress when fields are empty', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockRepo = MockTicketRepository();
      final appState = AppState(repository: mockRepo);
      appState.toggleLanguage();

      await tester.pumpWidget(
        MaterialApp(
          home: AppScope(
            state: appState,
            child: const RegistrationScreen(),
          ),
        ),
      );

      // Tap Next without filling in fields
      await tester.ensureVisible(find.text('Next ->'));
      await tester.tap(find.text('Next ->'));
      await tester.pump();

      // Error message should appear
      expect(find.text(appState.s.get('name_min_chars')), findsOneWidget);
    });
  });
}
