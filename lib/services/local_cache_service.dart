import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalCacheService {
  static const String _prefix = 'cache_';

  Future<void> save(String key, dynamic data, {Duration? expiration}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheData = {
      'data': data,
      'expires_at': expiration != null 
          ? DateTime.now().add(expiration).millisecondsSinceEpoch 
          : null,
    };
    await prefs.setString('$_prefix$key', jsonEncode(cacheData));
  }

  Future<dynamic> get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final String? cached = prefs.getString('$_prefix$key');
    if (cached == null) return null;

    final Map<String, dynamic> cacheData = jsonDecode(cached);
    final int? expiresAt = cacheData['expires_at'];

    if (expiresAt != null && DateTime.now().millisecondsSinceEpoch > expiresAt) {
      await remove(key);
      return null;
    }

    return cacheData['data'];
  }

  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$key');
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_prefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
