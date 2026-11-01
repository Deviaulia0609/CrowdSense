import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models.dart';
import 'secure_store.dart';

class ApiException implements Exception {
  final int status;
  final String message;
  ApiException(this.status, this.message);
  @override
  String toString() => 'ApiException($status): $message';
}

class ApiService {
  /// Emulator Android: 10.0.2.2. Ganti dengan --dart-define=API_URL=http://IP:8000
  static const baseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000');
  final SecureStore _store;
  String? _token;
  ApiService(this._store);

  Map<String, String> get _h => {
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<void> _ensureToken() async {
    _token ??= await _store.getString('token');
    if (_token != null) return;
    final r = await http
        .post(Uri.parse('$baseUrl/api/devices'), headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 10));
    _check(r);
    _token = (jsonDecode(r.body) as Map)['token'] as String;
    await _store.putString('token', _token!);
  }

  void _check(http.Response r) {
    if (r.statusCode == 401) {
      _token = null;
      _store.remove('token');
    }
    if (r.statusCode >= 400) throw ApiException(r.statusCode, r.body);
  }

  Future<dynamic> get(String path) async {
    await _ensureToken();
    final r = await http
        .get(Uri.parse('$baseUrl/api$path'), headers: _h)
        .timeout(const Duration(seconds: 10));
    _check(r);
    return jsonDecode(r.body);
  }

  Future<void> submitReport(PendingReport p) async {
    await _ensureToken();
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/reports'))
      ..headers.addAll(_h)
      ..fields.addAll({
        'client_id': p.id,
        'text': p.text,
        'tickers': p.tickers.join(','),
        'source_category': p.sourceCategory,
        'language_label': p.languageLabel,
        'simhash': p.simhash,
      });
    final path = p.imagePath;
    if (path != null && File(path).existsSync()) {
      req.files.add(await http.MultipartFile.fromPath('image', path));
    }
    final res = await http.Response.fromStream(
        await req.send().timeout(const Duration(seconds: 30)));
    _check(res);
  }
}
