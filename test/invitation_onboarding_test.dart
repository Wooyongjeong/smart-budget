import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_budget/features/household/household_repository.dart';
import 'package:smart_budget/features/household/invitation_onboarding_screen.dart';
import 'package:smart_budget/l10n/generated/app_localizations.dart';

class _Repository implements HouseholdRepository {
  String? accepted;

  @override
  Future<HouseholdOverview> load() async =>
      const HouseholdOverview(id: 'household', name: '우리 가계부', members: []);

  @override
  Future<String> createInvitation(String householdId) async => 'a' * 48;

  @override
  Future<String> acceptInvitation(String token) async {
    accepted = token;
    return 'household';
  }

  @override
  Future<void> leave(String householdId) async {}
}

Widget _app(_Repository repository, VoidCallback complete) => MaterialApp(
  locale: const Locale('ko'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: InvitationOnboardingScreen(
    repository: repository,
    initialToken: 'a' * 48,
    onComplete: complete,
  ),
);

void main() {
  testWidgets('prefills a deep-link token and accepts it after login', (
    tester,
  ) async {
    final repository = _Repository();
    var completed = false;
    await tester.pumpWidget(_app(repository, () => completed = true));
    await tester.pumpAndSettle();

    expect(find.text('a' * 48), findsOneWidget);
    await tester.tap(find.text('공동 가계부 참여'));
    await tester.pumpAndSettle();

    expect(repository.accepted, 'a' * 48);
    expect(completed, isTrue);
  });

  testWidgets('allows a user without an invitation to skip', (tester) async {
    final repository = _Repository();
    var completed = false;
    await tester.pumpWidget(_app(repository, () => completed = true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('나중에 참여할게요'));
    expect(completed, isTrue);
  });
}
