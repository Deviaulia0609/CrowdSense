import 'dart:math';

/// Proses 4: Multinomial Naive Bayes (Laplace smoothing) untuk gaya bahasa.
class NaiveBayes {
  final Map<String, int> _docs = {};
  final Map<String, Map<String, int>> _words = {};
  final Map<String, int> _total = {};
  final Set<String> _vocab = {};
  int _n = 0;

  static List<String> tokenize(String t) =>
      RegExp(r'[a-z0-9%]+').allMatches(t.toLowerCase()).map((m) => m[0]!).toList();

  void train(String label, String text) {
    _docs[label] = (_docs[label] ?? 0) + 1;
    _n++;
    final w = _words.putIfAbsent(label, () => {});
    for (final t in tokenize(text)) {
      w[t] = (w[t] ?? 0) + 1;
      _total[label] = (_total[label] ?? 0) + 1;
      _vocab.add(t);
    }
  }

  Map<String, double> proba(String text) {
    final toks = tokenize(text).where(_vocab.contains).toList();
    final logs = <String, double>{};
    for (final c in _docs.keys) {
      var lp = log(_docs[c]! / _n);
      final wc = _words[c]!;
      final tot = _total[c] ?? 0;
      for (final t in toks) {
        lp += log(((wc[t] ?? 0) + 1) / (tot + _vocab.length));
      }
      logs[c] = lp;
    }
    final m = logs.values.reduce(max);
    final out = <String, double>{};
    var sum = 0.0;
    logs.forEach((c, l) {
      final e = exp(l - m);
      out[c] = e;
      sum += e;
    });
    out.updateAll((c, e) => e / sum);
    return out;
  }

  String predict(String text) {
    if (tokenize(text).where(_vocab.contains).isEmpty) return 'netral';
    final p = proba(text);
    return p.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}

const languageLabels = {
  'netral': 'Informasi netral',
  'belum_pasti': 'Informasi belum pasti',
  'promosi': 'Bahasa promosi berlebihan',
  'tekanan': 'Bahasa penuh tekanan',
  'peringatan': 'Informasi peringatan',
};

const _seed = {
  'netral': [
    'laporan keuangan kuartal dirilis hari ini',
    'volume perdagangan saham terlihat stabil',
    'manajemen menyampaikan paparan publik',
    'harga saham bergerak sideways',
    'pembahasan saham ini meningkat di grup',
  ],
  'belum_pasti': [
    'katanya akan ada akuisisi belum tentu benar',
    'apakah benar rumor ini ada yang tahu',
    'info belum jelas sumbernya',
    'katanya mau ada pengumuman besok',
    'ada yang bisa konfirmasi kabar ini',
    'rumor belum terverifikasi',
  ],
  'promosi': [
    'pasti cuan 100% naik tinggi',
    'saham gorengan pasti terbang cuan besar',
    'jamin untung ratusan persen',
    'bakal melejit auto cuan',
    'peluang emas pasti naik',
  ],
  'tekanan': [
    'harus beli sekarang buruan',
    'jangan sampai ketinggalan kesempatan terakhir',
    'buruan serok sebelum terlambat',
    'segera masuk sekarang sebelum naik',
    'ayo borong sekarang jangan ragu',
  ],
  'peringatan': [
    'hati hati saham ini bisa turun',
    'waspada potensi penipuan pump and dump',
    'awas rumor palsu jangan terpancing',
    'risiko tinggi suspensi bursa',
    'peringatan saham sedang disuspensi',
  ],
};

/// Model awal dilatih dari contoh kecil; perbanyak data latih agar akurat.
NaiveBayes buildLanguageModel() {
  final nb = NaiveBayes();
  _seed.forEach((label, texts) {
    for (final t in texts) {
      nb.train(label, t);
    }
  });
  return nb;
}
