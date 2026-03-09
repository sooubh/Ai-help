You are an expert Flutter/Firebase architect. I need you to implement a 
comprehensive caching and data synchronization system for my CARE-AI app.
The goal is to drastically reduce Firebase reads while keeping critical 
features real-time, and ensuring all data is safely backed up locally.

═══════════════════════════════════════════
ARCHITECTURE OVERVIEW
═══════════════════════════════════════════

THREE-TIER DATA STRATEGY:

TIER 1 — REAL-TIME (Always live Firebase listeners):
- Authentication state
- Active chat/voice messages
- Emergency alerts
- Notifications

TIER 2 — SCHEDULED SYNC (Fetch once, cache locally, refresh on schedule):
- User profile + child profiles
- Wellness entries
- Daily plan
- Progress data
- Guidance notes
- Activity logs
- Game sessions
- Community posts

TIER 3 — STATIC (Fetch once per app install, almost never changes):
- Therapy modules/content
- Game definitions
- App configuration

═══════════════════════════════════════════
TECHNOLOGY STACK
═══════════════════════════════════════════

Use these packages — add to pubspec.yaml:

dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.2
  connectivity_plus: ^6.0.3  # already exists
  workmanager: ^0.5.2         # for background sync
  crypto: ^3.0.3              # for cache invalidation hashing

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.8

═══════════════════════════════════════════
STEP 1 — CREATE LOCAL CACHE SERVICE
═══════════════════════════════════════════

Create: lib/services/cache/local_cache_service.dart

This is the core service that manages all local Hive storage.
```dart
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
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
      final backupData = {
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0',
        'data': {}
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
```

═══════════════════════════════════════════
STEP 2 — CREATE SMART DATA REPOSITORY
═══════════════════════════════════════════

Create: lib/services/cache/smart_data_repository.dart

