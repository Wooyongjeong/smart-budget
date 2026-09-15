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
import 'features/payment_methods/payment_methods_screen.dart';

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
    return Card(
      child: Column(
        children: [
          CalendarDatePicker(
            initialDate: selectedDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            onDateChanged: onDateChanged,
          ),
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
            ...items.map(
              (item) => ListTile(
                title: Text(item['merchant'] as String),
                trailing: Text(
                  l10n.formattedAmount(
                    formatWon((item['amount_won'] as num).toInt()),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

class AuthRoot extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final auth = service ?? SupabaseAuthService(config.redirectUrl);
    return MaterialApp(
      title: lookupAppLocalizations(Locale(initialLocale ?? 'ko')).appTitle,
      locale: Locale(initialLocale ?? 'ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      home: StreamBuilder(
        stream: auth.authStateChanges,
        builder: (context, snapshot) => auth.isSignedIn
            ? BudgetApp(
                initialTheme: initialTheme,
                initialLocale: initialLocale,
                saveTheme: saveTheme,
                saveLocale: saveLocale,
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
    this.initialLocale,
    required this.saveTheme,
    this.saveLocale,
    this.transactionRepository,
    this.entryPaymentMethods = const [],
    this.entryMembers = const [],
  });
  final String? initialTheme;
  final String? initialLocale;
  final Future<void> Function(String) saveTheme;
  final Future<void> Function(String)? saveLocale;
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
  late Locale locale = Locale(widget.initialLocale ?? 'ko');
  int tab = 0;
  bool saving = false;
  bool openingEntry = false;
  late Future<TransactionQueryResult>? overview = _loadOverview();
  DateTime selectedDate = DateTime.now();
  final messenger = GlobalKey<ScaffoldMessengerState>();
  AppLocalizations get _l10n => lookupAppLocalizations(locale);

  Future<TransactionQueryResult>? _loadOverview() {
    final repository = widget.transactionRepository;
    if (repository == null) return null;
    return () async {
      final now = DateTime.now();
      final context = await repository.loadContext();
      return repository.query(
        context.householdId,
        DateTime(now.year, now.month),
        DateTime(now.year, now.month + 1),
      );
    }();
  }

  void refreshOverview() {
    setState(() {
      overview = _loadOverview();
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
          builder: (_) =>
              AiReviewScreen(repository: repository, contextData: data),
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
        appBar: AppBar(title: Text(l10n.appTitle)),
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
                            title: Text(l10n.directEntry),
                            subtitle: Text(l10n.directEntrySubtitle),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              openEntry(
                                context,
                                initialDate: tab == 0 ? selectedDate : null,
                              );
                            },
                          ),
                          ListTile(
                            onTap: () {
                              Navigator.pop(sheetContext);
                              openAiReview(context);
                            },
                            leading: Icon(Icons.image_outlined),
                            title: Text(l10n.captureStatement),
                            subtitle: Text(l10n.captureStatementSubtitle),
                          ),
                        ],
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.record),
                ),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (value) {
            setState(() => tab = value);
          },
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              label: l10n.calendar,
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              label: l10n.history,
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: l10n.wallet,
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              label: l10n.settings,
            ),
          ],
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
                  padding: const EdgeInsets.all(24),
                  children: [
                    if (tab != 3) ...[
                      Text(
                        [
                          l10n.calendarHeading,
                          l10n.historyHeading,
                          l10n.walletHeading,
                        ][tab],
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        [
                          l10n.calendarDescription,
                          l10n.historyDescription,
                          l10n.walletDescription,
                        ][tab],
                      ),
                      const SizedBox(height: 32),
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
                            onDateChanged: (date) =>
                                setState(() => selectedDate = date),
                          ),
                        ),
                      if (widget.transactionRepository == null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(l10n.previewUnavailable),
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
                                              title: Text(
                                                item['merchant'] as String,
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
                      Text(
                        l10n.themeTitle,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.themeDescription),
                      const SizedBox(height: 14),
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
                      Text(l10n.accountComingSoon),
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
