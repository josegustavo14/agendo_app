import 'package:agendo/models/rating_model.dart';
import 'package:agendo/repositories/rating_repository.dart';
import 'package:agendo/view_models/rating_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRatingRepository extends Mock implements RatingRepository {}

RatingModel _rating({int id = 1, int score = 5, int professionalId = 10}) =>
    RatingModel(
      id: id,
      score: score,
      comment: 'ok',
      clientId: 100,
      clientName: 'Cliente',
      professionalId: professionalId,
      professionalName: 'Pro',
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  late MockRatingRepository repository;
  late RatingViewModel viewModel;

  setUp(() {
    repository = MockRatingRepository();
    viewModel = RatingViewModel(repository: repository);
  });

  group('loadRatings', () {
    test('caches ratings by professional', () async {
      when(() => repository.fetchRatings(10)).thenAnswer((_) async => [
            _rating(id: 1, score: 5),
            _rating(id: 2, score: 3),
          ]);

      await viewModel.loadRatings(10);

      expect(viewModel.ratingsFor(10), hasLength(2));
      expect(viewModel.isLoadingFor(10), isFalse);
    });

    test('keeps empty list on failure', () async {
      when(() => repository.fetchRatings(10)).thenThrow(Exception('boom'));

      await viewModel.loadRatings(10);

      expect(viewModel.ratingsFor(10), isEmpty);
      expect(viewModel.isLoadingFor(10), isFalse);
    });

    test('does not double-fetch while a request is already in flight', () async {
      var calls = 0;
      when(() => repository.fetchRatings(10)).thenAnswer((_) async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return [_rating()];
      });

      await Future.wait([
        viewModel.loadRatings(10),
        viewModel.loadRatings(10),
      ]);

      expect(calls, 1);
    });
  });

  group('averageFor', () {
    test('null when there are no ratings', () {
      expect(viewModel.averageFor(99), isNull);
    });

    test('computes arithmetic mean', () async {
      when(() => repository.fetchRatings(10)).thenAnswer((_) async => [
            _rating(score: 5),
            _rating(score: 4),
            _rating(score: 3),
          ]);

      await viewModel.loadRatings(10);

      expect(viewModel.averageFor(10), closeTo(4.0, 1e-6));
    });
  });

  group('loadMyRatings', () {
    test('populates myRatings on success', () async {
      when(() => repository.fetchMyRatings())
          .thenAnswer((_) async => [_rating()]);

      await viewModel.loadMyRatings();

      expect(viewModel.myRatings, hasLength(1));
      expect(viewModel.isLoadingMyRatings, isFalse);
    });

    test('keeps empty list on failure', () async {
      when(() => repository.fetchMyRatings()).thenThrow(Exception('boom'));

      await viewModel.loadMyRatings();

      expect(viewModel.myRatings, isEmpty);
    });
  });

  group('submitRating', () {
    test('success: invalidates cache and re-fetches', () async {
      // Inicial: 1 rating
      var fetchCalls = 0;
      when(() => repository.fetchRatings(10)).thenAnswer((_) async {
        fetchCalls++;
        return fetchCalls == 1
            ? [_rating(id: 1)]
            : [_rating(id: 1), _rating(id: 2)];
      });
      when(() => repository.createRating(
            professionalId: any(named: 'professionalId'),
            score: any(named: 'score'),
            comment: any(named: 'comment'),
          )).thenAnswer((_) async {});

      await viewModel.loadRatings(10);
      expect(viewModel.ratingsFor(10), hasLength(1));

      final ok = await viewModel.submitRating(
        professionalId: 10,
        score: 4,
        comment: 'boa',
      );

      expect(ok, isTrue);
      expect(viewModel.submitError, isNull);
      expect(viewModel.ratingsFor(10), hasLength(2));
      expect(fetchCalls, 2);
    });

    test('failure: sets submitError and returns false', () async {
      when(() => repository.createRating(
            professionalId: any(named: 'professionalId'),
            score: any(named: 'score'),
            comment: any(named: 'comment'),
          )).thenThrow(Exception('boom'));

      final ok = await viewModel.submitRating(professionalId: 10, score: 4);

      expect(ok, isFalse);
      expect(viewModel.submitError, 'Erro ao enviar avaliação');
      expect(viewModel.isSubmitting, isFalse);
    });
  });
}
