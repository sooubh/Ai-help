// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

void main() async {
  final envFile = File('.env');
  final envContent = await envFile.readAsString();
  final lines = envContent.split('\n');

  String? apiKey;
  for (var line in lines) {
    if (line.startsWith('GEMINI_API_KEY=')) {
      apiKey = line.split('=')[1].trim();
      break;
    }
  }

  if (apiKey == null) {
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
  final outFile = File('models_supported.txt');
  final sink = outFile.openWrite();

  if (data is Map && data.containsKey('models')) {
    final models = data['models'] as List;
    sink.writeln('Available Models with generateContent:');
    for (var model in models) {
      final name = model['name'];
      final methods = model['supportedGenerationMethods'];
      if (methods != null && methods.contains('generateContent')) {
        sink.writeln('- $name');
      }
    }
  } else {
    sink.writeln('Unexpected response: $responseBody');
  }
  await sink.close();
  print('Done.');
}
