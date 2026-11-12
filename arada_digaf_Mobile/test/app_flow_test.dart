import 'package:flutter_test/flutter_test.dart';
import 'package:arada_digaf/state/app_state.dart';
import 'package:arada_digaf/models/ticket.dart';
import 'package:arada_digaf/models/user.dart';
import 'package:arada_digaf/core/strings.dart';

void main() {
  group('Arada Digaf State and Flow Tests', () {
    late AppState appState;

    setUp(() {
      appState = AppState();
    });

    test('Initial state has seeded tickets and notifications', () async {
      await Future.delayed(const Duration(milliseconds: 50));
      expect(appState.tickets.length, 3);
      expect(appState.tickets[0].id, 'AD-2026-0423');
      expect(appState.tickets[1].id, 'AD-2026-0419');
      expect(appState.tickets[2].id, 'AD-2026-0415');
      expect(appState.notifications.isNotEmpty, isTrue);
    });

    test('Login authentication succeeds for employee and technician', () {
      // Invalid credentials
      expect(appState.login('wrong', '1234', UserRole.employee), isFalse);
      expect(appState.currentUser, isNull);

      // Employee login
      expect(appState.login('selam', '1234', UserRole.employee), isTrue);
      expect(appState.currentUser?.fullName, 'Selam Tesfaye');
      expect(appState.currentUser?.role, UserRole.employee);

      // Technician login
      expect(appState.login('abel', '1234', UserRole.technician), isTrue);
      expect(appState.currentUser?.fullName, 'Abel Mekonnen');
      expect(appState.currentUser?.role, UserRole.technician);
    });

    test('Create new ticket increments ID and adds to top of list', () async {
      appState.login('selam', '1234', UserRole.employee);

      final draft = TicketDraft(
        category: ServiceCategory.maintenance,
        deviceType: DeviceType.computer,
        problemDescription: 'Test monitor power issue',
        department: 'Finance Office',
        officeLocation: 'Room 101',
        phoneNumber: '+251 91 111 2222',
      );

      final newTicket = await appState.submitTicket(draft);
      expect(newTicket, isNotNull);
      expect(newTicket!.id, 'AD-2026-0424');
      expect(appState.tickets.first.id, 'AD-2026-0424');
      expect(newTicket.status, TicketStatus.submitted);

      // Next ticket increments again
      final draft2 = draft.copy();
      final newTicket2 = await appState.submitTicket(draft2);
      expect(newTicket2!.id, 'AD-2026-0425');
    });

    test('Technician startWork updates status to inProgress and assigns technician', () async {
      appState.login('abel', '1234', UserRole.technician);

      await appState.startWork('AD-2026-0423');
      final ticket = appState.tickets.firstWhere((t) => t.id == 'AD-2026-0423');

      expect(ticket.status, TicketStatus.inProgress);
      expect(ticket.assignedTechnician, 'Abel Mekonnen');
    });

    test('Technician recordWork updates status to resolved and adds work record', () async {
      appState.login('abel', '1234', UserRole.technician);

      final workRecord = WorkRecord(
        deviceType: 'Computer',
        model: 'Dell OptiPlex 7090',
        serialNumber: 'SN778899',
        problemDescription: 'Fixed power supply cable',
        toolsMaterials: 'Power cable',
        outcome: WorkOutcome.solutionGiven,
        solutionDateTime: DateTime.now(),
      );

      await appState.recordWork('AD-2026-0423', workRecord);
      final ticket = appState.tickets.firstWhere((t) => t.id == 'AD-2026-0423');

      expect(ticket.status, TicketStatus.resolved);
      expect(ticket.workRecord, isNotNull);
      expect(ticket.workRecord?.model, 'Dell OptiPlex 7090');
    });

    test('Employee rateTicket saves rating', () async {
      final rating = ServiceRating(
        quality: RatingLevel.veryHigh,
        speed: RatingLevel.high,
        ratedAt: DateTime.now(),
      );

      await appState.rateTicket('AD-2026-0415', rating);
      final ticket = appState.tickets.firstWhere((t) => t.id == 'AD-2026-0415');

      expect(ticket.rating, isNotNull);
      expect(ticket.rating?.quality, RatingLevel.veryHigh);
      expect(ticket.rating?.speed, RatingLevel.high);
    });

    test('Offline simulation retains draft and prevents submission until offline disabled', () async {
      appState.login('selam', '1234', UserRole.employee);
      appState.setSimulateOffline(true);

      final draft = TicketDraft(
        category: ServiceCategory.software,
        problemDescription: 'Offline test software issue description',
        department: 'HR Department',
      );

      final result = await appState.submitTicket(draft);
      expect(result, isNull);
      expect(appState.pendingDraft, isNotNull);
      expect(appState.pendingDraft?.department, 'HR Department');

      // Now disable offline and submit draft
      appState.setSimulateOffline(false);
      final submitted = await appState.submitTicket(appState.pendingDraft!);
      expect(submitted, isNotNull);
      expect(appState.pendingDraft, isNull);
    });

    test('Language switching toggles between Amharic and English', () {
      expect(appState.language, AppLanguage.amharic);
      expect(appState.s.get('app_name'), 'አራዳ ድጋፍ');

      appState.toggleLanguage();
      expect(appState.language, AppLanguage.english);
      expect(appState.s.get('app_name'), 'Arada Digaf');
    });
  });
}

