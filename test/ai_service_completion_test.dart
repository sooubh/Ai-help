import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:care_ai/core/config/env_config.dart';
import 'package:care_ai/services/ai_service.dart';

void main() {
  test('Test AiService Response', () async {
    await dotenv.load(fileName: ".env");
    EnvConfig.validate();

    final aiService = AiService();
    aiService.initialize();

    final response = await aiService.getResponse("Hello");
    debugPrint('Response: $response');

    expect(response, isNotEmpty);
  });
}
