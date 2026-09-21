import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_budget/features/household/household_repository.dart';
import 'package:smart_budget/features/household/nickname_onboarding_screen.dart';
import 'package:smart_budget/l10n/generated/app_localizations.dart';
import 'localized_test_app.dart';

class _Repository implements HouseholdRepository {
  String? saved;
  String? updateError;

  @override
  Future<HouseholdOverview> load() async =>
      const HouseholdOverview(id: 'household', name: '가계부', members: []);

  @override
  Future<String> loadCurrentDisplayName() async => saved ?? '나';

  @override
  Future<String> updateDisplayName(String name) async {
    if (updateError case final code?) throw HouseholdException(code);
    saved = name;
    return name;
  }

  @override
  Future<String> createInvitation(String householdId) async => 'a' * 48;

  @override
  Future<String> acceptInvitation(String token) async => 'household';

  @override
  Future<void> leave(String householdId) async {}
}

void main() {
  testWidgets('uses the fallback name and saves an edited name', (
    tester,
  ) async {
    final repository = _Repository();
    String? completed;
    await tester.pumpWidget(
      localizedTestApp(
        home: NicknameOnboardingScreen(
          repository: repository,
          initialName: '나',
          onComplete: (name) => completed = name,
        ),
      ),
    );

    expect(find.text('나'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('onboarding-nickname')),
      '민지',
    );
    await tester.tap(find.text('이 이름으로 시작하기'));
    await tester.pumpAndSettle();

    expect(repository.saved, '민지');
    expect(completed, '민지');
  });

  testWidgets('shows the Kakao nickname as the editable initial value', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: NicknameOnboardingScreen(
          repository: _Repository(),
          initialName: '카카오닉네임',
          onComplete: (_) {},
        ),
      ),
    );
    expect(find.text('카카오닉네임'), findsOneWidget);
    expect(
      find.text(
        AppLocalizations.of(
          tester.element(find.byType(NicknameOnboardingScreen)),
        )!.nicknameOnboardingTitle,
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows a specific validation error returned by the server', (
    tester,
  ) async {
    final repository = _Repository()..updateError = 'display_name_invalid';
    await tester.pumpWidget(
      localizedTestApp(
        home: NicknameOnboardingScreen(
          repository: repository,
          initialName: '나',
          onComplete: (_) {},
        ),
      ),
    );

    await tester.tap(find.text('이 이름으로 시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('이름을 한 글자 이상 입력해 주세요.'), findsOneWidget);
  });
}
