import 'package:flutter_test/flutter_test.dart';
import 'dart:math' as math;

int computeNewRating({
  required int current,
  required int opponent,
  required bool won,
  int k = 32,
}) {
  final expected = 1 / (1 + math.pow(10, (opponent - current) / 400));
  final score = won ? 1.0 : 0.0;
  return (current + k * (score - expected)).round();
}

void main() {
  group('ELO rating', () {
    test('equal players: winner gains ~16, loser loses ~16', () {
      const current = 1200;
      const opponent = 1200;

      final winnerRating = computeNewRating(
        current: current,
        opponent: opponent,
        won: true,
      );
      final loserRating = computeNewRating(
        current: current,
        opponent: opponent,
        won: false,
      );

      expect(winnerRating, 1216);
      expect(loserRating, 1184);
    });

    test('strong player beating weak loses few points if they win', () {
      final strong = computeNewRating(
        current: 1600,
        opponent: 1200,
        won: true,
      );
      // Expected ~1603 (small gain since already strong)
      expect(strong, greaterThan(1600));
      expect(strong, lessThan(1610));
    });

    test('weak player beating strong gains many points', () {
      final weak = computeNewRating(
        current: 1200,
        opponent: 1600,
        won: true,
      );
      // Expected ~1230 (big gain for upset)
      expect(weak, greaterThan(1225));
      expect(weak, lessThan(1240));
    });

    test('initial rating is 1200 by convention', () {
      const initialRating = 1200;
      expect(initialRating, 1200);
    });

    test('zero-sum: winner gain equals loser loss for equal players', () {
      const a = 1400;
      const b = 1400;

      final aWins = computeNewRating(current: a, opponent: b, won: true);
      final bLoses = computeNewRating(current: b, opponent: a, won: false);

      expect(aWins - a, equals(a - bLoses));
    });
  });
}
