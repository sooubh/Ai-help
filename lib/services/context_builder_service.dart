import 'package:intl/intl.dart';

import '../models/child_profile_model.dart';
import '../models/activity_log_model.dart';
import '../models/guidance_note_model.dart';
import 'cache/smart_data_repository.dart';
import 'cache/local_cache_service.dart';

class ContextBuilderService {
  final SmartDataRepository _repository;

  ContextBuilderService(this._repository);

  /// Builds a comprehensive string representing the user's current holistic context
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
      _repository.getMoodHistory(userId),
      _repository.getDailyPlan(
        userId, DateFormat('yyyy-MM-dd').format(DateTime.now()),
      ),
      _repository.getDashboardData(userId),
      childProfile != null
          ? _repository.getGuidanceNotes(childProfile.id!)
          : Future.value([]),
    ]);

    final moodHistory = results[0] as List<Map<String, dynamic>>?;
    final dailyPlan = results[1] as List<Map<String, dynamic>>?;
    final dashboardData = results[2] as Map<String, dynamic>?;
    final notesData = results[3] as List<Map<String, dynamic>>?;

    GuidanceNoteModel? latestNote;
    if (notesData != null && notesData.isNotEmpty) {
      latestNote = GuidanceNoteModel.fromMap(notesData.first, notesData.first['id']);
    }

    final contextInfo = _assembleContext(
      childProfile: childProfile,
      moodHistory: moodHistory ?? [],
      dailyPlan: dailyPlan,
      weeklyStats: dashboardData?['weeklyStats'],
      latestNote: latestNote,
      recentActivities: [], // Handled by dashboard stats now
    );

    await cache.save(key, contextInfo);
    return contextInfo;
  }

  String _assembleContext({
    ChildProfileModel? childProfile,
    required List<Map<String, dynamic>> moodHistory,
    List<Map<String, dynamic>>? dailyPlan,
    Map<String, dynamic>? weeklyStats,
    GuidanceNoteModel? latestNote,
    required List<ActivityLogModel> recentActivities,
  }) {
    final buffer = StringBuffer();
    buffer.writeln("=== USER CONTEXT FOR CARE-AI VOICE ===");

    // 1. Child Profile
    if (childProfile != null) {
      buffer.writeln("\nCHILD PROFILE:");
      buffer.writeln("Name: ${childProfile.name}, Age: ${childProfile.age}");
      buffer.writeln(
        "Diagnosed conditions: ${childProfile.conditions.join(', ')}",
      );
      buffer.writeln("Therapy Status: ${childProfile.currentTherapyStatus}");
    }

    // 2. Wellness State
    buffer.writeln("\nCURRENT WELLNESS STATE (last 7 logs):");
    if (moodHistory.isNotEmpty) {
      final latestMood = moodHistory.first['mood'] ?? 'Unknown';
      buffer.writeln("Most recent mood: $latestMood");
      final moods = moodHistory
          .map((m) => m['mood'].toString())
          .take(5)
          .join(', ');
      buffer.writeln("Recent mood trend: $moods");
    } else {
      buffer.writeln("No recent wellness logs available.");
    }

    // 3. Daily Plan
    buffer.writeln("\nTODAY'S DAILY PLAN:");
    if (dailyPlan != null && dailyPlan.isNotEmpty) {
      final completed = dailyPlan.where((t) => t['isCompleted'] == true).length;
      buffer.writeln("Completed tasks: $completed of ${dailyPlan.length}");
      final pending = dailyPlan
          .where((t) => t['isCompleted'] != true)
          .map((t) => t['title'])
          .join(', ');
      if (pending.isNotEmpty) buffer.writeln("Pending tasks: $pending");
    } else {
      buffer.writeln("No daily plan set for today.");
    }

    // 4. Progress Summary
    buffer.writeln("\nPROGRESS SUMMARY (Weekly):");
    if (weeklyStats != null) {
      buffer.writeln("Activities completed: ${weeklyStats['count']}");
      buffer.writeln("Minutes spent: ${weeklyStats['minutes']}");
      buffer.writeln("Current streak: ${weeklyStats['streak']} days");
    }

    // 5. Recent Activities
    buffer.writeln("\nRECENT ACTIVITIES (last 5):");
    if (recentActivities.isNotEmpty) {
      for (final activity in recentActivities) {
        final dateStr = DateFormat('MMM d').format(activity.completedAt);
        buffer.writeln(
          "- ${activity.activityTitle} ($dateStr) [${activity.category}]",
        );
      }
    } else {
      buffer.writeln("No recent activities.");
    }

    // 6. Therapist Notes
    buffer.writeln("\nTHERAPIST/GUIDANCE NOTES:");
    if (latestNote != null) {
      buffer.writeln(
        "From Dr. ${latestNote.doctorName}: ${latestNote.content}",
      );
    } else {
      buffer.writeln("No recent notes from therapist.");
    }

    buffer.writeln(
      "\nTODAY'S DATE AND TIME: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}",
    );
    buffer.writeln("=== END OF CONTEXT ===");

    return buffer.toString();
  }
}
