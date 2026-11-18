import 'package:flutter_test/flutter_test.dart';
import 'package:arada_digaf/state/app_state.dart';
import 'package:arada_digaf/core/strings.dart';

void main() {
  group('Arada Digaf app state', () {
    late AppState appState;

    setUp(() {
      appState = AppState();
    });

    test('starts without demo tickets, notifications, or a demo user', () {
      expect(appState.currentUser, isNull);
      expect(appState.tickets, isEmpty);
      expect(appState.notifications, isEmpty);
      expect(appState.isLoading, isFalse);
    });

    test('language switching toggles between Amharic and English', () {
      expect(appState.language, AppLanguage.amharic);
      expect(appState.s.get('app_name'), 'አራዳ ድጋፍ');

      appState.toggleLanguage();
      expect(appState.language, AppLanguage.english);
      expect(appState.s.get('app_name'), 'Arada Digaf');
    });
  });
}
