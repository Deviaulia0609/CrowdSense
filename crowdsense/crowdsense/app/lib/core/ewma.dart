/// Proses 5: Exponentially Weighted Moving Average untuk tren aktivitas.
enum Trend { turun, stabil, naik, naikCepat }

String trendLabel(Trend t) => switch (t) {
      Trend.turun => 'Turun ↓',
      Trend.stabil => 'Stabil →',
      Trend.naik => 'Naik ↑',
      Trend.naikCepat => 'Naik Cepat ↑↑',
    };

class Ewma {
  static List<double> smooth(List<num> x, {double alpha = 0.5}) {
    if (x.isEmpty) return [];
    final s = <double>[x.first.toDouble()];
    for (var i = 1; i < x.length; i++) {
      s.add(alpha * x[i] + (1 - alpha) * s[i - 1]);
    }
    return s;
  }

  static Trend classify(List<num> x, {double alpha = 0.5}) {
    if (x.length < 2) return Trend.stabil;
    final s = smooth(x, alpha: alpha);
    final prev = s[s.length - 2];
    final change = (s.last - prev) / (prev < 1 ? 1 : prev);
    if (change >= 0.5) return Trend.naikCepat;
    if (change >= 0.1) return Trend.naik;
    if (change <= -0.1) return Trend.turun;
    return Trend.stabil;
  }
}
