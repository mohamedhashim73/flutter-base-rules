import 'dart:convert';

import 'package:base/core/services/domain/firebase_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Last-known-good read cache. Firestore remains authoritative and all writes
/// continue to go through Firestore transactions.
class FirebaseCacheService {
  FirebaseCacheService(this._preferences, this._authService);

  final SharedPreferences _preferences;
  final FirebaseAuthService _authService;

  String _key(String collection) {
    final scope = _authService.organizationId ?? _authService.currentUser?.uid;
    return 'credexa_cache_${scope ?? 'anonymous'}_$collection';
  }

  String _markerKey(String collection) => '${_key(collection)}_last_sync_at';

  Future<void> write(String collection, List<Map<String, dynamic>> data) async {
    await _preferences.setString(_key(collection), jsonEncode(data));
  }

  List<Map<String, dynamic>>? read(String collection) {
    final raw = _preferences.getString(_key(collection));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } on FormatException {
      return null;
    }
  }

  int? readLastSyncAt(String collection) {
    try {
      return _preferences.getInt(_markerKey(collection));
    } catch (_) {
      return null;
    }
  }

  Future<void> writeLastSyncAt(String collection, int value) async {
    try {
      await _preferences.setInt(_markerKey(collection), value);
    } catch (_) {
      // Cache persistence is best-effort and must never block Firestore reads.
    }
  }

  Future<void> clearCurrentScope() async {
    try {
      final keys = _preferences
          .getKeys()
          .where((key) => key.startsWith('credexa_cache_'))
          .toList();
      for (final key in keys) {
        await _preferences.remove(key);
      }
    } catch (_) {
      // Logout must continue even when local cache cleanup is unavailable.
    }
  }
}
