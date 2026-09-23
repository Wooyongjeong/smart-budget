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
import 'features/transactions/transaction_request_tracker.dart';
import 'features/transactions/transaction_detail_screen.dart';
import 'features/transactions/transaction_history_screen.dart';
import 'features/transactions/calendar_summary.dart';
import 'features/transactions/transaction_display.dart';
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

class CalendarOverview extends StatefulWidget {
  const CalendarOverview({
    super.key,
    required this.selectedDate,
    required this.result,
    required this.onDateChanged,
    this.onTransactionTap,
    this.isLoading = false,
    this.isRefreshing = false,
    this.hasError = false,
    this.hasRefreshError = false,
    this.onRetry,
    this.onRefresh,
  });
  final DateTime selectedDate;
  final TransactionQueryResult? result;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<Map<String, dynamic>>? onTransactionTap;
  final bool isLoading;
  final bool isRefreshing;
  final bool hasError;
  final bool hasRefreshError;
  final VoidCallback? onRetry;
  final Future<void> Function()? onRefresh;

  @override
  State<CalendarOverview> createState() => _CalendarOverviewState();
}

class _CalendarOverviewState extends State<CalendarOverview> {
  int _pickerRevision = 0;

  void _goToToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() => _pickerRevision++);
    widget.onDateChanged(today);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.hasError) {
      return _QueryErrorState(
        message: l10n.loadHistoryFailed,
        onRetry: widget.onRetry,
      );
    }
    final items =
        widget.result?.items
            .where((item) => item['occurred_on'] == _date(widget.selectedDate))
            .toList() ??
        [];
    final summaries = groupCalendarTransactions(
      widget.result?.items ?? const [],
    );
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (widget.onRefresh != null)
              IconButton(
                key: const ValueKey('calendar-refresh'),
                tooltip: l10n.refresh,
                onPressed: widget.isRefreshing || widget.isLoading
                    ? null
                    : widget.onRefresh,
                icon: widget.isRefreshing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            TextButton.icon(
              key: const ValueKey('calendar-today'),
              onPressed: _goToToday,
              icon: const Icon(Icons.today_outlined, size: 18),
              label: Text(l10n.today),
            ),
          ],
        ),
        if (widget.hasRefreshError)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(child: Text(l10n.loadHistoryFailed)),
                TextButton(
                  onPressed: widget.onRefresh,
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: CalendarMonthPicker(
            key: ValueKey(_pickerRevision),
            selectedDate: widget.selectedDate,
            summaries: summaries,
            onDateChanged: widget.onDateChanged,
          ),
        ),
        const SizedBox(height: 8),
        if (widget.isLoading || widget.result == null)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(value: 0.35),
          )
        else if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.noTransactionsForDate),
          )
        else
          Card(
            child: Column(
              children: items.map((item) {
                final isIncome = item['kind'] == 'income';
                final color = isIncome
                    ? Colors.teal.shade700
                    : Theme.of(context).colorScheme.error;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.1),
                    child: Icon(
                      isIncome
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      color: color,
                      size: 19,
                    ),
                  ),
                  title: Text(
                    localizedMerchantName(l10n, item['merchant'] as String),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(isIncome ? l10n.income : l10n.expense),
                  trailing: Text(
                    '${isIncome ? '+' : '−'}${l10n.formattedAmount(formatWon((item['amount_won'] as num).toInt()))}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  onTap: widget.onTransactionTap == null
                      ? null
                      : () => widget.onTransactionTap!(item),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.eyebrow,
    required this.title,
    required this.displayName,
  });
  final String eyebrow;
  final String title;
  final String displayName;

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
          key: const ValueKey('profile-avatar'),
          radius: 24,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.11),
          child: Text(
            _avatarInitial(displayName),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );

  String _avatarInitial(String value) {
    final name = value.trim();
    return name.isEmpty ? '나' : String.fromCharCode(name.runes.first);
  }
}

class _QueryErrorState extends StatelessWidget {
  const _QueryErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(AppLocalizations.of(context)!.retry),
          ),
        ],
      ),
    ),
  );
}