This is the single source of truth for all data in the app.
Every screen fetches data ONLY through this repository.
It decides automatically: use cache or fetch from Firebase.
```dart
import '../firebase_service.dart';
import '../../models/child_profile_model.dart';
import '../../models/user_profile_model.dart';
import '../../models/wellness_model.dart';
import '../../models/daily_plan_model.dart';
import 'local_cache_service.dart';
import '../../core/utils/app_logger.dart';

class SmartDataRepository {
  final FirebaseService _firebaseService;
  final LocalCacheService _cache = LocalCacheService.instance;

  SmartDataRepository(this._firebaseService);

  // ═══════════════════════════════════════
  // USER PROFILE — Cache 24 hours
  // ═══════════════════════════════════════

  Future<UserProfileModel?> getUserProfile(String uid) async {
    const key = 'user_profile';

    // Return cache if fresh
    if (_cache.isFresh(key)) {
      final cached = _cache.get<UserProfileModel>(
        key, (j) => UserProfileModel.fromJson(j));
      if (cached != null) {
        AppLogger.info('SmartDataRepository', 'UserProfile from cache');
        return cached;
      }
    }

    // Fetch from Firebase
    try {
      final profile = await _firebaseService.getUserProfile(uid);
      if (profile != null) {
        await _cache.save(key, profile.toJson());
      }
      return profile;
    } catch (e) {
      // Offline — return stale cache if available
      AppLogger.info('SmartDataRepository', 'Offline — using stale cache');
      return _cache.get<UserProfileModel>(
        key, (j) => UserProfileModel.fromJson(j));
    }
  }

  // ═══════════════════════════════════════
  // CHILD PROFILES — Cache 24 hours
  // ═══════════════════════════════════════

  Future<List<ChildProfileModel>> getChildProfiles(String uid) async {
    const key = 'child_profiles';

    if (_cache.isFresh(key)) {
      final cached = _cache.get<List<ChildProfileModel>>(
        key, (j) => (j as List)
          .map((e) => ChildProfileModel.fromJson(e))
          .toList());
      if (cached != null) return cached;
    }

    try {
      final profiles = await _firebaseService.getChildProfiles(uid);
      await _cache.save(key, profiles.map((p) => p.toJson()).toList());
      return profiles;
    } catch (e) {
      return _cache.get<List<ChildProfileModel>>(
        key, (j) => (j as List)
          .map((e) => ChildProfileModel.fromJson(e))
          .toList()) ?? [];
    }
  }

  // ═══════════════════════════════════════
  // DASHBOARD DATA — Cache 1 hour
  // Combines weeklyStats + skillProgress + dailyActivityCounts
  // into ONE Firebase query instead of three
  // ═══════════════════════════════════════

  Future<Map<String, dynamic>> getDashboardData(String uid) async {
    const key = 'dashboard_data';

    if (_cache.isFresh(key)) {
      final cached = _cache.get<Map<String, dynamic>>(
        key, (j) => Map<String, dynamic>.from(j));
      if (cached != null) {
        AppLogger.info('SmartDataRepository', 'Dashboard from cache');
        return cached;
      }
    }

    try {
      // ONE combined Firebase query instead of 3 separate ones
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final snapshot = await _firebaseService.firestore
        .collection('users').doc(uid)
        .collection('activity_logs')
        .where('timestamp', isGreaterThan: 
          Timestamp.fromDate(sevenDaysAgo))
        .get();

      final logs = snapshot.docs.map((d) => d.data()).toList();

      final dashboardData = {
        'weeklyStats': _computeWeeklyStats(logs),
        'skillProgress': _computeSkillProgress(logs),
        'dailyActivityCounts': _computeDailyCounts(logs),
        'fetchedAt': DateTime.now().toIso8601String(),
      };

      await _cache.save(key, dashboardData);
      return dashboardData;
    } catch (e) {
      return _cache.get<Map<String, dynamic>>(
        key, (j) => Map<String, dynamic>.from(j)) ?? {};
    }
  }

  // ═══════════════════════════════════════
  // WELLNESS ENTRIES — Cache 6 hours
  // ═══════════════════════════════════════

  Future<List<Map<String, dynamic>>> getWellnessEntries(
      String uid, {int days = 7}) async {
    final key = 'wellness_entries_${days}d';

    if (_cache.isFresh(key)) {
      final cached = _cache.get<List<Map<String, dynamic>>>(
        key, (j) => List<Map<String, dynamic>>.from(
          (j as List).map((e) => Map<String, dynamic>.from(e))));
      if (cached != null) return cached;
    }

    try {
      final entries = await _firebaseService.getWellnessEntries(uid);
      final serialized = entries
        .map((e) => e.toJson())
        .toList();
      await _cache.save(key, serialized);
      return serialized;
    } catch (e) {
      return _cache.get<List<Map<String, dynamic>>>(
        key, (j) => List<Map<String, dynamic>>.from(
          (j as List).map((e) => Map<String, dynamic>.from(e)))) ?? [];
    }
  }

  // ═══════════════════════════════════════
  // DAILY PLAN — Cache 1 hour
  // ═══════════════════════════════════════

  Future<Map<String, dynamic>?> getDailyPlan(String uid) async {
    const key = 'daily_plan';

    if (_cache.isFresh(key)) {
      return _cache.get<Map<String, dynamic>>(
        key, (j) => Map<String, dynamic>.from(j));
    }

    try {
      final plan = await _firebaseService.getDailyPlan(uid);
      if (plan != null) {
        await _cache.save(key, plan.toJson());
        return plan.toJson();
      }
      return null;
    } catch (e) {
      return _cache.get<Map<String, dynamic>>(
        key, (j) => Map<String, dynamic>.from(j));
    }
  }

  // ═══════════════════════════════════════
  // GUIDANCE NOTES — Cache 24 hours
  // ═══════════════════════════════════════

  Future<List<Map<String, dynamic>>> getGuidanceNotes(
      String childId) async {
    final key = 'guidance_notes_$childId';

    if (_cache.isFresh(key)) {
      final cached = _cache.get<List<Map<String, dynamic>>>(
        key, (j) => List<Map<String, dynamic>>.from(
          (j as List).map((e) => Map<String, dynamic>.from(e))));
      if (cached != null) return cached;
    }

    try {
      final notes = await _firebaseService.getGuidanceNotes(childId);
      final serialized = notes.map((n) => n.toJson()).toList();
      await _cache.save(key, serialized);
      return serialized;
    } catch (e) {
      return _cache.get<List<Map<String, dynamic>>>(
        key, (j) => List<Map<String, dynamic>>.from(
          (j as List).map((e) => Map<String, dynamic>.from(e)))) ?? [];
    }
  }

  // ═══════════════════════════════════════
  // CHAT MESSAGES — Limited to last 50
  // ═══════════════════════════════════════

  Stream<List<Map<String, dynamic>>> getChatMessages(
      String uid, String sessionId) {
    // Real-time but limited to 50 messages
    return _firebaseService.firestore
      .collection('users').doc(uid)
      .collection('chat_sessions').doc(sessionId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs
        .map((d) => d.data())
        .toList()
        .reversed
        .toList());
  }

  // ═══════════════════════════════════════
  // FORCE REFRESH — Called on pull to refresh
  // ═══════════════════════════════════════

  Future<void> forceRefresh(String uid, {String? childId}) async {
    await _cache.invalidate('user_profile');
    await _cache.invalidate('child_profiles');
    await _cache.invalidate('dashboard_data');
    await _cache.invalidate('wellness_entries_7d');
    await _cache.invalidate('daily_plan');
    await _cache.invalidate('context_data');
    if (childId != null) {
      await _cache.invalidate('guidance_notes_$childId');
    }
    AppLogger.info('SmartDataRepository', 'Force refresh completed');
  }

  // ═══════════════════════════════════════
  // PRIVATE COMPUTE HELPERS
  // ═══════════════════════════════════════

  Map<String, dynamic> _computeWeeklyStats(
      List<Map<String, dynamic>> logs) {
    // Group logs by day and compute stats
    final Map<String, int> dailyCounts = {};
    for (final log in logs) {
      final date = (log['timestamp'] as Timestamp)
        .toDate().toIso8601String().substring(0, 10);
      dailyCounts[date] = (dailyCounts[date] ?? 0) + 1;
    }
    return {
      'totalActivities': logs.length,
      'dailyCounts': dailyCounts,
    };
  }

  Map<String, dynamic> _computeSkillProgress(
      List<Map<String, dynamic>> logs) {
    final Map<String, int> skillCounts = {};
    for (final log in logs) {
      final skill = log['skillType'] as String? ?? 'general';
      skillCounts[skill] = (skillCounts[skill] ?? 0) + 1;
    }
    return skillCounts;
  }

  Map<String, int> _computeDailyCounts(
      List<Map<String, dynamic>> logs) {
    final Map<String, int> counts = {};
    for (final log in logs) {
      final date = (log['timestamp'] as Timestamp)
        .toDate().toIso8601String().substring(0, 10);
      counts[date] = (counts[date] ?? 0) + 1;
    }
    return counts;
  }
}
```

