import 'dart:math';

/// Placeholder AI service.
/// Returns canned supportive responses.
///
/// To integrate a real LLM API (e.g., OpenAI, Gemini):
/// 1. Add your API key to a secure config
/// 2. Replace [getResponse] with an HTTP call to your LLM endpoint
/// 3. Format the prompt to include child profile context
class AiService {
  /// Simulated delay to mimic network latency.
  static const Duration _simulatedDelay = Duration(milliseconds: 1200);

  /// Pool of supportive placeholder responses.
  static const List<String> _responses = [
    "That's a great question! Based on general guidance, try breaking the activity "
        "into smaller steps. Celebrate each small win with your child — it builds "
        "confidence and connection.",
    "I understand how challenging this can be. One technique that often helps is "
        "using visual schedules. You can create simple picture cards showing the "
        "steps of a routine. This gives your child predictability and reduces anxiety.",
    "You're doing an amazing job by seeking help! For communication practice, try "
        "using the 'one-word-up' strategy — if your child uses single words, model "
        "two-word phrases. If they use phrases, model short sentences.",
    "Many parents face this challenge. A calming corner with soft items, dim "
        "lighting, and fidget tools can help during overwhelming moments. Practice "
        "using it together during calm times first.",
    "Here's a helpful tip: use the 'First-Then' approach. For example, 'First we "
        "brush teeth, then we read a story.' Visual boards make this even more "
        "effective for children who are visual learners.",
    "That sounds really tough, and your feelings are completely valid. Remember to "
        "also take care of yourself. Even 10 minutes of quiet time can help you "
        "recharge and be more present for your child.",
    "Sensory play can be very beneficial! Try activities like playing with rice, "
        "water beads, or playdough. These provide calming sensory input and can "
        "improve focus and fine motor skills.",
    "Routine is key for many children with developmental needs. Try to keep wake "
        "times, meals, and bedtime consistent. A predictable environment helps "
        "reduce behavioral challenges significantly.",
  ];

  final Random _random = Random();

  /// Generate a placeholder AI response.
  /// [userMessage] is the user's input (unused in placeholder, but will be
  /// sent to the real LLM API).
  Future<String> getResponse(String userMessage) async {
    // Simulate network delay
    await Future.delayed(_simulatedDelay);

    // Return a random supportive response
    return _responses[_random.nextInt(_responses.length)];
  }
}
