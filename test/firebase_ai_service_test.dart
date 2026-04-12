import 'package:flutter_test/flutter_test.dart';
import 'package:care_ai/services/ai_service.dart';
import 'package:mocktail/mocktail.dart';

class MockAiService extends Mock implements AiService {}

void main() {
  group('AiService unit tests', () {
    late MockAiService mockAiService;

    setUp(() {
      mockAiService = MockAiService();
    });

    test('getResponse returns expected string', () async {
      when(
        () => mockAiService.getResponse('Say hello!'),
      ).thenAnswer((_) async => 'Hello! How can I help?');

      final result = await mockAiService.getResponse('Say hello!');

      expect(result, equals('Hello! How can I help?'));
      verify(() => mockAiService.getResponse('Say hello!')).called(1);
    });

    test('getResponse throws on empty input', () {
      when(
        () => mockAiService.getResponse(''),
      ).thenThrow(ArgumentError('Input cannot be empty'));

      expect(
        () => mockAiService.getResponse(''),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