═══════════════════════════════════════════
STEP 3 — CREATE SYNC MANAGER
═══════════════════════════════════════════

Create: lib/services/cache/sync_manager.dart

This manages WHEN data syncs — on schedule, on app resume,
on connectivity restored, and daily backup.
```dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'local_cache_service.dart';
import 'smart_data_repository.dart';
import '../firebase_service.dart';
import '../../core/utils/app_logger.dart';

class SyncManager {
  final SmartDataRepository _repository;
  final LocalCacheService _cache = LocalCacheService.instance;
  final FirebaseService _firebaseService;

  Timer? _backupTimer;
  Timer? _syncTimer;
  StreamSubscription? _connectivitySub;
  bool _isSyncing = false;

  // Sync schedule config
  static const _backupInterval = Duration(hours: 6);
  static const _periodicSyncInterval = Duration(hours: 1);

  SyncManager(this._repository, this._firebaseService);

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
  }

  /// Perform full data sync — invalidates and re-fetches all data
  Future<void> _performSync(String userId) async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      AppLogger.info('SyncManager', 'Performing scheduled sync...');

      // Invalidate stale entries (let SmartDataRepository re-fetch)
      await _cache.invalidate('dashboard_data');
      await _cache.invalidate('wellness_entries_7d');
      await _cache.invalidate('daily_plan');
      await _cache.invalidate('context_data');

      // Pre-warm cache with fresh data
      await _repository.getDashboardData(userId);
      await _repository.getWellnessEntries(userId);
      await _repository.getDailyPlan(userId);

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

      await _firebaseService.firestore
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
    _connectivitySub?.cancel();
    _isSyncing = false;
    AppLogger.info('SyncManager', 'Sync stopped');
  }
}
```

