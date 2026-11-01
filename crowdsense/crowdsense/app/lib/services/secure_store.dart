import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Proses 10: AES-256-GCM. Kunci disimpan di Android Keystore / iOS Keychain
/// (lewat flutter_secure_storage); data terenkripsi disimpan di preferences.
class SecureStore {
  static const _keyName = 'crowdsense_aes_key';
  final _vault = const FlutterSecureStorage();
  final _algo = AesGcm.with256bits();
  SecretKey? _cached;

  Future<SecretKey> _key() async {
    if (_cached != null) return _cached!;
    final b64 = await _vault.read(key: _keyName);
    if (b64 == null) {
      final k = await _algo.newSecretKey();
      await _vault.write(key: _keyName, value: base64Encode(await k.extractBytes()));
      return _cached = k;
    }
    return _cached = SecretKey(base64Decode(b64));
  }

  Future<String> encrypt(String plain) async {
    final box = await _algo.encrypt(utf8.encode(plain), secretKey: await _key());
    return base64Encode(box.concatenation());
  }

  Future<String> decrypt(String b64) async {
    final box = SecretBox.fromConcatenation(base64Decode(b64),
        nonceLength: 12, macLength: 16);
    return utf8.decode(await _algo.decrypt(box, secretKey: await _key()));
  }

  Future<void> putString(String name, String value) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('enc_$name', await encrypt(value));
  }

  Future<String?> getString(String name) async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString('enc_$name');
    if (v == null) return null;
    try {
      return await decrypt(v);
    } catch (_) {
      return null; // rusak / dimodifikasi: tag GCM tidak cocok
    }
  }

  Future<void> remove(String name) async =>
      (await SharedPreferences.getInstance()).remove('enc_$name');

  Future<void> putJson(String name, Object data) => putString(name, jsonEncode(data));
  Future<dynamic> getJson(String name) async {
    final s = await getString(name);
    return s == null ? null : jsonDecode(s);
  }
}
