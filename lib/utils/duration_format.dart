/// Formats a duration as e.g. "3 days, 4 hours" for an approximate storage
/// estimate — shared by the Recording and Storage screens so both report
/// the same figure the same way.
String formatApproxDuration(Duration duration) {
  final days = duration.inDays;
  final hours = duration.inHours % 24;
  if (days <= 0 && hours <= 0) return 'less than an hour';
  final parts = <String>[];
  if (days > 0) parts.add('$days day${days == 1 ? '' : 's'}');
  if (hours > 0) parts.add('$hours hour${hours == 1 ? '' : 's'}');
  return parts.join(', ');
}
