String todayStamp([DateTime? now]) {
  final date = now ?? DateTime.now();
  return stampFromDate(date);
}

String stampFromDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

DateTime dateFromStamp(String stamp) {
  final parts = stamp.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

String previousStamp(String stamp) {
  final date = dateFromStamp(stamp);
  return stampFromDate(DateTime(date.year, date.month, date.day - 1));
}
