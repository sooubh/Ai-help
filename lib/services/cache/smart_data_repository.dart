import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_service.dart';
import '../../models/child_profile_model.dart';
import '../../models/user_model.dart';
import '../../models/guidance_note_model.dart';
import '../../models/chat_message_model.dart';
import '../../models/post_model.dart';
import 'local_cache_service.dart';
import '../../core/utils/app_logger.dart';

class SmartDataRepository {
  final FirebaseService _firebaseService;
  final LocalCacheService _cache = LocalCacheService.instance;

  SmartDataRepository(this._firebaseService);

  // ═══════════════════════════════════════
  // USER PROFILE — Cache 24 hours
  // ═══════════════════════════════════════

  Future<UserModel?> getUserProfile(String uid) async {
    const key = 'user_profile';

    // Return cache if fresh
    if (_cache.isFresh(key)) {
      final cached = _cache.get<UserModel>(
        key, (j) => UserModel.fromMap(j, uid));
      if (cached != null) {
        AppLogger.info('SmartDataRepository', 'UserProfile from cache');
        return cached;
      }
    }

    // Fetch from Firebase
    try {
      final profile = await _firebaseService.getUserProfile();
      if (profile != null) {
        await _cache.save(key, profile.toMap());
      }
      return profile;
    } catch (e) {
      // Offline — return stale cache if available
      AppLogger.info('SmartDataRepository', 'Offline — using stale cache');
      return _cache.get<UserModel>(
        key, (j) => UserModel.fromMap(j, uid));
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
          .map((e) => ChildProfileModel.fromMap(e['data'], e['id']))
          .toList());
      if (cached != null) return cached;
    }

