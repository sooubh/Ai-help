import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/config/env_config.dart';
import '../models/child_profile_model.dart';

/// AI service powered by Google Gemini.
///
/// Provides:
/// - Contextual chat with child profile awareness
/// - Non-diagnostic safety guardrails
/// - Streaming response support
/// - Personalized recommendations
class AiService {
  GenerativeModel? _model;
  ChatSession? _chatSession;

  static const String _modelName = 'gemini-2.0-flash';

  /// System instruction that frames CARE-AI's behavior.
  static const String _baseSystemPrompt = '''
You are CARE-AI, an empathetic AI parenting companion for children with developmental or physical disabilities.

RULES:
1. You are NOT a doctor. NEVER provide medical diagnoses or prescribe treatments.
2. Always encourage consulting qualified professionals for medical concerns.
3. Provide evidence-based, supportive parenting guidance.
4. Be warm, encouraging, and non-judgmental.
5. Offer practical, actionable advice for daily challenges.
6. Celebrate small wins and progress.
7. Support parents' emotional well-being — they are doing important work.
8. When discussing therapy activities, use step-by-step instructions.
9. Tailor your language to be simple and accessible.
10. If asked about emergencies or safety concerns, advise immediate professional help.

DISCLAIMER: Always remind users that your guidance supplements but does not replace professional medical advice.
''';

