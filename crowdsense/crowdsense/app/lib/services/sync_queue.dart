import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../core/backoff.dart';
import '../models.dart';
import 'api_service.dart';
import 'secure_store.dart';

/// Proses 9: antrean lokal terenkripsi + retry exponential backoff.
class SyncQueue extends ChangeNotifier {
  SyncQueue(this._store, this._api);
  final SecureStore _store;
  final ApiService _api;
  final _backoff = Backoff();
  List<PendingReport> items = [];
  int _attempt = 0;
  Timer? _timer;
  bool _busy = false;
  StreamSubscription? _sub;

  Future<void> load() async {
    final j = await _store.getJson('queue');
    if (j is List) {
      items = j.map((e) => PendingReport.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  void start() {
    _sub = Connectivity().onConnectivityChanged.listen((r) {
      if (!r.contains(ConnectivityResult.none)) flush();
    });
    flush();
  }

  Future<void> _save() => _store.putJson('queue', items.map((e) => e.toJson()).toList());

  Future<void> enqueue(PendingReport p) async {
    items.add(p);
    await _save();
    notifyListeners();
    unawaited(flush());
  }

  Future<void> flush() async {
    if (_busy || items.isEmpty) return;
    _busy = true;
    _timer?.cancel();
    try {
      while (items.isNotEmpty) {
        try {
          await _api.submitReport(items.first);
        } on ApiException catch (e) {
          final permanent = e.status >= 400 && e.status < 500 && e.status != 429 && e.status != 401;
          if (!permanent) rethrow; // 4xx validasi: buang agar antrean tidak macet
        }
        final done = items.removeAt(0);
        try {
          if (done.imagePath != null) File(done.imagePath!).deleteSync();
        } catch (_) {}
        _attempt = 0;
        await _save();
        notifyListeners();
      }
    } catch (_) {
      final d = _backoff.delay(_attempt++);
      _timer = Timer(d, () => flush());
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}
