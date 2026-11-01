import 'dart:math';

/// Proses 9: Exponential backoff + jitter. Delay(n) = min(Max, Base * 2^n).
class Backoff {
  final Duration base, max;
  final double jitter;
  final Random _r;
  Backoff({
    this.base = const Duration(seconds: 5),
    this.max = const Duration(minutes: 5),
    this.jitter = 0.2,
    Random? random,
  }) : _r = random ?? Random();

  Duration delay(int n) {
    final raw = min(max.inMilliseconds, base.inMilliseconds * (1 << min(n, 20)));
    final j = 1 + (_r.nextDouble() * 2 - 1) * jitter;
    return Duration(milliseconds: (raw * j).round());
  }
}
