// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:care_ai/core/config/env_config.dart';
import 'package:care_ai/services/ai_service.dart';

void main() {
  test('Initialize AiService', () async {
    await dotenv.load(fileName: ".env");
    print('Testing AiService initialization...');

    EnvConfig.validate();

    final aiService = AiService();
    aiService.initialize();

    expect(EnvConfig.hasGeminiKey, isTrue);
  });
}
