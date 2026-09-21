import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_budget/features/household/household_repository.dart';
import 'package:smart_budget/features/household/household_screen.dart';
import 'package:smart_budget/l10n/generated/app_localizations.dart';

class _Repository implements HouseholdRepository {
  HouseholdOverview value = const HouseholdOverview(
    id: 'household-1',
    name: '우리 가계부',
    members: [HouseholdMember(id: 'member-1', name: '우영', isMe: true)],
  );
  String? acceptedToken;
  bool left = false;
  String? createError;

  @override
  Future<HouseholdOverview> load() async => value;

  @override
  Future<String> createInvitation(String householdId) async {
    if (createError != null) throw HouseholdException(createError!);
    return 'a' * 48;
  }

  @override
  Future<String> acceptInvitation(String token) async {
    acceptedToken = token;
    value = const HouseholdOverview(
      id: 'household-2',
      name: '함께 가계부',
      members: [
        HouseholdMember(id: 'member-1', name: '우영', isMe: true),
        HouseholdMember(id: 'member-2', name: '배우자'),
      ],
    );
    return value.id;
  }

  @override
  Future<void> leave(String householdId) async => left = true;
}

Widget _app(
  _Repository repository, {
  Future<void> Function()? onLeft,
  ValueChanged<String>? onHouseholdChanged,
}) {
  return MaterialApp(
    locale: const Locale('ko'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: HouseholdScreen(
      repository: repository,
      onLeft: onLeft ?? () async {},
      onHouseholdChanged: onHouseholdChanged,
    ),
  );
}

void main() {
  testWidgets('creates and displays a one-time invitation code', (
    tester,
  ) async {
    final repository = _Repository();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('구성원 1/2명'), findsOneWidget);
    await tester.tap(find.text('초대 코드 만들기'));
    await tester.pumpAndSettle();

    expect(find.text('a' * 48), findsOneWidget);
    expect(find.byTooltip('초대 코드 복사'), findsOneWidget);
  });

  testWidgets('accepts a valid code and refreshes members', (tester) async {
    final repository = _Repository();
    String? selectedHousehold;
    await tester.pumpWidget(
      _app(
        repository,
        onHouseholdChanged: (value) => selectedHousehold = value,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('invitation-token')),
      'b' * 48,
    );
    await tester.tap(find.text('공동 가계부 참여'));
    await tester.pumpAndSettle();

    expect(repository.acceptedToken, 'b' * 48);
    expect(selectedHousehold, 'household-2');
    expect(find.text('구성원 2/2명'), findsOneWidget);
    expect(find.text('배우자'), findsOneWidget);
  });

  testWidgets('maps a full household error to an actionable message', (
    tester,
  ) async {
    final repository = _Repository()..createError = 'household_full';
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('초대 코드 만들기'));
    await tester.pumpAndSettle();

    expect(find.text('공동 가계부에는 두 명까지만 참여할 수 있어요.'), findsOneWidget);
  });

  testWidgets('leave requires confirmation and clears the signed-in session', (
    tester,
  ) async {
    final repository = _Repository();
    var signedOut = false;
    await tester.pumpWidget(
      _app(repository, onLeft: () async => signedOut = true),
    );
    await tester.pumpAndSettle();

    final leaveButton = find.byKey(const ValueKey('leave-household')).first;
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(leaveButton);
    await tester.pumpAndSettle();
    expect(repository.left, isFalse);
    await tester.tap(find.widgetWithText(FilledButton, '공동 가계부 나가기'));
    await tester.pumpAndSettle();

    expect(repository.left, isTrue);
    expect(signedOut, isTrue);
  });
}
