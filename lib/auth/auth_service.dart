import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AuthService {
  bool get isSignedIn;
  String? get suggestedDisplayName;
  Stream<AuthState> get authStateChanges;
  Future<AuthResult> signInWithKakao();
  Future<void> signOut();
  Future<void> deleteAccount();
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
  const AuthFailed();
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
    return suggestedDisplayNameFromMetadata(
      client.auth.currentUser?.userMetadata,
    );
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
    } on AuthException {
      return const AuthFailed();
    } catch (_) {
      return const AuthFailed();
    }
  }

  @override
  Future<void> signOut() => client.auth.signOut();

  @override
  Future<void> deleteAccount() async {
    final response = await client.functions.invoke('delete-account', body: {});
    if (response.data is Map && (response.data as Map)['deleted'] == true) {
      // The account is already gone; local sign-out must not report a false
      // deletion failure if the remote sign-out endpoint rejects its old token.
      try {
        await client.auth.signOut();
      } catch (_) {
        // GoTrue clears the local session before contacting the auth server.
      }
      return;
    }
    throw const AuthException('delete_failed');
  }
}

String? suggestedDisplayNameFromMetadata(Map<String, dynamic>? metadata) {
  if (metadata == null) return null;
  for (final key in ['nickname', 'name', 'full_name', 'preferred_username']) {
    final value = metadata[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}
