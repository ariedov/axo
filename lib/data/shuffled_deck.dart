import 'dart:math';

class ShuffledDeck<T> {
  ShuffledDeck({required List<T> items, required Random random})
    : _items = List<T>.unmodifiable(items),
      _random = random {
    _fill();
  }

  final List<T> _items;
  final Random _random;
  final List<T> _queue = [];
  T? _last;

  T next() {
    if (_queue.isEmpty) _fill();
    final item = _queue.removeLast();
    _last = item;
    return item;
  }

  void _fill() {
    _queue
      ..clear()
      ..addAll(_items)
      ..shuffle(_random);
    if (_queue.length > 1 && _last != null && _queue.last == _last) {
      _queue.insert(0, _queue.removeLast());
    }
  }
}
