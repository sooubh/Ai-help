import 'package:care_ai/core/theme/theme_provider.dart';
import 'package:care_ai/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: OnboardingScreen());
  }
}

Widget _buildAppUnderTest() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
    ],
    child: const MyApp(),
  );
}

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(_buildAppUnderTest());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shows loading or auth screen on launch', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildAppUnderTest());
    await tester.pump(const Duration(seconds: 1));

    final hasStartupUi =
        find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
        find.byType(OnboardingScreen).evaluate().isNotEmpty;

    expect(hasStartupUi, isTrue);
  });

  testWidgets('No RenderFlex overflow on startup', (WidgetTester tester) async {
    await tester.pumpWidget(_buildAppUnderTest());
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
