import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_cache_service.dart';
import 'smart_data_repository.dart';
import '../../core/utils/app_logger.dart';

class SyncManager {
  final SmartDataRepository _repository;
  final LocalCacheService _cache = LocalCacheService.instance;

  Timer? _backupTimer;
  Timer? _syncTimer;
  Timer? _dailyUpdateTimer;
  StreamSubscription? _connectivitySub;
  bool _isSyncing = false;

  // Sync schedule config
  static const _backupInterval = Duration(hours: 6);
  static const _periodicSyncInterval = Duration(hours: 1);
  static const _dailyFirebaseUpdateInterval = Duration(hours: 24);

  SyncManager(this._repository);

  /// Call this after user logs in
  Future<void> startSync(String userId) async {
    AppLogger.info('SyncManager', 'Starting sync for user: $userId');

    // Initial sync on login
    await _performSync(userId);

    // Periodic sync every hour
    _syncTimer = Timer.periodic(_periodicSyncInterval, (_) async {
      await _performSync(userId);
    });

    // Backup every 6 hours
    _backupTimer = Timer.periodic(_backupInterval, (_) async {
      await _performBackup(userId);
    });

    // Sync when connectivity restored
    _connectivitySub = Connectivity().onConnectivityChanged
      .listen((results) async {
        final isOnline = results.any(
          (r) => r != ConnectivityResult.none);
        if (isOnline && !_isSyncing) {
          AppLogger.info('SyncManager', 
            'Connectivity restored — syncing');
          await _performSync(userId);
        }
      });

    // Run immediately if daily update is overdue
    if (await _shouldRunDailyUpdate()) {
      await _pushDailyUpdateToFirebase(userId);
    }

    // Schedule daily updates every 24 hours
    _dailyUpdateTimer = Timer.periodic(
      _dailyFirebaseUpdateInterval, (_) async {
        await _pushDailyUpdateToFirebase(userId);
      });
  }

  /// Perform full data sync — invalidates and re-fetches all data
  Future<void> _performSync(String userId) async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      AppLogger.info('SyncManager', 'Performing scheduled sync...');

      final today = DateTime.now().toIso8601String().substring(0, 10);

      // Invalidate stale entries (let SmartDataRepository re-fetch)
      await _cache.invalidate('dashboard_data');
      await _cache.invalidate('mood_history_14');
      await _cache.invalidate('daily_plan_$today');
      await _cache.invalidate('context_data');

      // Pre-warm cache with fresh data
      await _repository.getDashboardData(userId);
      await _repository.getMoodHistory(userId);
      await _repository.getDailyPlan(userId, today);

      AppLogger.info('SyncManager', 'Sync completed successfully');
    } catch (e, stack) {
      AppLogger.error('SyncManager', 'Sync failed', e, stack);
    } finally {
      _isSyncing = false;
    }
  }

  /// Create local backup of all cached data
  Future<void> _performBackup(String userId) async {
    try {
      AppLogger.info('SyncManager', 'Creating backup...');
      await _cache.createBackup(userId);

      // Also push backup to Firebase for cloud safety
      await _pushBackupToFirebase(userId);

      AppLogger.info('SyncManager', 'Backup completed');
    } catch (e, stack) {
      AppLogger.error('SyncManager', 'Backup failed', e, stack);
    }
  }

  /// Push backup to Firebase as a safety net
  Future<void> _pushBackupToFirebase(String userId) async {
    try {
      final backupTimestamp = _cache.lastBackupTime;
      if (backupTimestamp == null) return;

      await FirebaseFirestore.instance
        .collection('user_backups')
        .doc(userId)
        .set({
          'lastBackup': backupTimestamp.toIso8601String(),
          'deviceBackupExists': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
    } catch (e) {
      // Non-critical — local backup still exists
      AppLogger.error('SyncManager', 
        'Firebase backup record update failed', e);
    }
  }

  /// Pushes all locally cached user data to Firebase once per day
  /// Costs exactly 1 Firebase write per day per user
  Future<void> _pushDailyUpdateToFirebase(String userId) async {
    try {
      AppLogger.info('SyncManager', 'Daily Firebase update starting...');

      final cache = LocalCacheService.instance;

      final profileData = cache.get<Map<String, dynamic>>(
        'user_profile', (j) => Map<String, dynamic>.from(j));

      final wellnessData = cache.get<List>(
        'wellness_entries_7d', (j) => j as List);

      final planData = cache.get<Map<String, dynamic>>(
        'daily_plan', (j) => Map<String, dynamic>.from(j));

      final dashboardData = cache.get<Map<String, dynamic>>(
        'dashboard_data', (j) => Map<String, dynamic>.from(j));

      await FirebaseFirestore.instance
        .collection('user_daily_snapshots')
        .doc(userId)
        .collection('snapshots')
        .doc(DateTime.now().toIso8601String().substring(0, 10))
        .set({
          'userId': userId,
          'date': DateTime.now().toIso8601String().substring(0, 10),
          'updatedAt': FieldValue.serverTimestamp(),
          'profile': profileData,
          'wellnessSummary': wellnessData,
          'dailyPlan': planData,
          'dashboardStats': dashboardData,
        }, SetOptions(merge: true));

      await cache.save('last_daily_firebase_update',
        DateTime.now().toIso8601String());

      AppLogger.info('SyncManager', 'Daily Firebase update completed');
    } catch (e, stack) {
      AppLogger.error('SyncManager', 
        'Daily Firebase update failed', e, stack);
    }
  }

  /// Returns true if 24 hours have passed since last update
  /// Prevents duplicate updates if app restarts within same day
  Future<bool> _shouldRunDailyUpdate() async {
    final cache = LocalCacheService.instance;
    final lastUpdateStr = cache.get<String>(
      'last_daily_firebase_update', (j) => j.toString());

    if (lastUpdateStr == null) return true;

    final lastUpdate = DateTime.parse(lastUpdateStr);
    final hoursSince = DateTime.now().difference(lastUpdate).inHours;
    return hoursSince >= 24;
  }

  /// Call on app resume from background
  Future<void> onAppResume(String userId) async {
    AppLogger.info('SyncManager', 'App resumed — checking staleness');
    // Only sync if dashboard cache is stale
    if (!_cache.isFresh('dashboard_data')) {
      await _performSync(userId);
    }
  }

  /// Call on user logout
  Future<void> stopSync() async {
    _syncTimer?.cancel();
    _backupTimer?.cancel();
    _dailyUpdateTimer?.cancel();
    _connectivitySub?.cancel();
    _isSyncing = false;
    AppLogger.info('SyncManager', 'Sync stopped');
  }
}
