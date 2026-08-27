bool answersMatch(String guess, String expected) {
  return normalizeAnswer(guess) == normalizeAnswer(expected);
}

String normalizeAnswer(String value) {
  return value
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll('’', "'")
      .replaceAll('`', "'")
      .toLowerCase();
}
