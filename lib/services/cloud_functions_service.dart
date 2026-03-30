import 'package:cloud_functions/cloud_functions.dart';

/// Service for directly invoking Firebase Cloud Functions.
class CloudFunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Calls the secure backend proxy to interact with Gemini AI.
  Future<String?> chatWithAI(String prompt) async {
    try {
      final callable = _functions.httpsCallable('chatWithAI');
      final result = await callable.call({'prompt': prompt});

      if (result.data != null && result.data['success'] == true) {
        return result.data['response'] as String?;
      }
      return null;
    } catch (e) {
      // In a production app, use proper error logging here
      return null;
    }
  }

  /// Calls the backend to auto-generate a daily plan based on the child's profile.
  Future<List<Map<String, dynamic>>?> generateDailyPlan(String childId) async {
    try {
      final callable = _functions.httpsCallable('generateDailyPlan');
      final result = await callable.call({'childId': childId});

      if (result.data != null && result.data['success'] == true) {
        final planList = result.data['plan'] as List<dynamic>;
        return planList.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
