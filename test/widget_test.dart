import 'package:care_ai/core/theme/theme_provider.dart';
import 'package:care_ai/features/onboarding/presentation/onboarding_screen.dart';
import 'package:care_ai/main.dart';
import 'package:care_ai/services/cache/local_cache_service.dart';
import 'package:care_ai/services/cache/smart_data_repository.dart';
import 'package:care_ai/services/cache/sync_manager.dart';
import 'package:care_ai/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _buildAppUnderTest() {
  final firebaseService = FirebaseService();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
      Provider<FirebaseService>.value(value: firebaseService),
      Provider<LocalCacheService>.value(value: LocalCacheService.instance),
      Provider<SmartDataRepository>(
        create: (context) => SmartDataRepository(context.read<FirebaseService>()),
      ),
      Provider<SyncManager>(
        create: (context) => SyncManager(context.read<SmartDataRepository>()),
      ),
    ],
    child: const CareAiApp(),
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
        find.byType(OnboardingScreen).evaluate().isNotEmpty ||
        find.text('CARE-AI').evaluate().isNotEmpty;

    expect(hasStartupUi, isTrue);
  });

  testWidgets('No RenderFlex overflow on startup', (WidgetTester tester) async {
    await tester.pumpWidget(_buildAppUnderTest());
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