class _MonthlySummaryCard extends StatelessWidget {
  const _MonthlySummaryCard({
    required this.result,
    required this.isLoading,
    required this.hasError,
    required this.onRetry,
  });
  final TransactionQueryResult? result;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (hasError) {
      return _QueryErrorState(
        message: l10n.loadHistoryFailed,
        onRetry: onRetry,
      );
    }
    if (isLoading || result == null) {
      return const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator(value: 0.35)),
      );
    }
    final data = result!;
    final primary = Theme.of(context).colorScheme.primary;
    final expense = data.totalExpense;
    final income = data.totalIncome;
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
            AppLocalizations.of(context)!.remainingBalance,
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
                  AppLocalizations.of(context)!.monthIncome(formatWon(income)),
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              Text(
                AppLocalizations.of(context)!.monthExpense(formatWon(expense)),
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
    invitationLinkBaseUrl: widget.config.invitationLinkBaseUrl,
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
  bool signingOut = false;
  bool refreshingOverview = false;
  bool overviewRefreshFailed = false;
  TransactionQueryResult? currentOverviewResult;
  bool openingEntry = false;
  String displayName = '나';
  DateTime selectedDate = DateTime.now();
  late Future<TransactionQueryResult>? overview = _loadOverview(selectedDate);
  final messenger = GlobalKey<ScaffoldMessengerState>();
  AppLocalizations get _l10n => lookupAppLocalizations(locale);

  @override
  void initState() {
    super.initState();
    _loadDisplayName();
  }

  Future<void> _loadDisplayName() async {
    final repository = widget.householdRepository;
    if (repository == null) return;
    try {
      final value = await repository.loadCurrentDisplayName();
      if (mounted) setState(() => displayName = value);
    } catch (_) {
      // Keep the safe fallback until the profile can be read again.
    }
  }

  Future<TransactionQueryResult>? _loadOverview([DateTime? anchor]) {
    final repository = widget.transactionRepository;
    if (repository == null) return null;
    return () async {
      final month = anchor ?? selectedDate;
      final context = await repository.loadContext();
      final result = await repository.query(
        context.householdId,
        DateTime(month.year, month.month),
        DateTime(month.year, month.month + 1),
      );
      if (mounted &&
          selectedDate.year == month.year &&
          selectedDate.month == month.month) {
        currentOverviewResult = result;
      }
      return result;
    }();
  }

  Future<void> refreshOverview() async {
    if (refreshingOverview || widget.transactionRepository == null) return;
    final anchor = DateTime(selectedDate.year, selectedDate.month);
    setState(() {
      refreshingOverview = true;
      overviewRefreshFailed = false;
    });
    try {
      final result = await _loadOverview(anchor);
      if (!mounted || result == null) return;
      if (selectedDate.year != anchor.year ||
          selectedDate.month != anchor.month) {
        return;
      }
      setState(() {
        currentOverviewResult = result;
        overview = Future.value(result);
      });
    } catch (_) {
      if (mounted &&
          selectedDate.year == anchor.year &&
          selectedDate.month == anchor.month) {
        setState(() => overviewRefreshFailed = true);
      }
    } finally {
      if (mounted) setState(() => refreshingOverview = false);
    }
  }

  void selectCalendarDate(DateTime date) {
    final monthChanged =
        selectedDate.year != date.year || selectedDate.month != date.month;
    setState(() {
      selectedDate = date;
      if (monthChanged) {
        currentOverviewResult = null;
        overviewRefreshFailed = false;
        overview = _loadOverview(date);
      }
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
      final requestTracker = TransactionRequestTracker();
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
                      await repository.saveMany(
                        data.householdId,
                        [draft],
                        requestId: requestTracker.requestIdFor(draft),
                      );
                      if (!context.mounted) return;
                      requestTracker.markSucceeded();
                      refreshOverview();
                      Navigator.of(context).pop();
                      messenger.currentState?.showSnackBar(
                        SnackBar(content: Text(_l10n.transactionSaved)),
                      );
                    } on TransactionSaveException catch (error) {
                      messenger.currentState?.showSnackBar(
                        SnackBar(
                          content: Text(
                            error.code == 'idempotency_conflict'
                                ? _l10n.transactionIdempotencyConflict
                                : _l10n.transactionSaveFailedCode(error.code),
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

  Future<void> openTransaction(Map<String, dynamic> item) async {
    final repository = widget.transactionRepository;
    if (repository == null || openingEntry) return;
    setState(() => openingEntry = true);
    try {
      final data = await repository.loadContext();
      final transaction = TransactionRecord.fromMap(item);
      if (!mounted) return;
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => TransactionDetailScreen(
            repository: repository,
            householdId: data.householdId,
            contextData: data,
            transaction: transaction,
            onChanged: refreshOverview,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        messenger.currentState?.showSnackBar(
          SnackBar(content: Text(_l10n.transactionDetailUnavailable)),
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
          onDisplayNameChanged: (value) {
            if (mounted) setState(() => displayName = value);
          },
          onLeft: () async {
            overview = null;
            await widget.onSignOut?.call();
          },
        ),
      ),
    );
  }

  Future<void> confirmSignOut(BuildContext context) async {
    if (signingOut || widget.onSignOut == null) return;
    final l10n = lookupAppLocalizations(locale);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.signOutTitle),
        content: Text(l10n.signOutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => signingOut = true);
    try {
      await widget.onSignOut!.call();
    } catch (_) {
      messenger.currentState?.showSnackBar(
        SnackBar(content: Text(l10n.signOutFailed)),
      );
    } finally {
      if (mounted) setState(() => signingOut = false);
    }
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
                            l10n.recordPrompt,
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
                        eyebrow: l10n.appTitle,
                        displayName: displayName,
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
                      if (tab == 0)
                        FutureBuilder<TransactionQueryResult>(
                          future: overview,
                          builder: (context, snapshot) {
                            final result =
                                snapshot.connectionState ==
                                    ConnectionState.waiting
                                ? currentOverviewResult
                                : snapshot.data ?? currentOverviewResult;
                            return _MonthlySummaryCard(
                              result: result,
                              isLoading: result == null && !snapshot.hasError,
                              hasError: snapshot.hasError && result == null,
                              onRetry: refreshOverview,
                            );
                          },
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
                          builder: (context, snapshot) {
                            final result =
                                snapshot.connectionState ==
                                    ConnectionState.waiting
                                ? currentOverviewResult
                                : snapshot.data ?? currentOverviewResult;
                            return CalendarOverview(
                              selectedDate: selectedDate,
                              result: result,
                              onDateChanged: selectCalendarDate,
                              onTransactionTap: openTransaction,
                              isLoading: result == null && !snapshot.hasError,
                              isRefreshing: refreshingOverview,
                              hasError: snapshot.hasError && result == null,
                              hasRefreshError: overviewRefreshFailed,
                              onRetry: refreshOverview,
                              onRefresh: refreshOverview,
                            );
                          },
                        ),
                      if (tab == 1 && widget.transactionRepository != null)
                        TransactionHistoryScreen(
                          repository: widget.transactionRepository!,
                          initialDate: selectedDate,
                          onTransactionTap: openTransaction,
                        )
                      else if (widget.transactionRepository == null)
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
                      else if (tab == 0)
                        FutureBuilder<TransactionQueryResult>(
                          future: overview,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return _QueryErrorState(
                                message: l10n.loadHistoryFailed,
                                onRetry: refreshOverview,
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
                                                localizedMerchantName(
                                                  l10n,
                                                  item['merchant'] as String,
                                                ),
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
                                              onTap: () =>
                                                  openTransaction(item),
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
                        title: l10n.settings,
                        displayName: displayName,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.profileSection,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.person_outline_rounded),
                          title: Text(displayName),
                          subtitle: Text(l10n.displayName),
                          trailing: widget.householdRepository == null
                              ? null
                              : const Icon(Icons.chevron_right_rounded),
                          onTap: widget.householdRepository == null
                              ? null
                              : () => openHousehold(context),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.screenSection,
                        style: Theme.of(context).textTheme.titleLarge,
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
                      if (widget.onSignOut != null) ...[
                        const SizedBox(height: 8),
                        Card(
                          child: Builder(
                            builder: (itemContext) => ListTile(
                              key: const ValueKey('sign-out'),
                              leading: Icon(
                                Icons.logout_rounded,
                                color: Theme.of(itemContext).colorScheme.error,
                              ),
                              title: Text(l10n.signOut),
                              subtitle: Text(l10n.signOutDescription),
                              trailing: signingOut
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.chevron_right_rounded),
                              enabled: !signingOut,
                              onTap: () => confirmSignOut(itemContext),
                            ),
                          ),
                        ),
                      ],
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
