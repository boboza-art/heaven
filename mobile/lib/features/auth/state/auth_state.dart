import '../models/auth_model.dart';

/// Auth state for the authentication flow.
///
/// Three main states:
/// - [AuthState.initial] — not yet checked stored tokens
/// - [AuthState.authenticated] — user is logged in
/// - [AuthState.unauthenticated] — no valid tokens, show login
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;
  final bool _hasCheckedSession;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    bool hasCheckedSession = false,
  }) : _hasCheckedSession = hasCheckedSession;

  /// Initial state — session not yet restored.
  static const AuthState initial = AuthState();

  /// Whether the user is currently authenticated.
  bool get isAuthenticated => user != null;

  /// Whether we've finished checking stored tokens on app start.
  bool get hasCheckedSession => _hasCheckedSession;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    bool? hasCheckedSession,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasCheckedSession: hasCheckedSession ?? _hasCheckedSession,
    );
  }
}
