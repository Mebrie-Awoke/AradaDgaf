/// Pure Dart implementation of Ethiopian Calendar (EC) conversion and utilities.
///
/// Ethiopian Calendar characteristics:
/// - 12 months of 30 days each.
/// - 13th month (Pagume) of 5 days (6 days in a leap year).
/// - Leap year occurs when `year % 4 == 3`.
class EthiopianDate implements Comparable<EthiopianDate> {
  final int year;
  final int month;
  final int day;

  const EthiopianDate(this.year, this.month, this.day);

  static const List<String> monthNamesEn = [
    'Meskerem',
    'Tikimt',
    'Hidar',
    'Tahsas',
    'Tir',
    'Yekatit',
    'Megabit',
    'Miazia',
    'Ginbot',
    'Sene',
    'Hamle',
    'Nehase',
    'Pagume',
  ];

  static const List<String> monthNamesAm = [
    'መስከረም',
    'ጥቅምት',
    'ህዳር',
    'ታህሳስ',
    'ጥር',
    'የካቲት',
    'መጋቢት',
    'ሚያዝያ',
    'ግንቦት',
    'ሰኔ',
    'ሐምሌ',
    'ነሐሴ',
    'ጳጉሜ',
  ];

  static const List<String> weekdayNamesEn = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> weekdayNamesAm = [
    'ሰኞ',
    'ማክሰኞ',
    'ረቡዕ',
    'ሐሙስ',
    'አርብ',
    'ቅዳሜ',
    'እሑድ',
  ];

  bool get isLeapYear => year % 4 == 3;

  int get maxDaysInMonth => month == 13 ? (isLeapYear ? 6 : 5) : 30;

  String get monthNameEn =>
      (month >= 1 && month <= 13) ? monthNamesEn[month - 1] : '';

  String get monthNameAm =>
      (month >= 1 && month <= 13) ? monthNamesAm[month - 1] : '';

  String monthName({required bool isAmharic}) =>
      isAmharic ? monthNameAm : monthNameEn;

  /// Returns 1 for Monday, 7 for Sunday (matching DateTime.weekday).
  int get weekday => toDateTime().weekday;

  /// Converts Gregorian [DateTime] to [EthiopianDate].
  factory EthiopianDate.fromDateTime(DateTime date) {
    final jdn = _gregorianToJdn(date.year, date.month, date.day);
    final r = (jdn - 1723856) % 1461;
    final n = (r % 365) + 365 * (r ~/ 1460);
    final year = 4 * ((jdn - 1723856) ~/ 1461) + (r ~/ 365) - (r ~/ 1460);
    final month = (n ~/ 30) + 1;
    final day = (n % 30) + 1;
    return EthiopianDate(year, month, day);
  }

  /// Converts this [EthiopianDate] to Gregorian [DateTime].
  DateTime toDateTime([int hour = 0, int minute = 0, int second = 0]) {
    final jdn = _ethiopianToJdn(year, month, day);
    final (gy, gm, gd) = _jdnToGregorian(jdn);
    return DateTime(gy, gm, gd, hour, minute, second);
  }

  /// Formatted as dd/mm/yyyy EC (e.g. "26/02/2019 EC")
  String formatEC() {
    final dd = day.toString().padLeft(2, '0');
    final mm = month.toString().padLeft(2, '0');
    return '$dd/$mm/$year EC';
  }

  /// Formatted with month name, e.g. "Meskerem 1, 2019 EC" or "መስከረም 1, 2019 ዓ.ም"
  String formatFull({bool isAmharic = false}) {
    if (isAmharic) {
      return '$monthNameAm $day, $year ዓ.ም';
    }
    return '$monthNameEn $day, $year EC';
  }

  static int _gregorianToJdn(int year, int month, int day) {
    final a = (14 - month) ~/ 12;
    final y = year + 4800 - a;
    final m = month + 12 * a - 3;
    return day + (153 * m + 2) ~/ 5 + 365 * y + y ~/ 4 - y ~/ 100 + y ~/ 400 - 32045;
  }

  static (int, int, int) _jdnToGregorian(int jdn) {
    final l = jdn + 68569;
    final n = (4 * l) ~/ 146097;
    final l2 = l - (146097 * n + 3) ~/ 4;
    final i = (4000 * (l2 + 1)) ~/ 1461001;
    final l3 = l2 - (1461 * i) ~/ 4 + 31;
    final j = (80 * l3) ~/ 2447;
    final d = l3 - (2447 * j) ~/ 80;
    final l4 = j ~/ 11;
    final m = j + 2 - 12 * l4;
    final y = 100 * (n - 49) + i + l4;
    return (y, m, d);
  }

  static int _ethiopianToJdn(int year, int month, int day) {
    return (1723856 + 365) + 365 * (year - 1) + (year ~/ 4) + (month - 1) * 30 + (day - 1);
  }

  EthiopianDate nextMonth() {
    if (month == 13) {
      return EthiopianDate(year + 1, 1, 1);
    }
    return EthiopianDate(year, month + 1, 1);
  }

  EthiopianDate previousMonth() {
    if (month == 1) {
      final prevYear = year - 1;
      return EthiopianDate(prevYear, 13, 1);
    }
    return EthiopianDate(year, month - 1, 1);
  }

  @override
  int compareTo(EthiopianDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EthiopianDate &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month &&
          day == other.day;

  @override
  int get hashCode => year.hashCode ^ month.hashCode ^ day.hashCode;

  @override
  String toString() => '$year-$month-$day EC';
}

