import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/lru.dart';

/// Cache JSON respons (LRU) yang dipersist agar bisa dibuka offline.
class CacheService {
  final _lru = LruCache<String, String>(40);

  Future<void> load() async {
    final s = (await SharedPreferences.getInstance()).getString('lru_cache');
    if (s == null) return;
    for (final e in jsonDecode(s) as List) {
      _lru.put(e[0] as String, e[1] as String);
    }
  }

  String? get(String key) {
    final v = _lru.get(key);
    if (v != null) unawaited(_persist());
    return v;
  }

  void put(String key, String value) {
    _lru.put(key, value);
    unawaited(_persist());
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('lru_cache',
        jsonEncode(_lru.entries.map((e) => [e.key, e.value]).toList()));
  }
}
