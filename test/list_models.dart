// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  final apiKey = dotenv.env['GEMINI_API_KEY'];

  if (apiKey == null || apiKey.isEmpty) {
    print('No API key found!');
    return;
  }

  final url = Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey',
  );
  final request = await HttpClient().getUrl(url);
  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();

  final data = json.decode(responseBody);
  if (data is Map && data.containsKey('models')) {
    final models = data['models'] as List;
    print('Available Models:');
    for (var model in models) {
      final name = model['name'];
      final methods = model['supportedGenerationMethods'];
      if (methods != null && methods.contains('generateContent')) {
        print('- $name');
      }
    }
  } else {
    print('Unexpected response: $responseBody');
  }
}
