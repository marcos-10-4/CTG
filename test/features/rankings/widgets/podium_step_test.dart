import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:ctg_app/core/theme/app_theme.dart';
import 'package:ctg_app/features/rankings/domain/entities/ranking_entry.dart';
import 'package:ctg_app/features/rankings/presentation/widgets/podium_step.dart';

void main() {
  final entry = RankingEntry(
    userId: 'uid-1',
    points: 1450,
    wins: 12,
    losses: 3,
    position: 1,
    weeklyDelta: 2,
    updatedAt: DateTime(2026, 5, 1),
    displayName: 'María García',
  );

  testWidgets('PodiumStep shows player name and points', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: 120,
            height: 280,
            child: PodiumStep(entry: entry, position: 1),
          ),
        ),
      ),
    );

    expect(find.text('1450 pts'), findsOneWidget);
    expect(find.text('María'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testGoldens('PodiumStep golden pos 1', (tester) async {
    await loadAppFonts();

    await tester.pumpWidgetBuilder(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: 120,
            height: 280,
            child: PodiumStep(entry: entry, position: 1),
          ),
        ),
      ),
      surfaceSize: const Size(120, 280),
    );

    await screenMatchesGolden(tester, 'podium_step_1');
  });
}
