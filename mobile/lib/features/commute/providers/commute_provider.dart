import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/commute_api.dart';
import '../domain/commute_model.dart';

part 'commute_provider.g.dart';

/// State for nearby commutes list
class NearbyCommutesState {
  final List<CommuteModel> commutes;
  final bool isLoading;
  final String? error;

  const NearbyCommutesState({
    this.commutes = const [],
    this.isLoading = false,
    this.error,
  });

  NearbyCommutesState copyWith({
    List<CommuteModel>? commutes,
    bool? isLoading,
    String? error,
  }) => NearbyCommutesState(
    commutes: commutes ?? this.commutes,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

@riverpod
class NearbyCommutesNotifier extends _$NearbyCommutesNotifier {
  final _api = CommuteApi();

  @override
  FutureOr<NearbyCommutesState> build() {
    return const NearbyCommutesState();
  }

  Future<void> fetchNearby({required double lat, required double lng, double radius = 5}) async {
    final curr = state.value ?? const NearbyCommutesState();
    state = AsyncData(curr.copyWith(isLoading: true, error: null));

    try {
      final result = await _api.getNearby(lat: lat, lng: lng, radius: radius);
      state = AsyncData(NearbyCommutesState(commutes: result.commutes));
    } catch (e) {
      developer.log('fetchNearby error: $e', name: 'CommuteProvider');
      state = AsyncData(curr.copyWith(isLoading: false, error: _extractError(e)));
    }
  }

  String _extractError(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      return e.response!.data['message']?.toString() ?? 'Something went wrong';
    }
    return 'Network error';
  }
}

/// State for creating a commute
class CreateCommuteState {
  final bool isLoading;
  final String? error;
  final CommuteModel? created;

  const CreateCommuteState({this.isLoading = false, this.error, this.created});

  CreateCommuteState copyWith({bool? isLoading, String? error, CommuteModel? created}) =>
      CreateCommuteState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        created: created ?? this.created,
      );
}

@riverpod
class CreateCommuteNotifier extends _$CreateCommuteNotifier {
  final _api = CommuteApi();

  @override
  FutureOr<CreateCommuteState> build() {
    return const CreateCommuteState();
  }

  Future<bool> createCommute(Map<String, dynamic> data) async {
    state = const AsyncData(CreateCommuteState(isLoading: true));
    try {
      final commute = await _api.createCommute(data);
      state = AsyncData(CreateCommuteState(created: commute));
      return true;
    } catch (e) {
      developer.log('createCommute error: $e', name: 'CommuteProvider');
      String msg = 'Failed to create commute';
      if (e is DioException && e.response?.data != null) {
        msg = e.response!.data['message']?.toString() ?? msg;
      }
      state = AsyncData(CreateCommuteState(error: msg));
      return false;
    }
  }
}

/// Provider for commute detail
@riverpod
class CommuteDetailNotifier extends _$CommuteDetailNotifier {
  final _api = CommuteApi();

  @override
  FutureOr<CommuteModel?> build() {
    return null;
  }

  Future<void> fetchDetail(String commuteId) async {
    state = const AsyncLoading();
    try {
      final commute = await _api.getById(commuteId);
      state = AsyncData(commute);
    } catch (e) {
      developer.log('fetchDetail error: $e', name: 'CommuteProvider');
      state = AsyncError(e, StackTrace.current);
    }
  }
}

/// Provider for my commutes
@riverpod
class MyCommutesNotifier extends _$MyCommutesNotifier {
  final _api = CommuteApi();

  @override
  FutureOr<List<CommuteModel>> build() {
    return [];
  }

  Future<void> fetchMyCommutes({String status = 'all'}) async {
    state = const AsyncLoading();
    try {
      final commutes = await _api.getMyCommutes(status: status);
      state = AsyncData(commutes);
    } catch (e) {
      developer.log('fetchMyCommutes error: $e', name: 'CommuteProvider');
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> updateStatus(String commuteId, String newStatus) async {
    try {
      await _api.updateStatus(commuteId, newStatus);
      await fetchMyCommutes();
    } catch (e) {
      developer.log('updateStatus error: $e', name: 'CommuteProvider');
    }
  }
}
