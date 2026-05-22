import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:ctg_app/core/theme/app_theme.dart';
import 'package:ctg_app/features/events/domain/entities/club_event.dart';
import 'package:ctg_app/features/events/presentation/widgets/event_row.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es', null);
  });

  final event = ClubEvent(
    id: 'ev-1',
    title: 'Torneo Primavera Individual',
    description: 'Torneo interno por categorías.',
    place: 'Pista 1',
    kind: EventKind.tournament,
    startsAt: DateTime(2026, 5, 25, 10, 0),
    endsAt: DateTime(2026, 5, 25, 18, 0),
    capacity: 16,
    registeredCount: 10,
  );

  testWidgets('EventRow renders title, place and capacity', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: EventRow(event: event, onTap: () {}),
        ),
      ),
    );

    expect(find.text('Torneo Primavera Individual'), findsOneWidget);
    expect(find.text('Pista 1'), findsOneWidget);
    expect(find.text('6 PLAZAS'), findsOneWidget);
  });

  testGoldens('EventRow golden', (tester) async {
    await loadAppFonts();

    await tester.pumpWidgetBuilder(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: EventRow(event: event, onTap: () {}),
        ),
      ),
      surfaceSize: const Size(390, 150),
    );

    await screenMatchesGolden(tester, 'event_row');
  });
}