    try {
      final profiles = await _firebaseService.getChildProfiles();
      await _cache.save(key, profiles.map((p) => {'data': p.toMap(), 'id': p.id}).toList());
      return profiles;
    } catch (e) {
      return _cache.get<List<ChildProfileModel>>(
        key, (j) => (j as List)
          .map((e) => ChildProfileModel.fromMap(e['data'], e['id']))
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
      // Using an internal firestore reference since we need to do a custom query
      // _firebaseService exposes `_firestore` as private? No, it has to be exposed if we follow chache.md
      // Let's use the actual firebase query if exposed, otherwise we need to rely on the service
      // Let's assume FirebaseFirestore.instance can be used or we add a getter in FirebaseService
      final snapshot = await FirebaseFirestore.instance
        .collection('users').doc(uid)
        .collection('activity_logs')
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
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

  Future<List<Map<String, dynamic>>> getMoodHistory(String uid, {int limit = 14}) async {
    final key = 'mood_history_$limit';

    if (_cache.isFresh(key)) {
      final cached = _cache.get<List<Map<String, dynamic>>>(
        key, (j) => List<Map<String, dynamic>>.from(
          (j as List).map((e) => Map<String, dynamic>.from(e))));
      if (cached != null) return cached;
    }

    try {
      final entries = await _firebaseService.getMoodHistory(limit: limit);
      // Ensure complex types (Timestamp, FieldValue) are serializable before caching if needed, 
      // though typically we should cache serializable formats.
      final serialized = entries.map((e) {
        final map = Map<String, dynamic>.from(e);
        if (map['timestamp'] is Timestamp) {
          map['timestamp'] = (map['timestamp'] as Timestamp).toDate().toIso8601String();
        }
        return map;
      }).toList();
      await _cache.save(key, serialized);
      // For immediate use we can parse back or return entries directly
      return entries;
    } catch (e) {
      final cached = _cache.get<List<Map<String, dynamic>>>(
        key, (j) => List<Map<String, dynamic>>.from(
          (j as List).map((e) => Map<String, dynamic>.from(e))));
      if (cached != null) {
        // Convert ISO string back to Timestamp for UI use if expected
        return cached.map((e) {
            final map = Map<String, dynamic>.from(e);
            if (map['timestamp'] is String) {
                map['timestamp'] = Timestamp.fromDate(DateTime.parse(map['timestamp']));
            }
            return map;
        }).toList();
      }
      return [];
    }
  }

  // ═══════════════════════════════════════
  // DAILY PLAN — Cache 1 hour
  // ═══════════════════════════════════════

  Future<List<Map<String, dynamic>>?> getDailyPlan(String uid, String date) async {
    final key = 'daily_plan_$date';

    if (_cache.isFresh(key)) {
      return _cache.get<List<Map<String, dynamic>>>(
        key, (j) => List<Map<String, dynamic>>.from(
          (j as List).map((e) => Map<String, dynamic>.from(e))));
    }

    try {
      final plan = await _firebaseService.getDailyPlan(date);
      if (plan != null) {
        await _cache.save(key, plan);
        return plan;
      }
      return null;
    } catch (e) {
      return _cache.get<List<Map<String, dynamic>>>(
        key, (j) => List<Map<String, dynamic>>.from(
          (j as List).map((e) => Map<String, dynamic>.from(e))));
    }
  }

  // ═══════════════════════════════════════
  // GUIDANCE NOTES — Cache 24 hours
  // ═══════════════════════════════════════

  Stream<List<GuidanceNoteModel>> watchGuidanceNotes(String childId) {
    // This is part of the original Firebase service and should be kept real-time
    return _firebaseService.watchGuidanceNotes(childId);
  }

  // Alternative fetched list for context builder
  Future<List<Map<String, dynamic>>> getGuidanceNotes(String childId) async {
    final key = 'guidance_notes_$childId';

    if (_cache.isFresh(key)) {
      final cached = _cache.get<List<Map<String, dynamic>>>(
        key, (j) => List<Map<String, dynamic>>.from(
          (j as List).map((e) => Map<String, dynamic>.from(e))));
      if (cached != null) return cached;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
        .collection('guidance_notes')
        .where('childId', isEqualTo: childId)
        .orderBy('createdAt', descending: true)
        .get();
        
      final notes = snapshot.docs.map((d) {
          final map = d.data();
          map['id'] = d.id;
          if (map['createdAt'] is Timestamp) {
            map['createdAt'] = (map['createdAt'] as Timestamp).toDate().toIso8601String();
          }
          return map;
      }).toList();
      
      await _cache.save(key, notes);
      return notes;
    } catch (e) {
      return _cache.get<List<Map<String, dynamic>>>(
        key, (j) => List<Map<String, dynamic>>.from(
          (j as List).map((e) => Map<String, dynamic>.from(e)))) ?? [];
    }
  }

  // ═══════════════════════════════════════
  // CHAT MESSAGES — Limited to last 50
  // ═══════════════════════════════════════

  Stream<List<ChatMessageModel>> getChatMessages(String uid, [String? childId]) {
    // Real-time but limited to 50 messages
    final path = childId != null
        ? FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('children')
            .doc(childId)
            .collection('chats')
        : FirebaseFirestore.instance.collection('users').doc(uid).collection('chats');

    return path
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs
        .map((d) => ChatMessageModel.fromMap(d.data(), d.id))
        .toList()
        .reversed
        .toList());
  }

  // ═══════════════════════════════════════
  // COMMUNITY POSTS — Real-time stream (Tier 1)
  // ═══════════════════════════════════════

  Stream<List<PostModel>> getCommunityPosts() {
    return _firebaseService.getCommunityPosts();
  }

  Future<void> createPost(String content, String authorName) {
    return _firebaseService.createPost(content, authorName);
  }

  Future<void> toggleLikePost(String postId) {
    return _firebaseService.toggleLikePost(postId);
  }

  String? get currentUserId => _firebaseService.currentUser?.uid;

  // ═══════════════════════════════════════
  // FORCE REFRESH — Called on pull to refresh
  // ═══════════════════════════════════════

  Future<void> forceRefresh(String uid, {String? childId}) async {
    await _cache.invalidate('user_profile');
    await _cache.invalidate('child_profiles');
    await _cache.invalidate('dashboard_data');
    await _cache.invalidate('mood_history_14');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await _cache.invalidate('daily_plan_$today');
    await _cache.invalidate('context_data');
    if (childId != null) {
      await _cache.invalidate('guidance_notes_$childId');
    }
    AppLogger.info('SmartDataRepository', 'Force refresh completed');
  }

  // ═══════════════════════════════════════
  // PRIVATE COMPUTE HELPERS
  // ═══════════════════════════════════════

  Map<String, dynamic> _computeWeeklyStats(List<Map<String, dynamic>> logs) {
    int totalSeconds = 0;
    for (final log in logs) {
      totalSeconds += (log['durationSeconds'] as int? ?? 0);
    }

    final dailyCounts = <String, int>{};
    final activeDays = <String>{};
    for (final log in logs) {
      if (log['completedAt'] != null && log['completedAt'] is Timestamp) {
        final d = (log['completedAt'] as Timestamp).toDate();
        final date = d.toIso8601String().substring(0, 10);
        dailyCounts[date] = (dailyCounts[date] ?? 0) + 1;
        activeDays.add('${d.year}-${d.month}-${d.day}');
      }
    }

    // Calculate streak (consecutive days with activity)
    int streak = 0;
    final now = DateTime.now();
    var checkDate = DateTime(now.year, now.month, now.day);
    while (activeDays.contains('${checkDate.year}-${checkDate.month}-${checkDate.day}')) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    
    return {
      'count': logs.length,
      'minutes': (totalSeconds / 60).round(),
      'streak': streak,
      'dailyCounts': dailyCounts,
    };
  }

  Map<String, double> _computeSkillProgress(List<Map<String, dynamic>> logs) {
    final Map<String, int> skillCounts = {};
    for (final log in logs) {
      final skill = log['category'] as String? ?? 'Other';
      skillCounts[skill] = (skillCounts[skill] ?? 0) + 1;
    }
    
    final progress = <String, double>{};
    for (final entry in skillCounts.entries) {
      progress[entry.key] = (entry.value / 10).clamp(0.0, 1.0);
    }
    return progress;
  }

  List<int> _computeDailyCounts(List<Map<String, dynamic>> logs) {
    final now = DateTime.now();
    final counts = List.filled(7, 0);
    
    for (final log in logs) {
      if (log['completedAt'] != null && log['completedAt'] is Timestamp) {
        final ts = (log['completedAt'] as Timestamp).toDate();
        final daysAgo = now.difference(ts).inDays;
        if (daysAgo >= 0 && daysAgo < 7) {
          counts[6 - daysAgo] += 1;
        }
      }
    }
    return counts;
  }
}
