import 'package:anime_pulse/features/dashboard/domain/entities/dashboard_entities.dart';
import 'package:anime_pulse/features/dashboard/domain/usecases/dashboard_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ComputeLinearRegression', () {
    const regress = ComputeLinearRegression();

    test('ajusta una recta perfecta y R² = 1', () {
      // rating = 5 + 0.01 * episodios
      final pts = [for (final e in [10, 20, 30, 40]) CatalogPoint(episodes: e, rating: 5 + 0.01 * e)];
      final r = regress(pts)!;
      expect(r.slope, closeTo(0.01, 1e-9));
      expect(r.intercept, closeTo(5, 1e-9));
      expect(r.r2, closeTo(1, 1e-9));
      expect(r.predict(100), closeTo(6, 1e-9));
    });

    test('devuelve null con menos de 2 puntos o sin varianza en x', () {
      expect(regress(const [CatalogPoint(episodes: 10, rating: 8)]), isNull);
      expect(
        regress(const [CatalogPoint(episodes: 12, rating: 7), CatalogPoint(episodes: 12, rating: 9)]),
        isNull,
      );
    });
  });

  group('BuildRegistrationTrend', () {
    test('agrupa por mes, ordena y acumula; ignora fechas nulas', () {
      const build = BuildRegistrationTrend();
      final trend = build([
        CatalogPoint(episodes: 1, rating: 1, createdAt: DateTime(2026, 3, 15)),
        CatalogPoint(episodes: 1, rating: 1, createdAt: DateTime(2026, 1, 2)),
        CatalogPoint(episodes: 1, rating: 1, createdAt: DateTime(2026, 3, 1)),
        const CatalogPoint(episodes: 1, rating: 1),
      ]);
      expect(trend.map((t) => t.month), [DateTime(2026, 1), DateTime(2026, 3)]);
      expect(trend.map((t) => t.added), [1, 2]);
      expect(trend.map((t) => t.cumulative), [1, 3]);
    });
  });
}
