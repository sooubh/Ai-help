import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  test('List Gemini Models', () async {
    await dotenv.load(fileName: ".env");
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    expect(apiKey, isNotNull);

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey',
    );
    final request = await HttpClient().getUrl(url);
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    final data = json.decode(responseBody);
    if (data is Map && data.containsKey('models')) {
      final models = data['models'] as List;
      debugPrint('Available Models:');
      for (var model in models) {
        final name = model['name'];
        final methods = model['supportedGenerationMethods'];
        debugPrint('- $name (Supported methods: $methods)');
      }
    } else {
      debugPrint('Unexpected response: $responseBody');
    }
  });
}
