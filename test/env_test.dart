// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  test('Load .env file', () async {
    await dotenv.load(fileName: ".env");
    print('GEMINI_API_KEY: \${dotenv.env["GEMINI_API_KEY"]}');
    expect(dotenv.env['GEMINI_API_KEY'], isNotNull);
  });
}
