import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';

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

/// Auth notifier — handles login, register, logout.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _loadToken();
  }

  final _dio = DioClient().dio;

  Future<void> _loadToken() async {
    final token = await SecureStorage.getToken();
    if (token != null) {
      state = state.copyWith(token: token);
      await fetchMe();
    }
  }

  Future<void> register(String email, String password, String fullName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'full_name': fullName,
      });
      final token = response.data['data']['token'];
      await SecureStorage.saveToken(token);
      state = state.copyWith(token: token, isLoading: false);
      await fetchMe();
    } catch (e) {
      final msg = _extractError(e);
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final token = response.data['data']['token'];
      await SecureStorage.saveToken(token);
      state = state.copyWith(token: token, isLoading: false);
      await fetchMe();
    } catch (e) {
      final msg = _extractError(e);
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<void> fetchMe() async {
    try {
      final response = await _dio.get('/auth/me');
      final user = response.data['data']['user'] as Map<String, dynamic>;
      state = state.copyWith(user: user);
    } catch (_) {}
  }

  Future<void> logout() async {
    await SecureStorage.deleteToken();
    state = const AuthState();
  }

  String _extractError(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      return e.response!.data['message']?.toString() ?? 'Something went wrong';
    }
    return 'Network error';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
