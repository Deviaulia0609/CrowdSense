import 'dart:convert';

/// Proses 3: SimHash 64-bit + Hamming distance untuk laporan mirip.
class SimHash {
  static const int _offset = -3750763034362895579; // FNV-1a 64 offset basis
  static const int _prime = 0x100000001b3;
  static const int threshold = 8; // maks. bit berbeda dianggap near-duplicate
  static const _stop = {
    'yang', 'dan', 'di', 'ke', 'dari', 'ada', 'katanya', 'kata', 'itu', 'ini',
    'mau', 'akan', 'untuk', 'dengan', 'saya', 'aku', 'nih', 'sih', 'ya'
  };

  static List<String> tokens(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty && !_stop.contains(w))
      .toList();

  static int _fnv(String s) {
    var h = _offset;
    for (final c in utf8.encode(s)) {
      h ^= c;
      h *= _prime;
    }
    return h;
  }

  static int fingerprint(String text) {
    final v = List<int>.filled(64, 0);
    for (final t in tokens(text)) {
      final h = _fnv(t);
      for (var b = 0; b < 64; b++) {
        v[b] += ((h >> b) & 1) == 1 ? 1 : -1;
      }
    }
    var f = 0;
    for (var b = 0; b < 64; b++) {
      if (v[b] > 0) f |= (1 << b);
    }
    return f;
  }

  static int hamming(int a, int b) {
    var x = a ^ b;
    var c = 0;
    while (x != 0) {
      x &= x - 1;
      c++;
    }
    return c;
  }

  static List<int> split(int f) => [(f >>> 32) & 0xFFFFFFFF, f & 0xFFFFFFFF];
  static int join(int hi, int lo) => (hi << 32) | lo;
  static String toHex(int f) {
    final p = split(f);
    return p[0].toRadixString(16).padLeft(8, '0') +
        p[1].toRadixString(16).padLeft(8, '0');
  }
}
