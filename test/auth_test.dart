import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_budget/auth/auth_config.dart';
import 'package:smart_budget/auth/auth_screen.dart';
import 'package:smart_budget/auth/auth_service.dart';
import 'localized_test_app.dart';

class FakeAuthService implements AuthService {
  FakeAuthService(this.result);
  final AuthResult result;
  @override
  bool isSignedIn = false;
  @override
  String? suggestedDisplayName;
  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();
  @override
  Future<AuthResult> signInWithKakao() async => result;
  @override
  Future<void> signOut() async {}
}

void main() {
  test('prefers a consented Kakao nickname and ignores blank metadata', () {
    expect(
      suggestedDisplayNameFromMetadata({'nickname': '  민지  ', 'name': '다른 이름'}),
      '민지',
    );
    expect(
      suggestedDisplayNameFromMetadata({'nickname': ' ', 'name': '우영'}),
      '우영',
    );
    expect(suggestedDisplayNameFromMetadata({'nickname': 123}), isNull);
  });

  test('configuration accepts only a complete HTTPS URL and all values', () {
    expect(
      const SupabaseConfig(
        url: '',
        publishableKey: '',
        redirectUrl: '',
      ).isConfigured,
      isFalse,
    );
    expect(
      const SupabaseConfig(
        url: 'http://example.com',
        publishableKey: 'key',
        redirectUrl: 'app://callback',
      ).isConfigured,
      isFalse,
    );
    expect(
      const SupabaseConfig(
        url: 'https://example.supabase.co',
        publishableKey: 'key',
        redirectUrl: 'app://callback',
      ).isConfigured,
      isTrue,
    );
  });

  testWidgets('cancelled and failed Kakao login show recoverable messages', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: AuthScreen(service: FakeAuthService(const AuthCancelled())),
      ),
    );
    await tester.tap(find.text('카카오로 시작하기'));
    await tester.pumpAndSettle();
    expect(find.text('로그인을 취소했어요.'), findsOneWidget);

    await tester.pumpWidget(
      localizedTestApp(
        home: AuthScreen(service: FakeAuthService(const AuthFailed())),
      ),
    );
    await tester.tap(find.text('카카오로 시작하기'));
    await tester.pumpAndSettle();
    expect(find.text('카카오 로그인 중 문제가 발생했어요. 잠시 후 다시 시도해 주세요.'), findsOneWidget);
  });
}
