import 'dart:collection';

/// Proses 2: pencocokan banyak kode saham sekaligus (Aho-Corasick).
class AhoCorasick {
  final List<Map<String, int>> _next = [{}];
  final List<int> _fail = [0];
  final List<List<String>> _out = [[]];

  AhoCorasick(Iterable<String> patterns) {
    for (final p in patterns) {
      _add(p.toUpperCase());
    }
    _build();
  }

  void _add(String p) {
    if (p.isEmpty) return;
    var s = 0;
    for (final ch in p.split('')) {
      var n = _next[s][ch];
      if (n == null) {
        _next.add({});
        _fail.add(0);
        _out.add([]);
        n = _next.length - 1;
        _next[s][ch] = n;
      }
      s = n;
    }
    _out[s].add(p);
  }

  void _build() {
    final q = Queue<int>();
    for (final s in _next[0].values) {
      _fail[s] = 0;
      q.add(s);
    }
    while (q.isNotEmpty) {
      final r = q.removeFirst();
      _next[r].forEach((ch, s) {
        q.add(s);
        var f = _fail[r];
        while (f != 0 && !_next[f].containsKey(ch)) {
          f = _fail[f];
        }
        final t = _next[f][ch];
        _fail[s] = (t != null && t != s) ? t : 0;
        _out[s].addAll(_out[_fail[s]]);
      });
    }
  }

  static bool _alnum(int c) =>
      (c >= 48 && c <= 57) || (c >= 65 && c <= 90) || (c >= 97 && c <= 122);

  /// Mengembalikan kode unik sesuai urutan kemunculan (hanya kata utuh).
  List<String> search(String text) {
    final t = text.toUpperCase();
    final found = <String>[];
    var state = 0;
    for (var i = 0; i < t.length; i++) {
      final ch = t[i];
      while (state != 0 && !_next[state].containsKey(ch)) {
        state = _fail[state];
      }
      state = _next[state][ch] ?? 0;
      for (final p in _out[state]) {
        final start = i - p.length + 1;
        final before = start == 0 || !_alnum(t.codeUnitAt(start - 1));
        final after = i == t.length - 1 || !_alnum(t.codeUnitAt(i + 1));
        if (before && after && !found.contains(p)) found.add(p);
      }
    }
    return found;
  }
}
