import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'l10n/generated/app_localizations.dart';

import 'themes.dart';
import 'entry_form.dart';
import 'money_input.dart';
import 'auth/auth_config.dart';
import 'auth/auth_screen.dart';
import 'auth/auth_service.dart';
import 'auth/config_missing_screen.dart';
import 'features/transactions/transaction_repository.dart';
import 'features/transactions/ai_review_screen.dart';
import 'features/transactions/receipt_analysis.dart';
import 'features/payment_methods/payment_methods_screen.dart';
import 'features/household/household_repository.dart';
import 'features/household/household_screen.dart';
import 'features/household/invitation_link.dart';
import 'features/household/invitation_onboarding_screen.dart';
import 'features/household/nickname_onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = SupabaseConfig.fromEnvironment();
  if (!config.isConfigured) {
    runApp(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ConfigMissingScreen(),
      ),
    );
    return;
  }
  await Supabase.initialize(
    url: config.url,
    publishableKey: config.publishableKey,
  );
  final preferences = SharedPreferencesAsync();
  String? saved;
  String? savedLocale;
  try {
    saved = await preferences.getString('theme_id');
    savedLocale = await preferences.getString('locale_code');
  } catch (_) {
    // A preferences read failure must not prevent opening the app.
  }
  runApp(
    AuthRoot(
      config: config,
      initialTheme: saved,
      initialLocale: savedLocale,
      saveTheme: (id) => preferences.setString('theme_id', id),
      saveLocale: (code) => preferences.setString('locale_code', code),
    ),
  );
}

