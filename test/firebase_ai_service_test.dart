// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:care_ai/services/ai_service.dart';

void main() {
  testWidgets('Test Firebase AiService Response', (WidgetTester tester) async {
    // In test environment we need this
    TestWidgetsFlutterBinding.ensureInitialized();

    // Initialize standard Firebase app, assumes standard default config
    try {
      await Firebase.initializeApp();
    } catch (e) {
      print('Firebase init error: $e');
      // If we can't initialize firebase in plain tests, we might
      // just pass or document for integration test context.
    }

    final aiService = AiService();
    aiService.initialize();

    final response = await aiService.getResponse("Say hello!");
    print('Firebase AI Response: $response');

    expect(response, isNotEmpty);
  });
}
