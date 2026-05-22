import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:ctg_app/core/theme/app_theme.dart';
import 'package:ctg_app/features/feed/domain/entities/club_post.dart';
import 'package:ctg_app/features/feed/presentation/widgets/post_card.dart';

void main() {
  final _post = ClubPost(
    id: 'post-1',
    authorId: 'uid-1',
    title: 'Torneo de Primavera 2026',
    body:
        'Este año el torneo de primavera contará con categorías sub-18, '
        'adultos y veteranos. Plazas limitadas, ¡inscríbete ya!',
    kind: PostKind.tournament,
    likesCount: 24,
    commentsCount: 5,
    pinned: true,
    createdAt: _fixedDate,
    authorName: 'Admin CTG',
    authorRole: 'admin',
  );

  testWidgets('PostCard renders title and author', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: PostCard(post: _post, onTap: () {}),
          ),
        ),
      ),
    );

    expect(find.text('Torneo de Primavera 2026'), findsOneWidget);
    expect(find.text('Admin CTG'), findsOneWidget);
    expect(find.text('FIJADO'), findsOneWidget);
  });

  testGoldens('PostCard golden', (tester) async {
    await loadAppFonts();

    await tester.pumpWidgetBuilder(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: PostCard(post: _post, onTap: () {}),
          ),
        ),
      ),
      surfaceSize: const Size(390, 320),
    );

    await screenMatchesGolden(tester, 'post_card');
  });
}

// Fixed date for deterministic goldens
final _fixedDate = DateTime(2026, 5, 1, 10, 0);
