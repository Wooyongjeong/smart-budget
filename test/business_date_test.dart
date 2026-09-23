import 'package:flutter_test/flutter_test.dart';
import 'package:smart_budget/business_date.dart';

void main() {
  group('BusinessDateProvider (Asia/Seoul MVP policy)', () {
    test('uses Seoul date before UTC midnight', () {
      final date = BusinessDateProvider(
        utcNow: () => DateTime.utc(2026, 9, 22, 14, 59, 59),
      );

      expect(date.today, DateTime(2026, 9, 22));
    });

    test('crosses into the next Seoul date at UTC 15:00', () {
      final date = BusinessDateProvider(
        utcNow: () => DateTime.utc(2026, 9, 22, 15),
      );

      expect(date.today, DateTime(2026, 9, 23));
      expect(date.currentMonth, DateTime(2026, 9));
    });

    test('crosses the year boundary using the business offset', () {
      final date = BusinessDateProvider(
        utcNow: () => DateTime.utc(2026, 12, 31, 15),
      );

      expect(date.today, DateTime(2027, 1, 1));
      expect(date.currentMonth, DateTime(2027, 1));
    });
  });
}
