import 'package:flutter/material.dart';
import '../models/rating_model.dart';
import '../repositories/rating_repository.dart';

class RatingViewModel extends ChangeNotifier {
  final RatingRepository repository;

  RatingViewModel({required this.repository});

  // Cache: professionalId -> ratings list
  final Map<int, List<RatingModel>> _cache = {};
  final Set<int> _loading = {};

  bool isSubmitting = false;
  String? submitError;

  List<RatingModel> ratingsFor(int professionalId) =>
      _cache[professionalId] ?? [];

  bool isLoadingFor(int professionalId) => _loading.contains(professionalId);

  double? averageFor(int professionalId) {
    final ratings = _cache[professionalId];
    if (ratings == null || ratings.isEmpty) return null;
    final sum = ratings.fold(0, (acc, r) => acc + r.score);
    return sum / ratings.length;
  }

  Future<void> loadRatings(int professionalId) async {
    if (_loading.contains(professionalId)) return;
    _loading.add(professionalId);
    notifyListeners();

    try {
      final ratings = await repository.fetchRatings(professionalId);
      _cache[professionalId] = ratings;
    } catch (_) {
      _cache[professionalId] = [];
    } finally {
      _loading.remove(professionalId);
      notifyListeners();
    }
  }

  Future<bool> submitRating({
    required int professionalId,
    required int score,
    String? comment,
  }) async {
    isSubmitting = true;
    submitError = null;
    notifyListeners();

    try {
      await repository.createRating(
        professionalId: professionalId,
        score: score,
        comment: comment,
      );
      _cache.remove(professionalId); // invalidate cache
      await loadRatings(professionalId);
      return true;
    } catch (_) {
      submitError = 'Erro ao enviar avaliação';
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
