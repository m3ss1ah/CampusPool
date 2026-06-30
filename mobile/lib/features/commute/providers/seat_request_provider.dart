import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/commute_api.dart';
import '../domain/seat_request_model.dart';

part 'seat_request_provider.g.dart';

/// State for seat request operations
class SeatRequestState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const SeatRequestState({this.isLoading = false, this.error, this.successMessage});
}

@riverpod
class SeatRequestNotifier extends _$SeatRequestNotifier {
  final _api = CommuteApi();

  @override
  FutureOr<SeatRequestState> build() {
    return const SeatRequestState();
  }

  Future<bool> requestSeat({required String commuteId, String? message}) async {
    state = const AsyncData(SeatRequestState(isLoading: true));
    try {
      await _api.createRequest(commuteId: commuteId, message: message);
      state = const AsyncData(SeatRequestState(successMessage: 'Seat request sent!'));
      return true;
    } catch (e) {
      developer.log('requestSeat error: $e', name: 'SeatRequest');
      String msg = 'Failed to send request';
      if (e is DioException && e.response?.data != null) {
        msg = e.response!.data['message']?.toString() ?? msg;
      }
      state = AsyncData(SeatRequestState(error: msg));
      return false;
    }
  }

  Future<bool> respondToRequest(String requestId, String status) async {
    state = const AsyncData(SeatRequestState(isLoading: true));
    try {
      await _api.respondToRequest(requestId, status);
      state = AsyncData(SeatRequestState(successMessage: 'Request $status'));
      return true;
    } catch (e) {
      developer.log('respondToRequest error: $e', name: 'SeatRequest');
      String msg = 'Failed to respond';
      if (e is DioException && e.response?.data != null) {
        msg = e.response!.data['message']?.toString() ?? msg;
      }
      state = AsyncData(SeatRequestState(error: msg));
      return false;
    }
  }

  Future<bool> cancelRequest(String requestId) async {
    state = const AsyncData(SeatRequestState(isLoading: true));
    try {
      await _api.cancelRequest(requestId);
      state = const AsyncData(SeatRequestState(successMessage: 'Request cancelled'));
      return true;
    } catch (e) {
      developer.log('cancelRequest error: $e', name: 'SeatRequest');
      state = const AsyncData(SeatRequestState(error: 'Failed to cancel'));
      return false;
    }
  }
}

/// Provider for incoming requests list
@riverpod
class IncomingRequestsNotifier extends _$IncomingRequestsNotifier {
  final _api = CommuteApi();

  @override
  FutureOr<List<SeatRequestModel>> build() {
    return [];
  }

  Future<void> fetch() async {
    state = const AsyncLoading();
    try {
      final requests = await _api.getIncomingRequests();
      state = AsyncData(requests);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}

/// Provider for outgoing requests list
@riverpod
class OutgoingRequestsNotifier extends _$OutgoingRequestsNotifier {
  final _api = CommuteApi();

  @override
  FutureOr<List<SeatRequestModel>> build() {
    return [];
  }

  Future<void> fetch() async {
    state = const AsyncLoading();
    try {
      final requests = await _api.getOutgoingRequests();
      state = AsyncData(requests);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}
