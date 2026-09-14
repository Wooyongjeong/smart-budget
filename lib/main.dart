import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'themes.dart';
import 'entry_form.dart';
import 'auth/auth_config.dart';
import 'auth/auth_screen.dart';
import 'auth/auth_service.dart';
import 'auth/config_missing_screen.dart';
import 'features/transactions/transaction_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = SupabaseConfig.fromEnvironment();
  if (!config.isConfigured) {
    runApp(const MaterialApp(home: ConfigMissingScreen()));
    return;
  }
  await Supabase.initialize(
    url: config.url,
    publishableKey: config.publishableKey,
  );
  final preferences = SharedPreferencesAsync();
  String? saved;
  try {
    saved = await preferences.getString('theme_id');
  } catch (_) {
    // A preferences read failure must not prevent opening the app.
  }
  runApp(
    AuthRoot(
      config: config,
      initialTheme: saved,
      saveTheme: (id) => preferences.setString('theme_id', id),
    ),
  );
}

class AuthRoot extends StatelessWidget {
  const AuthRoot({
    super.key,
    required this.config,
    this.initialTheme,
    required this.saveTheme,
    this.service,
  });
  final SupabaseConfig config;
  final String? initialTheme;
  final Future<void> Function(String) saveTheme;
  final AuthService? service;

  @override
  Widget build(BuildContext context) {
    final auth = service ?? SupabaseAuthService(config.redirectUrl);
    return MaterialApp(
      title: '우리 가계부',
      debugShowCheckedModeBanner: false,
      home: StreamBuilder(
        stream: auth.authStateChanges,
        builder: (context, snapshot) => auth.isSignedIn
            ? BudgetApp(
                initialTheme: initialTheme,
                saveTheme: saveTheme,
                transactionRepository: SupabaseTransactionRepository(),
              )
            : AuthScreen(service: auth),
      ),
    );
  }
}

class BudgetApp extends StatefulWidget {
  const BudgetApp({
    super.key,
    this.initialTheme,
    required this.saveTheme,
    this.transactionRepository,
    this.entryPaymentMethods = const [],
    this.entryMembers = const [],
  });
  final String? initialTheme;
  final Future<void> Function(String) saveTheme;
  final TransactionRepository? transactionRepository;
  final List<PaymentMethodOption> entryPaymentMethods;
  final List<MemberOption> entryMembers;

  @override
  State<BudgetApp> createState() => _BudgetAppState();
}

class _BudgetAppState extends State<BudgetApp> {
  late BudgetPalette palette = palettes.firstWhere(
    (p) => p.id == widget.initialTheme,
    orElse: () => palettes.first,
  );
  int tab = 0;
  bool saving = false;
  bool openingEntry = false;
  final messenger = GlobalKey<ScaffoldMessengerState>();

  Future<void> select(BudgetPalette next) async {
    if (saving || next == palette) return;
    final previous = palette;
    setState(() {
      palette = next;
      saving = true;
    });
    try {
      await widget.saveTheme(next.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => palette = previous);
      messenger.currentState?.showSnackBar(
        const SnackBar(content: Text('테마를 저장하지 못했어요. 다시 선택해 주세요.')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> openEntry(BuildContext context) async {
    if (openingEntry) return;
    setState(() => openingEntry = true);
    try {
      final repository = widget.transactionRepository;
      final data = repository == null
          ? HouseholdContext(
              householdId: '',
              paymentMethods: widget.entryPaymentMethods,
              members: widget.entryMembers,
            )
          : await repository.loadContext();
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EntryForm(
            paymentMethods: data.paymentMethods,
            members: data.members,
            onConfirm: repository == null
                ? null
                : (draft) async {
                    try {
                      await repository.save(data.householdId, draft);
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      messenger.currentState?.showSnackBar(
                        const SnackBar(content: Text('거래를 저장했어요.')),
                      );
                    } on TransactionSaveException catch (error) {
                      messenger.currentState?.showSnackBar(
                        SnackBar(
                          content: Text('거래를 저장하지 못했어요. (${error.code})'),
                        ),
                      );
                    } catch (_) {
                      messenger.currentState?.showSnackBar(
                        const SnackBar(
                          content: Text('거래를 저장하지 못했어요. 다시 시도해 주세요.'),
                        ),
                      );
                    }
                  },
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        messenger.currentState?.showSnackBar(
          const SnackBar(content: Text('가계부 정보를 불러오지 못했어요. 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => openingEntry = false);
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '우리 가계부',
    debugShowCheckedModeBanner: false,
    scaffoldMessengerKey: messenger,
    theme: palette.theme,
    home: Scaffold(
      appBar: AppBar(title: const Text('우리 가계부')),
      floatingActionButton: tab < 2
          ? Builder(
              builder: (context) => FloatingActionButton.extended(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (sheetContext) => SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit_outlined),
                          title: const Text('직접 입력'),
                          subtitle: const Text('수입과 지출을 가계부에 저장'),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            openEntry(context);
                          },
                        ),
                        const ListTile(
                          enabled: false,
                          leading: Icon(Icons.image_outlined),
                          title: Text('이용내역 캡처'),
                          subtitle: Text('AI 분석 기능 준비 중'),
                        ),
                      ],
                    ),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('기록하기'),
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: '캘린더',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: '내역',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: '지갑',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: '설정',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (tab != 3) ...[
              Text(
                ['함께 기록하는 하루', '우리의 수입과 지출', '결제 수단을 한곳에'][tab],
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                [
                  '날짜별 수입과 지출을 확인할 공간이에요.',
                  '일·주·월별로 내역을 모아볼 공간이에요.',
                  '카드 실적과 상품권 잔액을 관리할 공간이에요.',
                ][tab],
              ),
              const SizedBox(height: 32),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    '화면 미리보기\n아직 가계부 데이터가 연결되지 않았어요.\n설정에서 앱 테마를 골라보세요.',
                  ),
                ),
              ),
            ] else ...[
              const Text(
                '앱 테마',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text('우리 가계부를 나만의 색으로\n선택한 테마는 이 기기에만 적용돼요.'),
              const SizedBox(height: 24),
              ...palettes.map(
                (option) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Semantics(
                    selected: option == palette,
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: saving ? null : () => select(option),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      option.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (option == palette)
                                    const Icon(
                                      Icons.check_circle,
                                      semanticLabel: '선택됨',
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                children:
                                    [
                                          option.primary,
                                          option.secondary,
                                          option.background,
                                        ]
                                        .map(
                                          (color) => Container(
                                            width: 44,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: color,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.black12,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '계정 · 공동 가계부',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text('카카오 로그인과 배우자 초대는 다음 단계에서 연결할 예정이에요.'),
            ],
          ],
        ),
      ),
    ),
  );
}