═══════════════════════════════════════════
STEP 4 — UPDATE main.dart
═══════════════════════════════════════════

In main.dart, initialize Hive before runApp and provide
SmartDataRepository and SyncManager:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local cache FIRST
  await LocalCacheService.initialize();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        // Existing providers...
        Provider<LocalCacheService>(
          create: (_) => LocalCacheService.instance,
        ),
        Provider<SmartDataRepository>(
          create: (ctx) => SmartDataRepository(
            ctx.read<FirebaseService>(),
          ),
        ),
        Provider<SyncManager>(
          create: (ctx) => SyncManager(
            ctx.read<SmartDataRepository>(),
            ctx.read<FirebaseService>(),
          ),
        ),
        // VoiceAssistantService — already exists
      ],
      child: const CareAiApp(),
    ),
  );
}
```

═══════════════════════════════════════════
STEP 5 — HOOK INTO AUTH EVENTS
═══════════════════════════════════════════

In your AuthService or wherever login/logout happens:
```dart
// ON LOGIN SUCCESS:
final syncManager = context.read<SyncManager>();
await syncManager.startSync(userId);

// Restore backup if first login on new device
final cache = LocalCacheService.instance;
if (cache.lastBackupTime == null) {
  await cache.restoreFromBackup();
}

// ON LOGOUT:
final syncManager = context.read<SyncManager>();
await syncManager.stopSync();
await LocalCacheService.instance.clearUserData();
```

═══════════════════════════════════════════
STEP 6 — HANDLE APP LIFECYCLE
═══════════════════════════════════════════

In your main app widget, add lifecycle observer:
```dart
class CareAiApp extends StatefulWidget { ... }

