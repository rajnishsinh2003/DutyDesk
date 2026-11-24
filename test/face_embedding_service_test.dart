import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:duty_desk/core/config/face_config.dart';
import 'package:duty_desk/core/services/face_embedding_service.dart';

void main() {
  group('FaceEmbeddingService - Cosine Similarity Tests', () {
    test('Identical unit vectors yield similarity 1.0', () {
      final vecA = [0.6, 0.8, 0.0];
      final vecB = [0.6, 0.8, 0.0];

      final sim = FaceEmbeddingService.cosineSimilarity(vecA, vecB);
      expect(sim, closeTo(1.0, 1e-5));
    });

    test('Orthogonal unit vectors yield similarity 0.0', () {
      final vecA = [1.0, 0.0, 0.0];
      final vecB = [0.0, 1.0, 0.0];

      final sim = FaceEmbeddingService.cosineSimilarity(vecA, vecB);
      expect(sim, closeTo(0.0, 1e-5));
    });

    test('Opposite unit vectors yield similarity -1.0', () {
      final vecA = [0.0, 1.0, 0.0];
      final vecB = [0.0, -1.0, 0.0];

      final sim = FaceEmbeddingService.cosineSimilarity(vecA, vecB);
      expect(sim, closeTo(-1.0, 1e-5));
    });

    test('Vectors with mismatched lengths yield 0.0 safety fallback', () {
      final vecA = [1.0, 0.0];
      final vecB = [1.0, 0.0, 0.0];

      final sim = FaceEmbeddingService.cosineSimilarity(vecA, vecB);
      expect(sim, equals(0.0));
    });

    test('Synthetic 192-d MobileFaceNet vectors with small perturbation score high', () {
      final random = Random(42);
      final vecA = List.generate(192, (_) => random.nextDouble() - 0.5);
      final normA = sqrt(vecA.fold(0.0, (s, x) => s + x * x));
      final unitA = vecA.map((x) => x / normA).toList();

      // Slightly perturbed copy
      final unitB = unitA.map((x) => x + (random.nextDouble() - 0.5) * 0.05).toList();
      final normB = sqrt(unitB.fold(0.0, (s, x) => s + x * x));
      final normUnitB = unitB.map((x) => x / normB).toList();

      final sim = FaceEmbeddingService.cosineSimilarity(unitA, normUnitB);
      expect(sim, greaterThanOrEqualTo(0.90));
    });
  });

  group('FaceConfig - Verification Threshold Logic', () {
    test('Score at or above match threshold qualifies as MATCH', () {
      const matchScore = 0.52;
      expect(matchScore >= FaceConfig.matchThreshold, isTrue);
    });

    test('Score in borderline range [0.40, 0.50) triggers stabilization frame', () {
      const borderlineScore = 0.44;
      final isBorderline = borderlineScore >= FaceConfig.borderlineThreshold &&
          borderlineScore < FaceConfig.matchThreshold;
      expect(isBorderline, isTrue);
    });

    test('Score below 0.40 triggers direct rejection', () {
      const rejectedScore = 0.35;
      final isRejected = rejectedScore < FaceConfig.borderlineThreshold;
      expect(isRejected, isTrue);
    });
  });

  group('FaceConfig - Pose Angle Validation Logic', () {
    bool isFrontValid(double yaw, double pitch, double roll) {
      return yaw.abs() <= FaceConfig.maxFrontYaw &&
          pitch.abs() <= FaceConfig.maxPitch &&
          roll.abs() <= FaceConfig.maxRoll;
    }

    bool isLeftValid(double yaw) {
      return yaw >= FaceConfig.minLeftYaw && yaw <= FaceConfig.maxLeftYaw;
    }

    bool isRightValid(double yaw) {
      return yaw >= FaceConfig.minRightYaw && yaw <= FaceConfig.maxRightYaw;
    }

    test('Front face validation passes within ±10° yaw', () {
      expect(isFrontValid(0.0, 0.0, 0.0), isTrue);
      expect(isFrontValid(8.5, 4.0, -2.0), isTrue);
      expect(isFrontValid(-9.9, 0.0, 0.0), isTrue);
      expect(isFrontValid(12.5, 0.0, 0.0), isFalse); // turned too far
    });

    test('Front face rejects high pitch (nod up/down) or sideways roll', () {
      expect(isFrontValid(0.0, 18.0, 0.0), isFalse);
      expect(isFrontValid(0.0, 0.0, -20.0), isFalse);
    });

    test('Left profile validation accepts +20° to +40° yaw', () {
      expect(isLeftValid(30.0), isTrue);
      expect(isLeftValid(22.0), isTrue);
      expect(isLeftValid(38.0), isTrue);
      expect(isLeftValid(15.0), isFalse); // not turned enough
      expect(isLeftValid(45.0), isFalse); // turned too far
    });

    test('Right profile validation accepts -20° to -40° yaw', () {
      expect(isRightValid(-30.0), isTrue);
      expect(isRightValid(-22.0), isTrue);
      expect(isRightValid(-38.0), isTrue);
      expect(isRightValid(-15.0), isFalse); // not turned enough
      expect(isRightValid(-48.0), isFalse); // turned too far
    });
  });

  group('FaceConfig - Cross-Angle Enrollment Pair Consistency', () {
    test('Enforces same-person pair similarity thresholds', () {
      const frontLeftSim = 0.55;
      const frontRightSim = 0.58;
      const leftRightSim = 0.42;

      expect(frontLeftSim >= FaceConfig.minPairSimilarityFrontSide, isTrue);
      expect(frontRightSim >= FaceConfig.minPairSimilarityFrontSide, isTrue);
      expect(leftRightSim >= FaceConfig.minPairSimilaritySides, isTrue);
    });

    test('Rejects near-duplicate captures (> 0.98 similarity)', () {
      const identicalSim = 0.99;
      expect(identicalSim > FaceConfig.maxNearDuplicateSimilarity, isTrue);
    });
  });
}
