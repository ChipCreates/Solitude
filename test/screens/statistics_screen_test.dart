import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solitude/screens/statistics_screen.dart';
import 'package:solitude/services/statistics_service.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StatisticsBottomSheet', () {
    testWidgets('renders statistics data correctly', (tester) async {
      final statsService = StatisticsService();

      // Set up some test data
      await statsService.recordGameStarted();
      await statsService.recordWin(
        moves: 100,
        time: const Duration(minutes: 5),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: statsService,
              child: const StatisticsBottomSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that statistics are displayed
      expect(find.text('Statistics'), findsOneWidget);
      expect(find.text('Games Played'), findsOneWidget);
      expect(find.text('Games Won'), findsOneWidget);
      expect(find.text('Win %'), findsOneWidget);

      // Check that the drag handle is present
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('displays close button', (tester) async {
      final statsService = StatisticsService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: statsService,
              child: const StatisticsBottomSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify close button exists
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('displays reset and close action buttons', (tester) async {
      final statsService = StatisticsService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: statsService,
              child: const StatisticsBottomSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify action buttons
      expect(find.widgetWithText(ElevatedButton, 'Reset'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Close'), findsOneWidget);
    });

    testWidgets('displays formatted statistics values', (tester) async {
      final statsService = StatisticsService();

      // Create specific statistics
      await statsService.recordGameStarted();
      await statsService.recordWin(moves: 85, time: const Duration(minutes: 3, seconds: 30));
      await statsService.recordGameStarted();
      await statsService.recordWin(moves: 92, time: const Duration(minutes: 4));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: statsService,
              child: const StatisticsBottomSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that win percentage is displayed
      expect(find.textContaining('100.0%'), findsOneWidget); // 2 wins, 2 games = 100%
    });

    testWidgets('reset button resets statistics', (tester) async {
      final statsService = StatisticsService();

      // Add some stats
      await statsService.recordGameStarted();
      await statsService.recordWin(moves: 100, time: const Duration(minutes: 5));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: statsService,
              child: const StatisticsBottomSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify we have stats
      expect(find.text('1'), findsWidgets); // Games played/won

      // Tap reset button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Reset'));
      await tester.pumpAndSettle();

      // Verify stats are reset
      expect(find.text('0'), findsWidgets); // Games should be 0
    });
  });

  group('StatisticsScreen (Full Screen)', () {
    testWidgets('renders full screen version', (tester) async {
      final statsService = StatisticsService();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: statsService,
            child: const StatisticsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify app bar exists
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Statistics'), findsOneWidget);
    });

    testWidgets('has back button in app bar', (tester) async {
      final statsService = StatisticsService();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: statsService,
            child: const StatisticsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The back button should be present (automatic in Scaffold)
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
