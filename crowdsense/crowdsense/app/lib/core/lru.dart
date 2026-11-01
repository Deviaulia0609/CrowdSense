import 'dart:collection';

/// Proses 8: Least Recently Used cache (item terbaru di akhir map).
class LruCache<K, V> {
  final int capacity;
  final LinkedHashMap<K, V> _m = LinkedHashMap();
  LruCache(this.capacity);

  V? get(K key) {
    if (!_m.containsKey(key)) return null;
    final v = _m.remove(key) as V;
    _m[key] = v;
    return v;
  }

  void put(K key, V value) {
    _m.remove(key);
    _m[key] = value;
    while (_m.length > capacity) {
      _m.remove(_m.keys.first);
    }
  }

  Iterable<MapEntry<K, V>> get entries => _m.entries;
  List<K> get keysOldestFirst => _m.keys.toList();
}
