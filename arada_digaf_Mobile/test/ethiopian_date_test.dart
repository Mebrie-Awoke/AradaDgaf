import 'package:flutter_test/flutter_test.dart';
import 'package:arada_digaf/core/ethiopian_date.dart';

void main() {
  group('EthiopianDate Gregorian <-> Ethiopian conversions', () {
    test('Anchor 1: 2026-09-11 equals Meskerem 1, 2019 EC', () {
      final greg = DateTime(2026, 9, 11);
      final eth = EthiopianDate.fromDateTime(greg);

      expect(eth.year, 2019);
      expect(eth.month, 1);
      expect(eth.day, 1);
      expect(eth.monthNameEn, 'Meskerem');
      expect(eth.monthNameAm, 'መስከረም');

      // Round trip back to Gregorian
      final roundTrip = eth.toDateTime();
      expect(roundTrip.year, 2026);
      expect(roundTrip.month, 9);
      expect(roundTrip.day, 11);
    });

    test('Anchor 2: 2026-11-05 equals Tikimt 26, 2019 EC', () {
      final greg = DateTime(2026, 11, 5);
      final eth = EthiopianDate.fromDateTime(greg);

      expect(eth.year, 2019);
      expect(eth.month, 2);
      expect(eth.day, 26);
      expect(eth.monthNameEn, 'Tikimt');
      expect(eth.monthNameAm, 'ጥቅምት');

      // Round trip back to Gregorian
      final roundTrip = eth.toDateTime();
      expect(roundTrip.year, 2026);
      expect(roundTrip.month, 11);
      expect(roundTrip.day, 5);
    });

    test('Pagume boundary test: 2018 EC (non-leap year, 5 days)', () {
      // In 2018 EC (2018 % 4 == 2), Pagume has 5 days.
      final ethPagume5 = EthiopianDate(2018, 13, 5);
      expect(ethPagume5.isLeapYear, isFalse);
      expect(ethPagume5.maxDaysInMonth, 5);

      final gregPagume5 = ethPagume5.toDateTime();
      expect(gregPagume5.year, 2026);
      expect(gregPagume5.month, 9);
      expect(gregPagume5.day, 10);

      // Verify fromDateTime
      final ethConverted = EthiopianDate.fromDateTime(DateTime(2026, 9, 10));
      expect(ethConverted.year, 2018);
      expect(ethConverted.month, 13);
      expect(ethConverted.day, 5);

      // Next day is Meskerem 1, 2019 EC
      final nextDay = EthiopianDate.fromDateTime(DateTime(2026, 9, 11));
      expect(nextDay.year, 2019);
      expect(nextDay.month, 1);
      expect(nextDay.day, 1);
    });

    test('Leap year test: 2015 EC has Pagume 6', () {
      // 2015 % 4 == 3 is a leap year in Ethiopian calendar
      final ethLeap = EthiopianDate(2015, 13, 6);
      expect(ethLeap.isLeapYear, isTrue);
      expect(ethLeap.maxDaysInMonth, 6);

      final gregLeap = ethLeap.toDateTime();
      expect(gregLeap.year, 2023);
      expect(gregLeap.month, 9);
      expect(gregLeap.day, 11);

      final ethConverted = EthiopianDate.fromDateTime(DateTime(2023, 9, 11));
      expect(ethConverted.year, 2015);
      expect(ethConverted.month, 13);
      expect(ethConverted.day, 6);

      // Next day is Meskerem 1, 2016 EC (2023-09-12)
      final nextDay = EthiopianDate.fromDateTime(DateTime(2023, 9, 12));
      expect(nextDay.year, 2016);
      expect(nextDay.month, 1);
      expect(nextDay.day, 1);
    });

    test('Month navigation and formatting', () {
      final date = EthiopianDate(2019, 1, 15);
      expect(date.formatEC(), '15/01/2019 EC');
      expect(date.formatFull(isAmharic: false), 'Meskerem 15, 2019 EC');
      expect(date.formatFull(isAmharic: true), 'መስከረም 15, 2019 ዓ.ም');

      final nextMonth = date.nextMonth();
      expect(nextMonth.year, 2019);
      expect(nextMonth.month, 2);

      final prevMonth = date.previousMonth();
      expect(prevMonth.year, 2018);
      expect(prevMonth.month, 13);
    });
  });
}