  /// Initialize the Gemini model. Call once at app start.
  void initialize() {
    if (!EnvConfig.hasGeminiKey) {
      // ignore: avoid_print
      print('⚠️ Gemini API key not configured. AI features will use fallback.');
      return;
    }

    _model = GenerativeModel(
      model: _modelName,
      apiKey: EnvConfig.geminiApiKey,
      systemInstruction: Content.text(_baseSystemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        SafetySetting(
            HarmCategory.sexuallyExplicit, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
      ],
    );
  }

  /// Start a new chat session with child profile context.
  void startChatSession({ChildProfileModel? childProfile}) {
    if (_model == null) return;

    final contextPrompt = _buildChildContext(childProfile);

    _chatSession = _model!.startChat(
      history: [
        if (contextPrompt.isNotEmpty) Content.text(contextPrompt),
      ],
    );
  }

  /// Send a message and get a response.
  /// Returns the AI response text, or a fallback if API is unavailable.
  Future<String> getResponse(String userMessage) async {
    if (_chatSession == null || _model == null) {
      return _getFallbackResponse(userMessage);
    }

    try {
      final response = await _chatSession!.sendMessage(
        Content.text(userMessage),
      );

      final text = response.text;
      if (text == null || text.isEmpty) {
        return 'I understand your question. Could you please provide more details so I can give you better guidance?';
      }
      return text;
    } catch (e) {
      // ignore: avoid_print
      print('Gemini API error: $e');
      return _getFallbackResponse(userMessage);
    }
  }

  /// Send a message and stream the response token by token.
  Stream<String> getStreamingResponse(String userMessage) async* {
    if (_model == null) {
      yield _getFallbackResponse(userMessage);
      return;
    }

    try {
      final response = _model!.generateContentStream([
        Content.text(userMessage),
      ]);

      await for (final chunk in response) {
        final text = chunk.text;
        if (text != null && text.isNotEmpty) {
          yield text;
        }
      }
    } catch (e) {
      yield _getFallbackResponse(userMessage);
    }
  }

  /// Generate personalized recommendations based on child profile.
  Future<String> getRecommendations(ChildProfileModel profile) async {
    if (_model == null) {
      return _getDefaultRecommendations(profile);
    }

    final prompt = '''
Based on the following child profile, suggest 3-5 appropriate therapy activities for today.
Each activity should include: title, duration, objective, and why it's suitable.

Child Profile:
- Name: ${profile.name}
- Age: ${profile.age}
- Conditions: ${profile.conditions.join(', ')}
- Communication Level: ${profile.communicationLevel}
- Behavioral Concerns: ${profile.behavioralConcerns.join(', ')}
- Sensory Issues: ${profile.sensoryIssues.join(', ')}
- Motor Skill Level: ${profile.motorSkillLevel}
- Parent Goals: ${profile.parentGoals.join(', ')}

Format as a numbered list. Keep activities practical for home settings.
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? _getDefaultRecommendations(profile);
    } catch (e) {
      return _getDefaultRecommendations(profile);
    }
  }

  /// Build child context string for chat initialization.
  String _buildChildContext(ChildProfileModel? profile) {
    if (profile == null) return '';

    return '''
CHILD CONTEXT (use this to personalize all responses):
- Child Name: ${profile.name}
- Age: ${profile.age} years
- Conditions: ${profile.conditions.join(', ')}
- Communication: ${profile.communicationLevel}
- Behavioral Concerns: ${profile.behavioralConcerns.join(', ')}
- Sensory Issues: ${profile.sensoryIssues.join(', ')}
- Motor Skills: ${profile.motorSkillLevel}
- Parent Goals: ${profile.parentGoals.join(', ')}
- Current Therapy: ${profile.currentTherapyStatus}

Tailor all advice and activities to this child's specific needs and abilities.
''';
  }

  /// Fallback responses when Gemini API is unavailable.
  String _getFallbackResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains('meltdown') ||
        lowerMessage.contains('crisis') ||
        lowerMessage.contains('tantrum')) {
      return "During a meltdown, stay calm and ensure safety first. Try these steps:\n\n"
          "1. Reduce sensory input — dim lights, lower sounds\n"
          "2. Provide a safe space — soft area, comfort items\n"
          "3. Use a calm, low voice\n"
          "4. Don't try to reason during the peak — wait for calm\n"
          "5. Offer comfort when the child is ready\n\n"
          "Remember: meltdowns are not behavior problems — they're sensory/emotional overwhelm. "
          "If they increase in frequency, please consult your therapist.\n\n"
          "⚠️ This guidance does not replace professional medical advice.";
    }

    if (lowerMessage.contains('speech') || lowerMessage.contains('talk')) {
      return "For speech development, try the 'one-word-up' strategy:\n\n"
          "• If your child uses single words, model two-word phrases\n"
          "• If they use phrases, model short sentences\n"
          "• Narrate daily activities naturally\n"
          "• Use picture cards for visual support\n"
          "• Celebrate every communication attempt!\n\n"
          "⚠️ This guidance does not replace professional speech therapy.";
    }

    if (lowerMessage.contains('stress') ||
        lowerMessage.contains('burn') ||
        lowerMessage.contains('tired')) {
      return "Your feelings are completely valid — caregiving is deeply rewarding but exhausting.\n\n"
          "💙 Take 10 minutes for yourself today\n"
          "💙 Connect with other parents who understand\n"
          "💙 You are doing an incredible job\n"
          "💙 Small steps forward are still progress\n"
          "💙 It's okay to ask for help\n\n"
          "Remember: taking care of yourself IS taking care of your child.";
    }

    return "That's a great question! Here are some general tips:\n\n"
        "• Break activities into small, manageable steps\n"
        "• Use visual schedules for predictability\n"
        "• Celebrate every small win\n"
        "• Keep routines consistent\n"
        "• Use the 'First-Then' approach for motivation\n\n"
        "Would you like more specific guidance about a particular challenge?\n\n"
        "⚠️ CARE-AI does not provide medical diagnoses. Always consult a qualified professional.";
  }

  /// Default recommendations when AI is unavailable.
  String _getDefaultRecommendations(ChildProfileModel profile) {
    return "Here are some recommended activities for ${profile.name}:\n\n"
        "1. **Sensory Play** (15 min) — Play with textured materials like rice or playdough\n"
        "2. **Communication Practice** (10 min) — Use picture cards for daily requests\n"
        "3. **Motor Skills** (10 min) — Simple stacking or threading activities\n"
        "4. **Social Interaction** (15 min) — Turn-taking games with a caregiver\n"
        "5. **Calm Down Time** (10 min) — Guided breathing with visual cues";
  }

  /// Dispose resources.
  void dispose() {
    _chatSession = null;
    _model = null;
  }
}