class _CareAiAppState extends State<CareAiApp> 
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Sync on app resume
      final userId = context.read<FirebaseService>().currentUserId;
      if (userId != null) {
        context.read<SyncManager>().onAppResume(userId);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
```

═══════════════════════════════════════════
STEP 7 — UPDATE ALL SCREENS TO USE REPOSITORY
═══════════════════════════════════════════

Replace ALL direct FirebaseService calls in screens with
SmartDataRepository calls. Example:
```dart
// ❌ BEFORE — direct Firebase call in every screen
final profile = await _firebaseService.getUserProfile(uid);

// ✅ AFTER — goes through cache first
final repository = context.read<SmartDataRepository>();
final profile = await repository.getUserProfile(uid);
```

Do this for every screen that fetches:
- User profile
- Child profiles  
- Dashboard/stats data
- Wellness entries
- Daily plan
- Guidance notes
- Activity logs

═══════════════════════════════════════════
STEP 8 — UPDATE CONTEXT BUILDER
═══════════════════════════════════════════

Update context_builder_service.dart to use SmartDataRepository:
```dart
class ContextBuilderService {
  final SmartDataRepository _repository;

  ContextBuilderService(this._repository);

  Future<String> buildFullContext({
    required String userId,
    ChildProfileModel? childProfile,
  }) async {
    const key = 'context_data';
    final cache = LocalCacheService.instance;

    // Return cached context if fresh (10 min TTL)
    if (cache.isFresh(key)) {
      final cached = cache.get<String>(key, (j) => j.toString());
      if (cached != null) return cached;
    }

    // All calls go through cache — zero extra Firebase reads
    final results = await Future.wait([
      _repository.getWellnessEntries(userId),
      _repository.getDailyPlan(userId),
      _repository.getDashboardData(userId),
      childProfile != null
        ? _repository.getGuidanceNotes(childProfile.id)
        : Future.value([]),
    ]);

    final context = _assemble(
      childProfile: childProfile,
      wellness: results[0] as List,
      plan: results[1] as Map?,
      dashboard: results[2] as Map,
      notes: results[3] as List,
    );

    await cache.save(key, context);
    return context;
  }
}
```

═══════════════════════════════════════════
REAL-TIME EXCEPTIONS (DO NOT CACHE THESE)
═══════════════════════════════════════════

These must ALWAYS be live Firebase listeners — never cached:

1. Authentication state — FirebaseAuth.instance.authStateChanges()
2. Chat messages stream — real-time with .limit(50)
3. Emergency alerts — critical, must be instant
4. Push notifications — handled by FCM directly
5. Active voice session state — in-memory only

═══════════════════════════════════════════
FIREBASE FIXES TO IMPLEMENT SIMULTANEOUSLY
═══════════════════════════════════════════

While implementing caching, also fix these in firebase_service.dart:

FIX 1 — getChatMessages:
  Add .limit(50) to the query

FIX 2 — getSkillProgress:
  Add .where('timestamp', isGreaterThan: 30DaysAgo)

FIX 3 — getCompletedModuleIds:
  Read from ChildProfileModel.completedModuleIds array field
  instead of querying therapy_sessions collection

FIX 4 — Remove getWeeklyStats, getSkillProgress, getDailyActivityCounts
  as separate methods — replace with getDashboardData in repository

═══════════════════════════════════════════
FILES TO CREATE
═══════════════════════════════════════════

CREATE:
- lib/services/cache/local_cache_service.dart
- lib/services/cache/smart_data_repository.dart
- lib/services/cache/sync_manager.dart

MODIFY:
- lib/main.dart — initialize Hive + add providers
- lib/services/firebase_service.dart — fix 4 query issues above
- lib/services/context_builder_service.dart — use repository
- lib/services/voice_assistant_service.dart — use repository
- All screen files — replace direct Firebase calls with repository
- android/app/build.gradle — ensure minSdkVersion >= 19 for Hive

DO NOT CHANGE:
- gemini_live_service.dart
- pcm_audio_player.dart
- voice_assistant_screen.dart
- Any model files

═══════════════════════════════════════════
EXPECTED RESULTS AFTER IMPLEMENTATION
═══════════════════════════════════════════

READS PER DAY (per user):
Before:  150 - 300+ reads/day
After:   15 - 30 reads/day (90% reduction)

BACKUP SAFETY:
- Local Hive backup every 6 hours
- Firebase backup record every 6 hours
- Auto-restore on new device login
- Survives app uninstall IF Firebase backup exists

SYNC SCHEDULE:
- Login: immediate full sync
- Every hour: stale data refresh
- Every 6 hours: full backup
- App resume: check staleness
- Connectivity restored: immediate sync
- Logout: clear local data, keep backup

OFFLINE BEHAVIOR:
- App works fully offline using cached data
- Stale cache served when Firebase unreachable
- Queue writes for when connectivity returns
- User sees last-synced timestamp if data is stale

Return all created and modified files with complete code.