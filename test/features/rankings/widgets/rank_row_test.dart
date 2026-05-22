import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:ctg_app/core/theme/app_theme.dart';
import 'package:ctg_app/features/rankings/domain/entities/ranking_entry.dart';
import 'package:ctg_app/features/rankings/presentation/widgets/rank_row.dart';

void main() {
  final entry = RankingEntry(
    userId: 'uid-2',
    points: 1320,
    wins: 8,
    losses: 4,
    position: 5,
    weeklyDelta: -1,
    updatedAt: DateTime(2026, 5, 1),
    displayName: 'Carlos Pérez',
  );

  testWidgets('RankRow renders position, name and points', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: RankRow(entry: entry, isCurrentUser: false),
        ),
      ),
    );

    expect(find.text('5'), findsOneWidget);
    expect(find.text('Carlos Pérez'), findsOneWidget);
    expect(find.text('1320'), findsOneWidget);
  });

  testWidgets('RankRow highlights current user', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: RankRow(entry: entry, isCurrentUser: true),
        ),
      ),
    );

    // Current user row has purple soft background
    final container = tester.widget<Container>(find.byType(Container).first);
    final decoration = container.decoration as BoxDecoration?;
    expect(decoration?.color?.value, isNotNull);
  });

  testGoldens('RankRow golden current user', (tester) async {
    await loadAppFonts();

    await tester.pumpWidgetBuilder(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: RankRow(entry: entry, isCurrentUser: true),
        ),
      ),
      surfaceSize: const Size(390, 64),
    );

    await screenMatchesGolden(tester, 'rank_row_current_user');
  });
}
