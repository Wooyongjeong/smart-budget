import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AuthService {
  bool get isSignedIn;
  String? get suggestedDisplayName;
  Stream<AuthState> get authStateChanges;
  Future<AuthResult> signInWithKakao();
  Future<void> signOut();
}

sealed class AuthResult {
  const AuthResult();
}

class AuthStarted extends AuthResult {
  const AuthStarted();
}

class AuthCancelled extends AuthResult {
  const AuthCancelled();
}

class AuthFailed extends AuthResult {
  const AuthFailed(this.message);
  final String message;
}

class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this.redirectUrl, {SupabaseClient? client})
    : client = client ?? Supabase.instance.client;
  final String redirectUrl;
  final SupabaseClient client;

  @override
  bool get isSignedIn => client.auth.currentSession != null;

  @override
  String? get suggestedDisplayName {
    final metadata = client.auth.currentUser?.userMetadata;
    if (metadata == null) return null;
    for (final key in ['nickname', 'name', 'preferred_username']) {
      final value = metadata[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  @override
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  @override
  Future<AuthResult> signInWithKakao() async {
    try {
      final started = await client.auth.signInWithOAuth(
        OAuthProvider.kakao,
        redirectTo: redirectUrl,
      );
      return started ? const AuthStarted() : const AuthCancelled();
    } on AuthException catch (error) {
      return AuthFailed(error.message);
    } catch (_) {
      return const AuthFailed('카카오 로그인 중 문제가 발생했어요. 잠시 후 다시 시도해 주세요.');
    }
  }

  @override
  Future<void> signOut() => client.auth.signOut();
}
