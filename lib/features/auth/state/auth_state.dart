import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/auth_models.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? message;

  const AuthState({
    required this.status,
    this.user,
    this.message,
  });

  const AuthState.initial() : this(status: AuthStatus.initial);

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? message,
    bool clearMessage = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return const TokenStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokenStorage: ref.watch(tokenStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(apiClient: ref.watch(apiClientProvider));
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository repository;

  AuthController(this.repository) : super(const AuthState.initial());

  Future<bool> restoreSession() async {
    if (!await repository.apiClient.tokenStorage.hasSession()) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return false;
    }

    state = state.copyWith(status: AuthStatus.loading, clearMessage: true);
    try {
      final user = await repository.me();
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (error) {
      await repository.clearSession();
      state = AuthState(
        status: AuthStatus.unauthenticated,
        message: ApiClient.describeError(error),
      );
      return false;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _authenticate(
      () => repository.login(email: email, password: password),
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _authenticate(
      () => repository.register(name: name, email: email, password: password),
    );
  }

  Future<void> loginWithGoogle() async {
    await _authenticate(repository.loginWithGoogle);
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading, clearMessage: true);
    await repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> _authenticate(Future<AuthResponse> Function() action) async {
    state = state.copyWith(status: AuthStatus.loading, clearMessage: true);
    try {
      final response = await action();
      state = AuthState(
        status: AuthStatus.authenticated,
        user: response.user,
      );
    } catch (error) {
      state = AuthState(
        status: AuthStatus.error,
        message: ApiClient.describeError(error),
      );
      rethrow;
    }
  }
}
