/// Small date helpers shared by the recurrence and occurrence layers.
///
/// All occurrence keys use a local-date integer `yyyyMMdd` (e.g. 20261017) so
/// they sort naturally and survive timezone/day-boundary changes.

library;

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// yyyyMMdd integer key for a local date.
int ymdKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

DateTime fromYmdKey(int key) {
  final year = key ~/ 10000;
  final month = (key ~/ 100) % 100;
  final day = key % 100;
  return DateTime(year, month, day);
}

/// Number of whole days between two local dates (ignores time of day).
int daysBetween(DateTime a, DateTime b) =>
    dateOnly(b).difference(dateOnly(a)).inDays;
