import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/aho_corasick.dart';
import '../core/default_stocks.dart';
import '../core/ewma.dart';
import '../core/naive_bayes.dart';
import '../core/simhash.dart';
import '../core/topk.dart';
import '../core/wsm.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../services/image_service.dart';
import '../services/secure_store.dart';
import '../services/sync_queue.dart';

class AppState extends ChangeNotifier {
  final store = SecureStore();
  late final ApiService api = ApiService(store);
  final cache = CacheService();
  late final SyncQueue queue = SyncQueue(store, api);
  final images = ImageService();
  final _nb = buildLanguageModel();
  static const _scorer = WeightedSum(relevanceWeights);

  AhoCorasick _detector = AhoCorasick(kDefaultStocks.map((s) => s.code));
  List<StockInfo> stocks = kDefaultStocks;
  Set<String> watchlist = {};
  Map<String, int> opens = {};
  List<int> _fingerprints = [];

  Map<String, dynamic>? _rawDashboard;
  bool dashboardFromCache = false, dashboardLoading = false;
  String? dashboardError;

  Future<void> init() async {
    await cache.load();
    await queue.load();
    queue.addListener(notifyListeners);
    final w = await store.getJson('watchlist');
    watchlist = w is List ? w.cast<String>().toSet() : {'BBCA', 'BMRI', 'TLKM'};
    final o = await store.getJson('opens');
    if (o is Map) opens = o.map((k, v) => MapEntry(k as String, (v as num).toInt()));
    final f = await store.getJson('fingerprints');
    if (f is List) {
      _fingerprints = f.map((e) => SimHash.join(e[0] as int, e[1] as int)).toList();
    }
    final cd = cache.get('dashboard');
    if (cd != null) {
      _rawDashboard = jsonDecode(cd) as Map<String, dynamic>;
      dashboardFromCache = true;
    }
    final cs = cache.get('stocks');
    if (cs != null) _setStocks(jsonDecode(cs) as List);
    queue.start();
    unawaited(_loadStocks());
  }

  void _setStocks(List raw) {
    stocks = raw.map((e) => StockInfo.fromJson(e as Map<String, dynamic>)).toList();
    _detector = AhoCorasick(stocks.map((s) => s.code));
  }

  Future<void> _loadStocks() async {
    try {
      final j = await api.get('/stocks') as List;
      cache.put('stocks', jsonEncode(j));
      _setStocks(j);
      notifyListeners();
    } catch (_) {}
  }

  // ---- komputasi lokal (proses 2, 3, 4) ----
  List<String> detectTickers(String text) => _detector.search(text);
  bool isDuplicate(String text) {
    final fp = SimHash.fingerprint(text);
    return _fingerprints.any((o) => SimHash.hamming(fp, o) <= SimHash.threshold);
  }

  String classify(String text) => _nb.predict(text);

  Future<void> submit({
    required String text,
    required List<String> tickers,
    required String sourceCategory,
    String? imagePath,
  }) async {
    final fp = SimHash.fingerprint(text);
    final p = PendingReport(
      id: const Uuid().v4(),
      text: text.trim(),
      tickers: tickers,
      sourceCategory: sourceCategory,
      languageLabel: classify(text),
      simhash: SimHash.toHex(fp),
      imagePath: imagePath,
      createdAt: DateTime.now(),
    );
    _fingerprints = [fp, ..._fingerprints].take(50).toList();
    await store.putJson('fingerprints', _fingerprints.map(SimHash.split).toList());
    await queue.enqueue(p);
  }

  // ---- data dari cloud + cache LRU (proses 8) ----
  Future<Cached<Map<String, dynamic>>> _fetch(String key, String path) async {
    try {
      final j = await api.get(path) as Map<String, dynamic>;
      cache.put(key, jsonEncode(j));
      return Cached(j, false);
    } catch (e) {
      final c = cache.get(key);
      if (c != null) return Cached(jsonDecode(c) as Map<String, dynamic>, true);
      rethrow;
    }
  }

  Future<void> refreshDashboard() async {
    dashboardLoading = true;
    dashboardError = null;
    notifyListeners();
    try {
      final r = await _fetch('dashboard', '/dashboard');
      _rawDashboard = r.data;
      dashboardFromCache = r.fromCache;
    } catch (_) {
      dashboardError = 'Tidak dapat memuat data. Tarik layar untuk mencoba lagi.';
    }
    dashboardLoading = false;
    notifyListeners();
  }

  Future<Cached<Map<String, dynamic>>> loadStock(String code) {
    opens[code] = (opens[code] ?? 0) + 1;
    unawaited(store.putJson('opens', opens));
    return _fetch('stock:$code', '/stocks/$code');
  }

  Future<Cached<Map<String, dynamic>>> loadTopic(int id) => _fetch('topic:$id', '/topics/$id');

  // ---- tren (proses 5) ----
  List<Trending> get trending {
    final raw = _rawDashboard;
    if (raw == null) return [];
    return (raw['trending'] as List).map((e) {
      final j = e as Map<String, dynamic>;
      final s = (j['series'] as List).map((x) => (x as num).toInt()).toList();
      return Trending(j['code'] as String, j['name'] as String, s,
          (j['total'] as num).toInt(), Ewma.classify(s));
    }).toList();
  }

  // ---- relevansi (proses 6) + top-5 heap (proses 7) ----
  double _relevance(AlertItem a) {
    final age = max(0, DateTime.now().difference(a.lastReportAt).inMinutes).toDouble();
    final open = a.tickers.map((t) => opens[t] ?? 0).fold(0, max);
    return _scorer.score({
      'watchlist': a.tickers.any(watchlist.contains) ? 1.0 : 0.0,
      'freshness': exp(-age / 60),
      'crowd': min(1.0, a.reportCount / 50),
      'diversity': min(1.0, a.sourceCount / 4),
      'preference': min(1.0, open / 5),
    });
  }

  List<AlertItem> get topAlerts {
    final raw = _rawDashboard;
    if (raw == null) return [];
    final heap = TopK<AlertItem>(5);
    for (final j in raw['alerts'] as List) {
      final a = AlertItem.fromJson(j as Map<String, dynamic>);
      a.score = _relevance(a);
      heap.offer(a, a.score);
    }
    return heap.sortedDesc();
  }

  Future<void> toggleWatchlist(String code) async {
    watchlist.contains(code) ? watchlist.remove(code) : watchlist.add(code);
    notifyListeners(); // ranking langsung berubah tanpa request baru
    await store.putJson('watchlist', watchlist.toList());
  }
}
