/// Provides a single business-date policy, independent of the device timezone.
///
/// MVP uses the fixed Asia/Seoul offset. A future household-specific policy can
/// supply a different offset without changing date consumers.
class BusinessDateProvider {
  const BusinessDateProvider({
    DateTime Function()? utcNow,
    this.utcOffset = const Duration(hours: 9),
  }) : _utcNow = utcNow ?? _systemUtcNow;

  static final BusinessDateProvider current = BusinessDateProvider();

  final DateTime Function() _utcNow;
  final Duration utcOffset;

  DateTime get now => _utcNow().toUtc().add(utcOffset);

  DateTime get today {
    final value = now;
    return DateTime(value.year, value.month, value.day);
  }

  DateTime get currentMonth {
    final value = now;
    return DateTime(value.year, value.month);
  }
}

DateTime _systemUtcNow() => DateTime.now().toUtc();