class CalendarOverview extends StatelessWidget {
  const CalendarOverview({
    super.key,
    required this.selectedDate,
    required this.result,
    required this.onDateChanged,
  });
  final DateTime selectedDate;
  final TransactionQueryResult? result;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items =
        result?.items
            .where((item) => item['occurred_on'] == _date(selectedDate))
            .toList() ??
        [];
    return Column(
      children: [
        CalendarDatePicker(
          initialDate: selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          onDateChanged: onDateChanged,
        ),
        const SizedBox(height: 8),
        if (result == null)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          )
        else if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.noTransactionsForDate),
          )
        else
          Card(
            child: Column(
              children: items
                  .map(
                    (item) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 19,
                        ),
                      ),
                      title: Text(
                        item['merchant'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      trailing: Text(
                        l10n.formattedAmount(
                          formatWon((item['amount_won'] as num).toInt()),
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.eyebrow, required this.title});
  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ),
        CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.11),
          child: Text(
            '우',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _MonthlySummaryCard extends StatelessWidget {
  const _MonthlySummaryCard({required this.result});
  final TransactionQueryResult? result;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final expense = result?.totalExpense ?? 0;
    final income = result?.totalIncome ?? 0;
    final balance = income - expense;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, Color.lerp(primary, Colors.black, 0.34)!],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이번 달 남은 금액',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Text(
            '${formatWon(balance)}원',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  '수입 +${formatWon(income)}원',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              Text(
                '지출 −${formatWon(expense)}원',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AuthRoot extends StatefulWidget {
  const AuthRoot({
    super.key,
    required this.config,
    this.initialTheme,
    this.initialLocale,
    required this.saveTheme,
    required this.saveLocale,
    this.service,
  });
  final SupabaseConfig config;
  final String? initialTheme;
  final String? initialLocale;
  final Future<void> Function(String) saveTheme;
  final Future<void> Function(String) saveLocale;
  final AuthService? service;

  @override
  State<AuthRoot> createState() => _AuthRootState();
}

class _AuthRootState extends State<AuthRoot> {
  late final AuthService auth =
      widget.service ?? SupabaseAuthService(widget.config.redirectUrl);
  late final SupabaseTransactionRepository transactionRepository =
      SupabaseTransactionRepository();
  late final SupabaseHouseholdRepository householdRepository =
      SupabaseHouseholdRepository();
  final appLinks = AppLinks();
  StreamSubscription<Uri>? linkSubscription;
  StreamSubscription<AuthState>? authSubscription;
  String? pendingInvitationToken;
  Future<HouseholdOverview>? initialHouseholdCheck;
  bool onboardingSkipped = false;
  bool nicknameOnboardingCompleted = false;
  String? activeUserId;

  @override
  void initState() {
    super.initState();
    authSubscription = auth.authStateChanges.listen(
      _authStateChanged,
      onError: (_) {},
    );
    _listenForInvitationLinks();
  }

  Future<void> _listenForInvitationLinks() async {
    linkSubscription = appLinks.uriLinkStream.listen(
      _receiveInvitationLink,
      onError: (_) {},
    );
    try {
      final initial = await appLinks.getInitialLink();
      if (initial != null) _receiveInvitationLink(initial);
    } catch (_) {
      // A missing initial link must not prevent authentication.
    }
  }

  void _authStateChanged(AuthState state) {
    final nextUserId = state.session?.user.id;
    final userChanged = nextUserId != activeUserId;
    final signedOut = state.event == AuthChangeEvent.signedOut;
    if (!mounted) return;
    setState(() {
      if (signedOut) {
        activeUserId = null;
        initialHouseholdCheck = null;
        onboardingSkipped = false;
        nicknameOnboardingCompleted = false;
        pendingInvitationToken = null;
      } else if (userChanged && nextUserId != null) {
        activeUserId = nextUserId;
        initialHouseholdCheck = null;
        onboardingSkipped = false;
        nicknameOnboardingCompleted = false;
      }
    });
  }

  void _receiveInvitationLink(Uri uri) {
    final token = invitationTokenFromUri(
      uri,
      allowedWebHost: Uri.parse(widget.config.invitationLinkBaseUrl).host,
    );
    if (token == null || !mounted) return;
    setState(() => pendingInvitationToken = token);
  }

  @override
  void dispose() {
    linkSubscription?.cancel();
    authSubscription?.cancel();
    super.dispose();
  }

  void finishInvitation() {
    if (mounted) {
      setState(() {
        pendingInvitationToken = null;
        onboardingSkipped = true;
      });
    }
  }

  Widget _signedInHome() {
    if (onboardingSkipped && pendingInvitationToken == null) {
      return _budgetApp();
    }
    initialHouseholdCheck ??= householdRepository.load();
    return FutureBuilder<HouseholdOverview>(
      future: initialHouseholdCheck,
      builder: (context, snapshot) {
        if (snapshot.hasError &&
            snapshot.error is HouseholdException &&
            (snapshot.error! as HouseholdException).code == 'not_found') {
          if (!nicknameOnboardingCompleted) {
            return NicknameOnboardingScreen(
              repository: householdRepository,
              initialName: auth.suggestedDisplayName ?? '나',
              onComplete: (_) => setState(() {
                nicknameOnboardingCompleted = true;
              }),
            );
          }
          return _invitationOnboarding();
        }
        if (!snapshot.hasData && !snapshot.hasError) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (pendingInvitationToken != null) {
          return _invitationOnboarding();
        }
        return _budgetApp();
      },
    );
  }

  Widget _invitationOnboarding() => InvitationOnboardingScreen(
    repository: householdRepository,
    initialToken: pendingInvitationToken,
    onAccepted: transactionRepository.useHousehold,
    onComplete: finishInvitation,
  );

  Widget _budgetApp() => BudgetApp(
    initialTheme: widget.initialTheme,
    initialLocale: widget.initialLocale,
    saveTheme: widget.saveTheme,
    saveLocale: widget.saveLocale,
    transactionRepository: transactionRepository,
    householdRepository: householdRepository,
    onHouseholdChanged: transactionRepository.useHousehold,
    onSignOut: auth.signOut,
    invitationLinkBaseUrl: widget.config.invitationLinkBaseUrl,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: lookupAppLocalizations(
        Locale(widget.initialLocale ?? 'ko'),
      ).appTitle,
      locale: Locale(widget.initialLocale ?? 'ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      home: auth.isSignedIn ? _signedInHome() : AuthScreen(service: auth),
    );
  }
}

class BudgetApp extends StatefulWidget {
  const BudgetApp({
    super.key,
    this.initialTheme,
    this.initialLocale,
    required this.saveTheme,
    this.saveLocale,
    this.transactionRepository,
    this.householdRepository,
    this.onSignOut,
    this.onHouseholdChanged,
    this.invitationLinkBaseUrl = 'https://smart-budget.app/invite',
    this.entryPaymentMethods = const [],
    this.entryMembers = const [],
  });
  final String? initialTheme;
  final String? initialLocale;
  final Future<void> Function(String) saveTheme;
  final Future<void> Function(String)? saveLocale;
  final TransactionRepository? transactionRepository;
  final HouseholdRepository? householdRepository;
  final Future<void> Function()? onSignOut;
  final ValueChanged<String>? onHouseholdChanged;
  final String invitationLinkBaseUrl;
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
  late Locale locale = Locale(widget.initialLocale ?? 'ko');
  int tab = 0;
  bool saving = false;
  bool openingEntry = false;
  DateTime selectedDate = DateTime.now();
  late Future<TransactionQueryResult>? overview = _loadOverview(selectedDate);
  final messenger = GlobalKey<ScaffoldMessengerState>();
  AppLocalizations get _l10n => lookupAppLocalizations(locale);

  Future<TransactionQueryResult>? _loadOverview([DateTime? anchor]) {
    final repository = widget.transactionRepository;
    if (repository == null) return null;
    return () async {
      final month = anchor ?? selectedDate;
      final context = await repository.loadContext();
      return repository.query(
        context.householdId,
        DateTime(month.year, month.month),
        DateTime(month.year, month.month + 1),
      );
    }();
  }

  void refreshOverview() {
    setState(() {
      overview = _loadOverview(selectedDate);
    });
  }

  void selectCalendarDate(DateTime date) {
    final monthChanged =
        selectedDate.year != date.year || selectedDate.month != date.month;
    setState(() {
      selectedDate = date;
      if (monthChanged) overview = _loadOverview(date);
    });
  }

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
        SnackBar(content: Text(_l10n.themeSaveFailed)),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> selectLocale(String code) async {
    if (locale.languageCode == code) return;
    final previous = locale;
    setState(() => locale = Locale(code));
    try {
      await widget.saveLocale?.call(code);
    } catch (_) {
      if (!mounted) return;
      setState(() => locale = previous);
      messenger.currentState?.showSnackBar(
        SnackBar(content: Text(_l10n.languageSaveFailed)),
      );
    }
  }

  Future<void> openEntry(BuildContext context, {DateTime? initialDate}) async {
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
            initialDate: initialDate,
            paymentMethods: data.paymentMethods,
            members: data.members,
            onManagePaymentMethods: data.paymentMethods.isEmpty
                ? () async {
                    Navigator.of(context).pop();
                    await openPaymentMethods(context);
                    if (context.mounted) {
                      await openEntry(context, initialDate: initialDate);
                    }
                  }
                : null,
            onConfirm: repository == null
                ? null
                : (draft) async {
                    try {
                      await repository.save(data.householdId, draft);
                      if (!context.mounted) return;
                      refreshOverview();
                      Navigator.of(context).pop();
                      messenger.currentState?.showSnackBar(
                        SnackBar(content: Text(_l10n.transactionSaved)),
                      );
                    } on TransactionSaveException catch (error) {
                      messenger.currentState?.showSnackBar(
                        SnackBar(
                          content: Text(
                            _l10n.transactionSaveFailedCode(error.code),
                          ),
                        ),
                      );
                    } catch (_) {
                      messenger.currentState?.showSnackBar(
                        SnackBar(content: Text(_l10n.transactionSaveFailed)),
                      );
                    }
                  },
          ),
        ),
      );
    } catch (_) {
      if (context.mounted) {
        messenger.currentState?.showSnackBar(
          SnackBar(content: Text(_l10n.householdLoadFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => openingEntry = false);
    }
  }

  Future<void> openAiReview(BuildContext context) async {
    final repository = widget.transactionRepository;
    if (repository == null) return;
    try {
      final data = await repository.loadContext();
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AiReviewScreen(
            repository: repository,
            contextData: data,
            analysisClient: SupabaseReceiptAnalysisClient(),
          ),
        ),
      );
      if (mounted) refreshOverview();
    } catch (_) {
      if (context.mounted) {
        messenger.currentState?.showSnackBar(
          SnackBar(content: Text(_l10n.householdLoadFailed)),
        );
      }
    }
  }

  Future<void> openPaymentMethods(BuildContext context) async {
    final repository = widget.transactionRepository;
    if (repository == null) return;
    try {
      final data = await repository.loadContext();
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              PaymentMethodsScreen(repository: repository, contextData: data),
        ),
      );
    } catch (_) {
      if (context.mounted) {
        messenger.currentState?.showSnackBar(
          SnackBar(content: Text(_l10n.paymentLoadFailed)),
        );
      }
    }
  }

  Future<void> openHousehold(BuildContext context) async {
    final repository = widget.householdRepository;
    if (repository == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HouseholdScreen(
          repository: repository,
          invitationLinkBaseUrl: widget.invitationLinkBaseUrl,
          onHouseholdChanged: (householdId) {
            widget.onHouseholdChanged?.call(householdId);
            refreshOverview();
          },
          onLeft: () async {
            overview = null;
            await widget.onSignOut?.call();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppLocalizations(locale);
    return MaterialApp(
      title: l10n.appTitle,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: messenger,
      theme: palette.theme,
      home: Scaffold(
        extendBody: true,
        floatingActionButton: tab < 2
            ? Builder(
                builder: (context) => FloatingActionButton.extended(
                  backgroundColor: palette.primary,
                  foregroundColor: Colors.white,
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (sheetContext) => SafeArea(
                      minimum: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          Text(
                            l10n.record,
                            style: Theme.of(
                              sheetContext,
                            ).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '어떻게 기록할까요?',
                            style: Theme.of(sheetContext).textTheme.bodyLarge
                                ?.copyWith(color: const Color(0xff697570)),
                          ),
                          const SizedBox(height: 20),
                          Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: palette.primary.withValues(
                                  alpha: 0.1,
                                ),
                                foregroundColor: palette.primary,
                                child: const Icon(Icons.add_rounded),
                              ),
                              title: Text(
                                l10n.directEntry,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(l10n.directEntrySubtitle),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () {
                                Navigator.pop(sheetContext);
                                openEntry(
                                  context,
                                  initialDate: tab == 0 ? selectedDate : null,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            color: palette.primary,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 16,
                              ),
                              onTap: () {
                                Navigator.pop(sheetContext);
                                openAiReview(context);
                              },
                              leading: const CircleAvatar(
                                backgroundColor: Color(0x24ffffff),
                                foregroundColor: Colors.white,
                                child: Icon(Icons.auto_awesome_rounded),
                              ),
                              title: Text(
                                l10n.captureStatement,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                l10n.captureStatementSubtitle,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 24),
                  label: Text(l10n.record),
                ),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: (value) {
                setState(() => tab = value);
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.calendar_today_outlined),
                  selectedIcon: const Icon(Icons.calendar_today_rounded),
                  label: l10n.calendar,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.receipt_long_outlined),
                  selectedIcon: const Icon(Icons.receipt_long_rounded),
                  label: l10n.history,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: const Icon(
                    Icons.account_balance_wallet_rounded,
                  ),
                  label: l10n.wallet,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings_rounded),
                  label: l10n.settings,
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: tab == 2 && widget.transactionRepository != null
              ? FutureBuilder<HouseholdContext>(
                  future: widget.transactionRepository!.loadContext(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: TextButton(
                          onPressed: () => setState(() {}),
                          child: Text(l10n.walletLoadFailedRetry),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return PaymentMethodsScreen(
                      repository: widget.transactionRepository!,
                      contextData: snapshot.data!,
                      embedded: true,
                    );
                  },
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 124),
                  children: [
                    if (tab != 3) ...[
                      _TopHeader(
                        eyebrow: tab == 0 ? '우리 가계부' : l10n.appTitle,
                        title: tab == 0
                            ? l10n.calendarHeading
                            : [l10n.historyHeading, l10n.walletHeading][tab -
                                  1],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        [
                          l10n.calendarDescription,
                          l10n.historyDescription,
                          l10n.walletDescription,
                        ][tab],
                      ),
                      const SizedBox(height: 22),
                      if (tab < 2)
                        FutureBuilder<TransactionQueryResult>(
                          future: overview,
                          builder: (context, snapshot) =>
                              _MonthlySummaryCard(result: snapshot.data),
                        ),
                      if (tab < 2) const SizedBox(height: 24),
                      if (tab == 2 && widget.transactionRepository != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: FilledButton.icon(
                            onPressed: () => openPaymentMethods(context),
                            icon: const Icon(Icons.manage_accounts_outlined),
                            label: Text(l10n.paymentMethodsManage),
                          ),
                        ),
                      if (tab == 0 && widget.transactionRepository != null)
                        FutureBuilder<TransactionQueryResult>(
                          future: overview,
                          builder: (context, snapshot) => CalendarOverview(
                            selectedDate: selectedDate,
                            result: snapshot.data,
                            onDateChanged: selectCalendarDate,
                          ),
                        ),
                      if (widget.transactionRepository == null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.insights_rounded,
                                  color: palette.primary,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  l10n.previewUnavailable,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        FutureBuilder<TransactionQueryResult>(
                          future: overview,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(l10n.loadHistoryFailed),
                                ),
                              );
                            }
                            if (!snapshot.hasData) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final result = snapshot.data!;
                            if (tab == 0) return const SizedBox.shrink();
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.monthIncome(
                                        formatWon(result.totalIncome),
                                      ),
                                    ),
                                    Text(
                                      l10n.monthExpense(
                                        formatWon(result.totalExpense),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    if (result.items.isEmpty)
                                      Text(l10n.noTransactions)
                                    else
                                      ...result.items
                                          .take(10)
                                          .map(
                                            (item) => ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              leading: CircleAvatar(
                                                backgroundColor: palette.primary
                                                    .withValues(alpha: 0.09),
                                                foregroundColor:
                                                    palette.primary,
                                                child: const Icon(
                                                  Icons.receipt_long_rounded,
                                                  size: 19,
                                                ),
                                              ),
                                              title: Text(
                                                item['merchant'] as String,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              subtitle: Text(
                                                item['occurred_on'] as String,
                                              ),
                                              trailing: Text(
                                                l10n.formattedAmount(
                                                  formatWon(
                                                    (item['amount_won'] as num)
                                                        .toInt(),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ] else ...[
                      _TopHeader(
                        eyebrow: l10n.settings,
                        title: l10n.themeTitle,
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.themeDescription),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: palettes
                            .map(
                              (option) => Semantics(
                                selected: option == palette,
                                child: ChoiceChip(
                                  key: ValueKey('theme-${option.id}'),
                                  selected: option == palette,
                                  showCheckmark: false,
                                  onSelected: saving
                                      ? null
                                      : (_) => select(option),
                                  visualDensity: VisualDensity.compact,
                                  labelPadding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ...[
                                        option.primary,
                                        option.secondary,
                                        option.background,
                                      ].map(
                                        (color) => Container(
                                          width: 10,
                                          height: 10,
                                          margin: const EdgeInsets.only(
                                            right: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.black12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(_paletteName(l10n, option.id)),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.languageTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.languageDescription),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: [
                          ButtonSegment(value: 'ko', label: Text(l10n.korean)),
                          ButtonSegment(value: 'en', label: Text(l10n.english)),
                        ],
                        selected: {locale.languageCode},
                        onSelectionChanged: (value) =>
                            selectLocale(value.first),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        l10n.accountHousehold,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (widget.householdRepository == null)
                        Text(l10n.accountComingSoon)
                      else
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.people_outline_rounded),
                            title: Text(l10n.sharedHousehold),
                            subtitle: Text(l10n.manageHouseholdDescription),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => openHousehold(context),
                          ),
                        ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  String _paletteName(AppLocalizations l10n, String id) => switch (id) {
    'forest' => l10n.themeForest,
    'ocean' => l10n.themeOcean,
    'lavender' => l10n.themeLavender,
    'rose' => l10n.themeRose,
    'olive' => l10n.themeOlive,
    'terracotta' => l10n.themeTerracotta,
    'lemon' => l10n.themeLemon,
    'mint' => l10n.themeMint,
    'cocoa' => l10n.themeCocoa,
    'indigo' => l10n.themeIndigo,
    'plum' => l10n.themePlum,
    'sky' => l10n.themeSky,
    _ => id,
  };
}
