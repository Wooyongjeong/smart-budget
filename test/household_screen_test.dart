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
  Future<String> loadCurrentDisplayName() async =>
      value.members.firstWhere((member) => member.isMe).name;

  @override
  Future<String> updateDisplayName(String name) async {
    value = HouseholdOverview(
      id: value.id,
      name: value.name,
      members: [
        HouseholdMember(id: 'member-1', name: name.trim(), isMe: true),
        ...value.members.skip(1),
      ],
    );
    return name.trim();
  }

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
  ValueChanged<String>? onDisplayNameChanged,
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
      onDisplayNameChanged: onDisplayNameChanged,
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

    expect(
      find.text('https://smart-budget.app/invite/${'a' * 48}'),
      findsOneWidget,
    );
    expect(find.byTooltip('초대 코드 복사'), findsOneWidget);
  });

  testWidgets('accepts a valid code and refreshes members', (tester) async {
    final repository = _Repository()
      ..value = const HouseholdOverview(
        id: 'household-1',
        name: '초대 대기 가계부',
        members: [HouseholdMember(id: 'member-1', name: '초대자')],
      );
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

  testWidgets('hides invitation acceptance for an active member', (tester) async {
    final repository = _Repository();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('invitation-token')), findsNothing);
    expect(find.text('공동 가계부 참여'), findsNothing);
  });

  testWidgets('uses 나 as the fallback and lets me edit my display name', (
    tester,
  ) async {
    final repository = _Repository()
      ..value = const HouseholdOverview(
        id: 'household-1',
        name: '우리 가계부',
        members: [HouseholdMember(id: 'member-1', name: '나', isMe: true)],
      );
    String? changedName;
    await tester.pumpWidget(
      _app(repository, onDisplayNameChanged: (value) => changedName = value),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('edit-display-name')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '우영');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.text('우영'), findsOneWidget);
    expect(changedName, '우영');
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
