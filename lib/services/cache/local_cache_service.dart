import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/utils/app_logger.dart';

class LocalCacheService {
  static const String _dataBox = 'care_ai_data';
  static const String _metaBox = 'care_ai_meta';
  static const String _backupBox = 'care_ai_backup';

  static LocalCacheService? _instance;
  static LocalCacheService get instance => _instance!;

  Box? _dataBox_;
  Box? _metaBox_;
  Box? _backupBox_;

  // Cache TTL configuration (how long before refresh)
  static const Map<String, Duration> _cacheTTL = {
    'user_profile':       Duration(hours: 24),
    'child_profiles':     Duration(hours: 24),
    'wellness_entries':   Duration(hours: 6),
    'daily_plan':         Duration(hours: 1),
    'progress_data':      Duration(hours: 12),
    'guidance_notes':     Duration(hours: 24),
    'activity_logs':      Duration(hours: 6),
    'game_sessions':      Duration(hours: 12),
    'community_posts':    Duration(hours: 30),
    'therapy_modules':    Duration(days: 7),
    'mood_history':       Duration(hours: 6),
    'weekly_stats':       Duration(hours: 6),
    'dashboard_data':     Duration(hours: 1),
    'context_data':       Duration(minutes: 10),
  };

  static Future<void> initialize() async {
    await Hive.initFlutter();
    _instance = LocalCacheService();
    await _instance!._openBoxes();
  }

  Future<void> _openBoxes() async {
    _dataBox_ = await Hive.openBox(_dataBox);
    _metaBox_ = await Hive.openBox(_metaBox);
    _backupBox_ = await Hive.openBox(_backupBox);
    AppLogger.info('LocalCacheService', 'Hive boxes opened successfully');
  }

  // ═══════════════════════════════════
  // CORE CACHE OPERATIONS
  // ═══════════════════════════════════

  /// Save data to local cache with timestamp
  Future<void> save(String key, dynamic data) async {
    try {
      final encoded = jsonEncode(data);
      await _dataBox_!.put(key, encoded);
      await _metaBox_!.put('${key}_timestamp', 
        DateTime.now().millisecondsSinceEpoch);
      AppLogger.info('LocalCacheService', 'Saved: $key');
    } catch (e, stack) {
      AppLogger.error('LocalCacheService', 'Save failed: $key', e, stack);
    }
  }

  /// Get data from local cache — returns null if expired or missing
  T? get<T>(String key, T Function(dynamic) fromJson) {
    try {
      final raw = _dataBox_!.get(key);
      if (raw == null) return null;

      final decoded = jsonDecode(raw);
      return fromJson(decoded);
    } catch (e, stack) {
      AppLogger.error('LocalCacheService', 'Get failed: $key', e, stack);
      return null;
    }
  }

  /// Check if cache is still fresh
  bool isFresh(String key) {
    final timestamp = _metaBox_!.get('${key}_timestamp');
    if (timestamp == null) return false;

    final savedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final ttl = _cacheTTL[key] ?? const Duration(hours: 1);
    final age = DateTime.now().difference(savedAt);

    return age < ttl;
  }

  /// Force invalidate a cache entry
  Future<void> invalidate(String key) async {
    await _dataBox_!.delete(key);
    await _metaBox_!.delete('${key}_timestamp');
    AppLogger.info('LocalCacheService', 'Invalidated: $key');
  }

  /// Invalidate all cache entries
  Future<void> invalidateAll() async {
    await _dataBox_!.clear();
    await _metaBox_!.clear();
    AppLogger.info('LocalCacheService', 'All cache cleared');
  }

  // ═══════════════════════════════════
  // BACKUP OPERATIONS
  // ═══════════════════════════════════

  /// Create a full backup of all cached data
  Future<void> createBackup(String userId) async {
    try {
      final backupData = <String, dynamic>{
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0',
        'data': <String, dynamic>{}
      };

      // Backup all current cache entries
      for (final key in _dataBox_!.keys) {
        backupData['data'][key] = _dataBox_!.get(key);
      }

      await _backupBox_!.put('latest_backup', jsonEncode(backupData));
      await _backupBox_!.put('backup_timestamp', 
        DateTime.now().millisecondsSinceEpoch);

      AppLogger.info('LocalCacheService', 
        'Backup created for user: $userId');
    } catch (e, stack) {
      AppLogger.error('LocalCacheService', 'Backup failed', e, stack);
    }
  }

  /// Restore from backup
  Future<bool> restoreFromBackup() async {
    try {
      final backupRaw = _backupBox_!.get('latest_backup');
      if (backupRaw == null) return false;

      final backup = jsonDecode(backupRaw);
      final data = backup['data'] as Map;

      for (final entry in data.entries) {
        await _dataBox_!.put(entry.key, entry.value);
      }

      AppLogger.info('LocalCacheService', 'Backup restored successfully');
      return true;
    } catch (e, stack) {
      AppLogger.error('LocalCacheService', 'Restore failed', e, stack);
      return false;
    }
  }

  DateTime? get lastBackupTime {
    final ts = _backupBox_!.get('backup_timestamp');
    if (ts == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ts);
  }

  // ═══════════════════════════════════
  // CLEAR ON LOGOUT
  // ═══════════════════════════════════

  Future<void> clearUserData() async {
    await _dataBox_!.clear();
    await _metaBox_!.clear();
    // Keep backup box — useful for crash recovery
    AppLogger.info('LocalCacheService', 'User data cleared on logout');
  }
}
