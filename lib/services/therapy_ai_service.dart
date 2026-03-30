import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/config/env_config.dart';
import '../models/child_profile_model.dart';
import '../models/therapy_session_model.dart';

/// AI-powered therapy recommendation engine.
///
/// Uses Gemini to analyse a child's profile + therapy history and provide:
/// - Next-best module recommendations
/// - Post-completion performance feedback
/// - Difficulty adjustment suggestions
/// - Weekly therapy plan generation
/// - Skill-gap analysis
class TherapyAiService {
  GenerativeModel? _model;
  static const String _modelName = 'gemini-2.5-flash';

  void initialize() {
    if (!EnvConfig.hasGeminiKey) return;

    _model = GenerativeModel(
      model: _modelName,
      apiKey: EnvConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 2048,
        responseMimeType: 'application/json',
      ),
    );
  }

  bool get isAvailable => _model != null;

  // ═════════════════════════════════════════════════════════════
  // 1. NEXT-BEST MODULE RECOMMENDATIONS
  // ═════════════════════════════════════════════════════════════

  /// Analyses child profile + history and returns ranked module suggestions.
  Future<List<Map<String, dynamic>>> getNextRecommendations({
    required ChildProfileModel profile,
    required Map<String, dynamic> history,
    required List<String> availableModuleIds,
    int count = 5,
  }) async {
    if (_model == null) return _fallbackRecommendations(count);

    final prompt = '''
You are an AI therapy recommendation engine for children with developmental needs.

CHILD PROFILE:
${profile.summaryForAI}
Conditions: ${profile.conditions.join(', ')}
Communication Level: ${profile.communicationLevel}
Motor Skill Level: ${profile.motorSkillLevel}
Therapy Status: ${profile.currentTherapyStatus}
Parent Goals: ${profile.parentGoals.join(', ')}

THERAPY HISTORY:
Total sessions completed: ${history['totalSessionsCompleted']}
Completed module IDs: ${(history['completedModuleIds'] as List?)?.join(', ') ?? 'none'}
Weekly stats: ${jsonEncode(history['weeklyStats'])}
Average scores by category: ${jsonEncode(history['averageScoresByCategory'])}
Recent sessions: ${jsonEncode(history['recentSessions'])}

AVAILABLE MODULE IDS: ${availableModuleIds.join(', ')}

Based on this data, recommend the $count best next therapy modules.
Prioritize:
1. Weak skill areas (low average scores)
2. Modules not yet completed
3. Age-appropriate and condition-appropriate content
4. Modules whose prerequisites are already met
5. Gradual difficulty progression

Return a JSON array of objects with:
- "moduleId": one of the available module IDs
- "reason": one sentence explaining why this is recommended
- "priority": 1 (highest) to $count (lowest)
- "suggestedDifficulty": 1-5
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null) return _fallbackRecommendations(count);

      final decoded = jsonDecode(text);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      return _fallbackRecommendations(count);
    } catch (e) {
      return _fallbackRecommendations(count);
    }
  }

  // ═════════════════════════════════════════════════════════════
  // 2. POST-COMPLETION FEEDBACK
  // ═════════════════════════════════════════════════════════════

  /// After a module is done, analyses performance and returns feedback.
  Future<Map<String, dynamic>> getPostCompletionFeedback({
    required TherapySessionModel session,
    required ChildProfileModel profile,
  }) async {
    if (_model == null) return _fallbackFeedback(session);

    final prompt = '''
You are an encouraging AI therapy assistant for children with special needs.

CHILD: ${profile.summaryForAI}
MODULE COMPLETED: ${session.moduleTitle}
SKILL CATEGORY: ${session.skillCategory}
SCORE: ${session.score}/${session.maxScore} (${session.scorePercent.toStringAsFixed(0)}%)
DIFFICULTY: ${session.difficultyLevel}/5
TIME SPENT: ${session.timeSpentSeconds} seconds
STEPS COMPLETED: ${session.stepsCompleted}/${session.totalSteps}

Provide therapy feedback. Be warm and encouraging. Return JSON with:
- "feedbackMessage": 2-3 sentences of encouraging feedback about performance
- "strengthsObserved": list of 1-2 strengths shown
- "areasToImprove": list of 1-2 areas to work on (gentle language)
- "suggestedNextDifficulty": 1-5 (adjust based on performance)
- "nextActivitySuggestion": one sentence suggesting what to do next
- "celebrationLevel": "star" | "trophy" | "rocket" based on performance
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null) return _fallbackFeedback(session);
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (e) {
      return _fallbackFeedback(session);
    }
  }

  // ═════════════════════════════════════════════════════════════
  // 3. DIFFICULTY ADJUSTMENT
  // ═════════════════════════════════════════════════════════════

  /// Returns recommended difficulty (1-5) based on the last few sessions.
  int adjustDifficulty(List<TherapySessionModel> recentSessions) {
    if (recentSessions.isEmpty) return 1;

    final avgScore =
        recentSessions.map((s) => s.scorePercent).reduce((a, b) => a + b) /
        recentSessions.length;

    final currentDiff = recentSessions.first.difficultyLevel;

    // If consistently scoring > 85%, bump up
    if (avgScore > 85 && currentDiff < 5) return currentDiff + 1;
    // If consistently scoring < 40%, lower
    if (avgScore < 40 && currentDiff > 1) return currentDiff - 1;
    // Otherwise keep
    return currentDiff;
  }

  // ═════════════════════════════════════════════════════════════
  // 4. WEEKLY THERAPY PLAN
  // ═════════════════════════════════════════════════════════════

  /// Generates a 7-day therapy plan based on child profile and history.
  Future<List<Map<String, dynamic>>> generateWeeklyTherapyPlan({
    required ChildProfileModel profile,
    required Map<String, dynamic> history,
    required List<Map<String, String>> availableModules,
  }) async {
    if (_model == null) return _fallbackWeeklyPlan();

    final prompt = '''
You are an AI therapy planner for a child with special needs.

CHILD: ${profile.summaryForAI}
Parent Goals: ${profile.parentGoals.join(', ')}
History summary: ${jsonEncode(history['averageScoresByCategory'])}
Weekly stats: ${jsonEncode(history['weeklyStats'])}

Available modules (id → title):
${availableModules.map((m) => '- ${m['id']}: ${m['title']} (${m['category']})').join('\n')}

Create a 7-day therapy plan. Each day should have 2-3 activities.
Mix different skill categories. Increase difficulty gradually through the week.

Return a JSON array of 7 objects:
- "day": "Monday" through "Sunday"
- "activities": array of {"moduleId", "title", "duration": "15 min", "difficulty": 1-5}
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null) return _fallbackWeeklyPlan();
      final decoded = jsonDecode(text);
      if (decoded is List) return decoded.cast<Map<String, dynamic>>();
      return _fallbackWeeklyPlan();
    } catch (e) {
      return _fallbackWeeklyPlan();
    }
  }

  // ═════════════════════════════════════════════════════════════
  // 5. SKILL GAP ANALYSIS
  // ═════════════════════════════════════════════════════════════

  /// Identifies weak areas based on history.
  Future<Map<String, dynamic>> getSkillGapAnalysis({
    required ChildProfileModel profile,
    required Map<String, dynamic> history,
  }) async {
    if (_model == null) return _fallbackSkillGap();

    final prompt = '''
You are an AI analyzing a child's therapy progress.

CHILD: ${profile.summaryForAI}
Average scores by category: ${jsonEncode(history['averageScoresByCategory'])}
Skill progress: ${jsonEncode(history['skillProgress'])}
Total sessions: ${history['totalSessionsCompleted']}

Identify skill gaps and provide analysis. Return JSON with:
- "strongAreas": list of categories where child excels (>75% avg)
- "weakAreas": list of categories needing focus (<50% avg)
- "neglectedAreas": categories with 0 or very few sessions
- "overallAssessment": 2 sentences about the child's progress
- "focusRecommendation": one sentence about what to focus on next
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null) return _fallbackSkillGap();
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (e) {
      return _fallbackSkillGap();
    }
  }

  // ═════════════════════════════════════════════════════════════
  // FALLBACKS (when Gemini is unavailable)
  // ═════════════════════════════════════════════════════════════

  List<Map<String, dynamic>> _fallbackRecommendations(int count) {
    return List.generate(
      count,
      (i) => {
        'moduleId': 'mod_${i + 1}',
        'reason': 'Recommended based on your child\'s profile',
        'priority': i + 1,
        'suggestedDifficulty': 1,
      },
    );
  }

  Map<String, dynamic> _fallbackFeedback(TherapySessionModel session) {
    final pct = session.scorePercent;
    String msg;
    String celebration;
    if (pct >= 80) {
      msg =
          'Amazing work! You did a fantastic job on this activity. Keep up the great effort!';
      celebration = 'rocket';
    } else if (pct >= 50) {
      msg =
          'Good job completing this activity! With a little more practice, you\'ll get even better.';
      celebration = 'trophy';
    } else {
      msg =
          'Great effort trying this activity! Every attempt helps you grow. Let\'s try again soon!';
      celebration = 'star';
    }
    return {
      'feedbackMessage': msg,
      'strengthsObserved': ['Persistence', 'Engagement'],
      'areasToImprove': ['Keep practicing for higher accuracy'],
      'suggestedNextDifficulty': session.difficultyLevel,
      'nextActivitySuggestion':
          'Try another activity in the same category to reinforce learning.',
      'celebrationLevel': celebration,
    };
  }

  List<Map<String, dynamic>> _fallbackWeeklyPlan() {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days
        .map(
          (d) => {
            'day': d,
            'activities': [
              {
                'moduleId': 'mod_1',
                'title': 'Practice Activity',
                'duration': '15 min',
                'difficulty': 1,
              },
            ],
          },
        )
        .toList();
  }

  Map<String, dynamic> _fallbackSkillGap() {
    return {
      'strongAreas': [],
      'weakAreas': [],
      'neglectedAreas': ['Complete more activities to see analysis'],
      'overallAssessment':
          'Not enough data yet. Keep completing therapy activities!',
      'focusRecommendation':
          'Try activities across different skill categories.',
    };
  }
}
