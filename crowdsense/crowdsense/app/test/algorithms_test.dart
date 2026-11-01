import 'package:crowdsense/core/aho_corasick.dart';
import 'package:crowdsense/core/backoff.dart';
import 'package:crowdsense/core/ewma.dart';
import 'package:crowdsense/core/lru.dart';
import 'package:crowdsense/core/naive_bayes.dart';
import 'package:crowdsense/core/simhash.dart';
import 'package:crowdsense/core/topk.dart';
import 'package:crowdsense/core/wsm.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Aho-Corasick menemukan kode saham sebagai kata utuh', () {
    final ac = AhoCorasick(['BBCA', 'BBRI', 'BMRI', 'TLKM']);
    expect(ac.search('Saya melihat pembahasan BBCA, BBRI dan TLKM meningkat'), ['BBCA', 'BBRI', 'TLKM']);
    expect(ac.search('XBBCAX bukan kode'), isEmpty);
  });

  test('SimHash: teks hampir sama lebih dekat dari teks berbeda', () {
    final a = SimHash.fingerprint('Rumor ABCD akan melakukan akuisisi perusahaan X.');
    final b = SimHash.fingerprint('Ada rumor ABCD katanya mau akuisisi perusahaan X.');
    final c = SimHash.fingerprint('Dividen TLKM dibagikan bulan depan kepada pemegang saham');
    expect(SimHash.hamming(a, b), lessThan(SimHash.hamming(a, c)));
    expect(SimHash.hamming(a, a), 0);
    expect(SimHash.join(SimHash.split(a)[0], SimHash.split(a)[1]), a);
  });

  test('Naive Bayes mengenali bahasa promosi dan tekanan', () {
    final nb = buildLanguageModel();
    expect(nb.predict('pasti cuan 100% jamin untung'), 'promosi');
    expect(nb.predict('buruan beli sekarang jangan sampai ketinggalan'), 'tekanan');
  });

  test('EWMA: contoh dokumen TIA = naik cepat', () {
    expect(Ewma.classify([12, 18, 25, 47, 81]), Trend.naikCepat);
    expect(Ewma.classify([10, 10, 10, 10, 10]), Trend.stabil);
    expect(Ewma.classify([80, 60, 40, 20, 10]), Trend.turun);
  });

  test('WSM contoh dokumen = 0.9', () {
    const w = WeightedSum(relevanceWeights);
    final s = w.score({'watchlist': 1, 'freshness': .9, 'crowd': .8, 'diversity': .6, 'preference': 1});
    expect(s, closeTo(0.9, 1e-9));
  });

  test('TopK menyimpan 5 skor tertinggi', () {
    final h = TopK<int>(5);
    for (var i = 0; i < 100; i++) {
      h.offer(i, i.toDouble());
    }
    expect(h.sortedDesc(), [99, 98, 97, 96, 95]);
  });

  test('LRU membuang item paling lama tidak dipakai', () {
    final c = LruCache<String, int>(3)..put('BBCA', 1)..put('TLKM', 2)..put('BMRI', 3);
    c.get('BBCA');
    c.put('ANTM', 4);
    expect(c.get('TLKM'), isNull);
    expect(c.get('BBCA'), 1);
  });

  test('Backoff berlipat ganda dan dibatasi MaxDelay', () {
    final b = Backoff(jitter: 0);
    expect(b.delay(0), const Duration(seconds: 5));
    expect(b.delay(1), const Duration(seconds: 10));
    expect(b.delay(2), const Duration(seconds: 20));
    expect(b.delay(30), const Duration(minutes: 5));
  });
}
