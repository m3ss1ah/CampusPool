import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';

part 'auth_provider.g.dart';

/// Auth state — holds token and user data.
class AuthState {
  final String? token;
  final Map<String, dynamic>? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.token, this.user, this.isLoading = false, this.error});

  AuthState copyWith({
    String? token,
    Map<String, dynamic>? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      token: token ?? this.token,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

@riverpod
class AuthNotifier extends _$AuthNotifier {
  late final Dio _dio;

  @override
  FutureOr<AuthState> build() async {
    _dio = DioClient().dio;
    final token = await SecureStorage.getToken();
    
    if (token != null) {
      try {
        final response = await _dio.get('users/profile');
        // Profile endpoint returns data as the user object directly
        final user = response.data['data'] as Map<String, dynamic>;
        return AuthState(token: token, user: user);
      } catch (_) {
        // Token might be invalid
      }
    }
    return const AuthState();
  }

  Future<void> register(String email, String password, String fullName) async {
    final curr = state.value ?? const AuthState();
    state = AsyncData(curr.copyWith(isLoading: true, error: null));
    try {
      final response = await _dio.post('auth/register', data: {
        'email': email,
        'password': password,
        'full_name': fullName,
      });
      final token = response.data['data']['token'] as String;
      await SecureStorage.saveToken(token);
      
      final meRes = await _dio.get('users/profile', options: Options(headers: {'Authorization': 'Bearer $token'}));
      // Profile endpoint returns data as the user object directly
      final user = meRes.data['data'] as Map<String, dynamic>;

      state = AsyncData(curr.copyWith(token: token, user: user, isLoading: false));
    } catch (e) {
      final msg = _extractError(e);
      state = AsyncData(curr.copyWith(isLoading: false, error: msg));
    }
  }

  Future<void> login(String email, String password) async {
    final curr = state.value ?? const AuthState();
    state = AsyncData(curr.copyWith(isLoading: true, error: null));
    try {
      final response = await _dio.post('auth/login', data: {
        'email': email,
        'password': password,
      });
      final token = response.data['data']['token'] as String;
      await SecureStorage.saveToken(token);

      final meRes = await _dio.get('users/profile', options: Options(headers: {'Authorization': 'Bearer $token'}));
      // Profile endpoint returns data as the user object directly
      final user = meRes.data['data'] as Map<String, dynamic>;

      state = AsyncData(curr.copyWith(token: token, user: user, isLoading: false));
    } catch (e) {
      final msg = _extractError(e);
      state = AsyncData(curr.copyWith(isLoading: false, error: msg));
    }
  }

  Future<void> fetchMe() async {
    try {
      final response = await _dio.get('users/profile');
      // Profile endpoint returns data as the user object directly
      final user = response.data['data'] as Map<String, dynamic>;
      final curr = state.value ?? const AuthState();
      state = AsyncData(curr.copyWith(user: user));
    } catch (_) {}
  }

  Future<void> logout() async {
    await SecureStorage.deleteToken();
    state = const AsyncData(AuthState());
  }

  String _extractError(dynamic e) {
    developer.log('AUTH ERROR: $e', name: 'AuthNotifier');
    if (e is DioException) {
      developer.log('DIO type: ${e.type}', name: 'AuthNotifier');
      developer.log('DIO message: ${e.message}', name: 'AuthNotifier');
      developer.log('DIO response: ${e.response?.data}', name: 'AuthNotifier');
      if (e.response?.data != null) {
        return e.response!.data['message']?.toString() ?? 'Server error (${e.response?.statusCode})';
      }
      // Show the actual connection error type
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          return 'Connection timed out – is the backend running?';
        case DioExceptionType.connectionError:
          return 'Cannot reach server (${e.message})';
        case DioExceptionType.receiveTimeout:
          return 'Server took too long to respond';
        default:
          return 'Network error: ${e.type.name} – ${e.message}';
      }
    }
    return 'Unexpected error: $e';
  }
}
