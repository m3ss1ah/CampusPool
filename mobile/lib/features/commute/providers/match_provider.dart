import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/dio_client.dart';
import '../domain/commute_model.dart';

part 'match_provider.g.dart';

/// State for suggestions list
class SuggestionsState {
  final List<CommuteModel> matches;
  final bool isLoading;
  final String? error;

  const SuggestionsState({
    this.matches = const [],
    this.isLoading = false,
    this.error,
  });
}

@riverpod
class SuggestionsNotifier extends _$SuggestionsNotifier {
  final _dio = DioClient().dio;

  @override
  FutureOr<SuggestionsState> build() {
    return const SuggestionsState();
  }

  Future<void> fetchSuggestions({
    required double lat,
    required double lng,
    required String destLabel,
  }) async {
    state = const AsyncData(SuggestionsState(isLoading: true));

    try {
      final response = await _dio.get('matching/suggest', queryParameters: {
        'lat': lat,
        'lng': lng,
        'dest_label': destLabel,
      });

      final data = response.data['data'] as List;
      final matches = data.map((e) => CommuteModel.fromJson(e)).toList();

      state = AsyncData(SuggestionsState(matches: matches));
    } catch (e) {
      developer.log('fetchSuggestions error: $e', name: 'MatchProvider');
      String msg = 'Failed to load suggestions';
      if (e is DioException && e.response?.data != null) {
        msg = e.response!.data['message']?.toString() ?? msg;
      }
      state = AsyncData(SuggestionsState(error: msg));
    }
  }

  void clear() {
    state = const AsyncData(SuggestionsState());
  }
}
