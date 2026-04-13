import 'package:flutter/foundation.dart';
import '../models/rating_model.dart';
import '../repositories/rating_repository.dart';

class RatingViewModel extends ChangeNotifier {
  final RatingRepository repository;

  RatingViewModel({required this.repository});

  // Cache: professionalId -> ratings list
  final Map<int, List<RatingModel>> _cache = {};
  final Set<int> _loading = {};

  List<RatingModel> _myRatings = [];
  bool _isLoadingMyRatings = false;

  bool isSubmitting = false;
  String? submitError;

  List<RatingModel> get myRatings => _myRatings;
  bool get isLoadingMyRatings => _isLoadingMyRatings;

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
    } catch (e, st) {
      debugPrint('[RatingViewModel] Erro ao carregar avaliações: $e');
      debugPrint(st.toString());
      _cache[professionalId] = [];
    } finally {
      _loading.remove(professionalId);
      notifyListeners();
    }
  }

  Future<void> loadMyRatings() async {
    _isLoadingMyRatings = true;
    notifyListeners();

    try {
      _myRatings = await repository.fetchMyRatings();
    } catch (e, st) {
      debugPrint('[RatingViewModel] Erro ao carregar minhas avaliações: $e');
      debugPrint(st.toString());
      _myRatings = [];
    } finally {
      _isLoadingMyRatings = false;
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
    } catch (e, st) {
      debugPrint('[RatingViewModel] Erro ao enviar avaliação: $e');
      debugPrint(st.toString());
      submitError = 'Erro ao enviar avaliação';
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
