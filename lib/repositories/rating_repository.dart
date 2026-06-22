import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:agendo/models/rating_model.dart';
import 'package:agendo/services/api_service.dart';

class RatingRepository {
  final ApiService apiService;

  RatingRepository({required this.apiService});

  Future<List<RatingModel>> fetchRatings(int professionalId) async {
    final response = await apiService.get('/ratings/professional/$professionalId');

    debugPrint('[RatingRepository] GET /ratings/professional/$professionalId status: ${response.statusCode}');
    debugPrint('[RatingRepository] body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => RatingModel.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao buscar avaliações: ${response.statusCode} ${response.body}');
    }
  }

  Future<List<RatingModel>> fetchMyRatings() async {
    final response = await apiService.get('/ratings/my-ratings');

    debugPrint('[RatingRepository] GET /ratings/my-ratings status: ${response.statusCode}');
    debugPrint('[RatingRepository] body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => RatingModel.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao buscar minhas avaliações: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> createRating({
    required int professionalId,
    required int score,
    String? comment,
  }) async {
    final response = await apiService.post('/ratings', body: {
      'professionalId': professionalId,
      'score': score,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });

    debugPrint('[RatingRepository] POST /ratings status: ${response.statusCode}');
    debugPrint('[RatingRepository] body: ${response.body}');

    if (response.statusCode != 201) {
      throw Exception('Erro ao enviar avaliação: ${response.statusCode} ${response.body}');
    }
  }
}
