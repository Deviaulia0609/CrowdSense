/// Proses 7: Min-Heap berukuran K untuk memilih alert teratas.
class _Entry<T> {
  final T item;
  final double score;
  _Entry(this.item, this.score);
}

class TopK<T> {
  final int k;
  final List<_Entry<T>> _h = [];
  TopK(this.k);

  void offer(T item, double score) {
    if (k <= 0) return;
    if (_h.length < k) {
      _h.add(_Entry(item, score));
      _up(_h.length - 1);
    } else if (score > _h[0].score) {
      _h[0] = _Entry(item, score);
      _down(0);
    }
  }

  void _up(int i) {
    while (i > 0) {
      final p = (i - 1) ~/ 2;
      if (_h[p].score <= _h[i].score) break;
      final t = _h[p];
      _h[p] = _h[i];
      _h[i] = t;
      i = p;
    }
  }

  void _down(int i) {
    final n = _h.length;
    while (true) {
      var m = i;
      final l = 2 * i + 1, r = l + 1;
      if (l < n && _h[l].score < _h[m].score) m = l;
      if (r < n && _h[r].score < _h[m].score) m = r;
      if (m == i) break;
      final t = _h[m];
      _h[m] = _h[i];
      _h[i] = t;
      i = m;
    }
  }

  List<T> sortedDesc() {
    final c = [..._h]..sort((a, b) => b.score.compareTo(a.score));
    return c.map((e) => e.item).toList();
  }
}
